local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
---@class RosterEntry
local RosterEntry = Private.classes.RosterEntry
local DeepCopy = Private.DeepCopy

---@class Constants
local constants = Private.constants

---@class AssignmentUtilities
local assignmentUtilities = Private.assignmentUtilities
local MergeAssignments = assignmentUtilities.MergeAssignments

---@class Utilities
local utilities = Private.utilities
local SortAssigneeSpellSets = utilities.SortAssigneeSpellSets

---@class Diff
local Diff = Private.diff

local PlanDiffType = Private.classes.PlanDiffType

local format = string.format
local getmetatable, setmetatable = getmetatable, setmetatable
local GetSpellName = C_Spell.GetSpellName
local ipairs = ipairs
local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local tremove = table.remove
local tostring = tostring

---@param tbl table
---@return table
local function ShallowCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

-- Merges remote into local.
---@param localVersion RosterEntry
---@param remoteVersion RosterEntry
local function MergeRosterEntries(localVersion, remoteVersion)
	for field, remoteValue in pairs(remoteVersion) do
		localVersion[field] = remoteValue
	end
	local metaTable = getmetatable(remoteVersion)
	setmetatable(localVersion, metaTable)
end

---@param a FlatAssigneeSpellSet
---@param b FlatAssigneeSpellSet
---@return boolean
local function SortFlattenedAssigneeSpellSets(a, b)
	if a.assignee == b.assignee then
		if a.spellID <= constants.kTextAssignmentSpellID or b.spellID <= constants.kTextAssignmentSpellID then
			return a.spellID < b.spellID
		else
			local nameA, nameB = GetSpellName(a.spellID), GetSpellName(b.spellID)
			if nameA and nameB then
				return nameA < nameB
			else
				return a.spellID < b.spellID
			end
		end
	end
	return a.assignee < b.assignee
end

---@param assigneeSpellSets table<integer, AssigneeSpellSet>
---@return table<integer, FlatAssigneeSpellSet>
local function FlattenAssigneeSpellSets(assigneeSpellSets)
	local flattened = {}
	for _, assigneeSpellSet in ipairs(assigneeSpellSets) do
		for _, spellID in ipairs(assigneeSpellSet.spells) do
			tinsert(flattened, {
				assignee = assigneeSpellSet.assignee,
				spellID = spellID,
				ID = assigneeSpellSet.assignee .. "," .. tostring(spellID),
			})
		end
	end
	sort(flattened, SortFlattenedAssigneeSpellSets)
	return flattened
end

---@param flattenedAssigneeSpellSets table<integer, FlatAssigneeSpellSet>
---@return table<integer, AssigneeSpellSet>
local function UnFlattenAssigneeSpellSets(flattenedAssigneeSpellSets)
	local newAssigneeSpellSets = {} ---@type table<integer, AssigneeSpellSet>
	local indexMap = {}
	for _, flatAssigneeSpellSet in ipairs(flattenedAssigneeSpellSets) do
		local assignee = flatAssigneeSpellSet.assignee
		if not indexMap[assignee] then
			tinsert(newAssigneeSpellSets, { assignee = assignee, spells = {} })
			indexMap[assignee] = #newAssigneeSpellSets
		end
		local index = indexMap[assignee]
		tinsert(newAssigneeSpellSets[index].spells, flatAssigneeSpellSet.spellID)
	end
	SortAssigneeSpellSets(newAssigneeSpellSets)
	return newAssigneeSpellSets
end

-- Merges remote into local.
---@param localVersion FlatAssigneeSpellSet
---@param remoteVersion FlatAssigneeSpellSet
local function MergeFlatAssigneeSpellSets(localVersion, remoteVersion)
	localVersion.assignee = remoteVersion.assignee
	localVersion.spellID = remoteVersion.spellID
end

-- Merges delete and inserts entries into change entries of a diff if they their index is equal, accounting for
-- shifts due to deletes, inserts, and changes.
---@param diff table<integer, GenericDiffEntry> Original diff with no Change entries.
---@return table<integer, GenericDiffEntry> modifiedDiff
function Diff.CoalesceChanges(diff)
	local result = {}
	local i = 1
	local shift = 0
	while i <= #diff do
		local entry = diff[i]
		local nextEntry = diff[i + 1]
		local coalesced = false
		if entry.type == PlanDiffType.Delete then
			---@cast entry IndexedDeleteDiffEntry<any>
			if nextEntry and nextEntry.type == PlanDiffType.Insert then
				---@cast nextEntry IndexedInsertDiffEntry<any>
				if nextEntry.index == entry.index then
					tinsert(result, {
						type = PlanDiffType.Change,
						aIndex = entry.index,
						bIndex = entry.index,
						oldValue = entry.oldValue,
						newValue = nextEntry.newValue,
						result = true,
					})
					coalesced = true
				elseif nextEntry.index == entry.index + shift then
					tinsert(result, {
						type = PlanDiffType.Change,
						aIndex = entry.index + shift,
						bIndex = entry.index + shift,
						oldValue = entry.oldValue,
						newValue = nextEntry.newValue,
						result = true,
					})
					coalesced = true
				end
			end
			shift = shift - 1
		elseif entry.type == PlanDiffType.Insert then
			shift = shift + 1
		end

		if coalesced then -- Cancel out shift and skip next
			shift = shift + 1
			i = i + 2
		else
			tinsert(result, entry)
			i = i + 1
		end
	end
	return result
end

---@generic T
---@param a table<integer, T>|table<integer, T|{ID: string}>
---@param b table<integer, T>|table<integer, T|{ID: string}>
---@param comparator fun(a: T, b: T): boolean
---@return table<integer, GenericDiffEntry>
function Diff.MyersDiff(a, b, comparator)
	local front = { [1] = { 0, {} } } -- k = 1 represents diagonal 0

	local aCount, bCount = #a, #b
	for d = 0, aCount + bCount do
		for k = -d, d, 2 do
			local goDown
			if k == -d or k ~= d and front[k - 1][1] < front[k + 1][1] then
				goDown = true
			elseif k == d then
				goDown = false
			else
				local left = front[k - 1] and front[k - 1][1] or -math.huge
				local right = front[k + 1] and front[k + 1][1] or -math.huge
				goDown = right > left
			end

			local previousX, x, history
			if goDown then
				previousX = front[k + 1][1]
				history = front[k + 1][2]
				x = previousX
			else
				previousX = front[k - 1][1]
				history = front[k - 1][2]
				x = previousX + 1
			end
			local y = x - k

			history = ShallowCopy(history)

			if 1 <= y and y <= bCount and goDown then
				tinsert(
					history,
					{ type = PlanDiffType.Insert, ID = b[y].ID, index = y, newValue = b[y], result = true }
				)
			elseif 1 <= x and x <= aCount and not goDown then
				tinsert(
					history,
					{ type = PlanDiffType.Delete, ID = a[x].ID, index = x, oldValue = a[x], result = true }
				)
			end

			while x < aCount and y < bCount and comparator(a[x + 1], b[y + 1]) == true do
				tinsert(
					history,
					{ type = PlanDiffType.Equal, ID = b[y + 1].ID, aIndex = x + 1, bIndex = y + 1, result = false }
				)
				x = x + 1
				y = y + 1
			end

			if x >= aCount and y >= bCount then
				return history
			end

			front[k] = { x, history }
		end
	end

	return {}
end

do
	local AssignmentsEqual = assignmentUtilities.AssignmentsEqual
	local AreAssignmentsIdentical = assignmentUtilities.AreAssignmentsIdentical

	---@param a table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@param b table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@return table<integer, GenericDiffEntry>
	function Diff.MyersDiffAssignments(a, b)
		local front = { [1] = { 0, {} } } -- k = 1 represents diagonal 0

		local aCount, bCount = #a, #b
		for d = 0, aCount + bCount do
			for k = -d, d, 2 do
				local goDown
				if k == -d or k ~= d and front[k - 1][1] < front[k + 1][1] then
					goDown = true
				elseif k == d then
					goDown = false
				else
					local left = front[k - 1] and front[k - 1][1] or -math.huge
					local right = front[k + 1] and front[k + 1][1] or -math.huge
					goDown = right > left
				end

				local previousX, x, history
				if goDown then
					previousX = front[k + 1][1]
					history = front[k + 1][2]
					x = previousX
				else
					previousX = front[k - 1][1]
					history = front[k - 1][2]
					x = previousX + 1
				end
				local y = x - k

				history = ShallowCopy(history)

				if 1 <= y and y <= bCount and goDown then
					tinsert(
						history,
						{ type = PlanDiffType.Insert, index = y, newValue = b[y], ID = b[y].ID, result = true }
					)
				elseif 1 <= x and x <= aCount and not goDown then
					tinsert(
						history,
						{ type = PlanDiffType.Delete, index = x, oldValue = a[x], ID = a[x].ID, result = true }
					)
				end

				while x < aCount and y < bCount and AssignmentsEqual(a[x + 1], b[y + 1]) == true do
					if a[x + 1].ID == b[y + 1].ID and not AreAssignmentsIdentical(a[x + 1], b[y + 1]) then
						tinsert(history, {
							type = PlanDiffType.Change,
							ID = a[x + 1].ID,
							aIndex = x + 1,
							bIndex = y + 1,
							oldValue = a[x + 1],
							newValue = b[y + 1],
							result = true,
						})
					else
						tinsert(history, {
							type = PlanDiffType.Equal,
							ID = b[y + 1].ID,
							aIndex = x + 1,
							bIndex = y + 1,
							result = false,
						})
					end
					x = x + 1
					y = y + 1
				end

				if x >= aCount and y >= bCount then
					return history
				end

				front[k] = { x, history }
			end
		end

		return {}
	end
end

do
	---@param baseAssignments table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@param localAssignments table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@param remoteAssignments table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@return table<integer, string>
	local function CreateOrderedAssignmentIDs(baseAssignments, localAssignments, remoteAssignments)
		local orderedIDs = {}
		local seen = {}

		for _, a in ipairs(remoteAssignments) do
			if not seen[a.ID] then
				tinsert(orderedIDs, a.ID)
				seen[a.ID] = true
			end
		end
		for _, a in ipairs(baseAssignments) do
			if not seen[a.ID] then
				tinsert(orderedIDs, a.ID)
				seen[a.ID] = true
			end
		end
		for _, a in ipairs(localAssignments) do
			if not seen[a.ID] then
				tinsert(orderedIDs, a.ID)
				seen[a.ID] = true
			end
		end
		return orderedIDs
	end

	local GetAssignmentConflicts = assignmentUtilities.GetAssignmentConflicts

	---@param base Assignment|CombatLogEventAssignment|TimedAssignment
	---@param localChange GenericDiffEntry
	---@param remoteChange GenericDiffEntry
	---@return GenericDiffEntry
	local function ResolveAssignmentChangeOrConflict(base, localChange, remoteChange)
		local localType, remoteType = localChange.type, remoteChange.type
		local localValue, remoteValue = nil, nil
		local forceConflict = false

		if localType == PlanDiffType.Change and remoteType == PlanDiffType.Change then
			---@cast localChange ChangeDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			---@cast remoteChange ChangeDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			localValue = localChange.newValue
			remoteValue = remoteChange.newValue
		elseif localType == PlanDiffType.Change and remoteType == PlanDiffType.Delete then
			---@cast localChange ChangeDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			---@cast remoteChange DeleteDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			localValue = localChange.newValue
			remoteValue = remoteChange.oldValue
			forceConflict = true
		elseif localType == PlanDiffType.Delete and remoteType == PlanDiffType.Change then
			---@cast localChange DeleteDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			---@cast remoteChange ChangeDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			localValue = localChange.oldValue
			remoteValue = remoteChange.newValue
			forceConflict = true
		elseif localType == PlanDiffType.Equal then
			return remoteChange
		elseif remoteType == PlanDiffType.Equal then
			return localChange
		elseif localType == remoteType then
			return localChange
		end

		if forceConflict then
			---@type ConflictDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
			local entry = {
				type = PlanDiffType.Conflict,
				ID = base.ID,
				localType = localType,
				remoteType = remoteType,
				conflicts = {},
				result = true,
				chooseLocal = false,
				localValue = localValue,
				remoteValue = remoteValue,
			}
			return entry
		else
			local conflicts = GetAssignmentConflicts(base, localValue, remoteValue)
			if #conflicts > 0 then
				---@type ConflictDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				local entry = {
					type = PlanDiffType.Conflict,
					ID = base.ID,
					localType = localType,
					remoteType = remoteType,
					conflicts = conflicts,
					result = true,
					chooseLocal = false,
					localValue = localValue,
					remoteValue = remoteValue,
				}
				return entry
			else
				local localCopy = DeepCopy(localValue)
				setmetatable(localCopy, getmetatable(localValue))
				MergeAssignments(localCopy, remoteValue)
				---@type ChangeDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				local entry = {
					type = PlanDiffType.Change,
					ID = base.ID,
					result = true,
					oldValue = localValue,
					newValue = localCopy,
				}

				return entry
			end
		end
	end

	local MyersDiff = Diff.MyersDiff
	local MyersDiffAssignments = Diff.MyersDiffAssignments

	---@param baseAssignments table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@param localAssignments table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@param remoteAssignments table<integer, Assignment|CombatLogEventAssignment|TimedAssignment>
	---@return table<integer, GenericDiffEntry>
	local function PerformAssignmentDiff(baseAssignments, localAssignments, remoteAssignments)
		---@type table<integer, GenericDiffEntry>
		local merged = {}

		---@type table<string, Assignment|CombatLogEventAssignment|TimedAssignment>
		local baseAssignmentsByID = {}
		for _, v in ipairs(baseAssignments) do
			baseAssignmentsByID[v.ID] = v
		end

		---@type table<string, GenericDiffEntry>
		local localVersionByID = {}
		for _, v in ipairs(MyersDiffAssignments(baseAssignments, localAssignments)) do
			localVersionByID[v.ID] = v
		end

		---@type table<string, GenericDiffEntry>
		local incomingVersionByID = {}
		for _, v in ipairs(MyersDiffAssignments(baseAssignments, remoteAssignments)) do
			incomingVersionByID[v.ID] = v
		end

		for _, id in ipairs(CreateOrderedAssignmentIDs(baseAssignments, localAssignments, remoteAssignments)) do
			local localChange = localVersionByID[id]
			local remoteChange = incomingVersionByID[id]
			local base = baseAssignmentsByID[id]

			if localChange and remoteChange then
				local conflictOrMerge = ResolveAssignmentChangeOrConflict(base, localChange, remoteChange)
				tinsert(merged, conflictOrMerge)
				localVersionByID[id] = nil
				incomingVersionByID[id] = nil
			elseif localChange then
				localChange.localOnlyChange = true
				tinsert(merged, localChange)
				localVersionByID[id] = nil
			elseif remoteChange then
				tinsert(merged, remoteChange)
				incomingVersionByID[id] = nil
			end
		end

		return merged
	end

	---@generic T
	---@param byID table<string, T>
	---@param orderedIDs table<integer, string>
	---@param visited table<string, boolean>
	local function MergeIDsGeneric(byID, orderedIDs, visited)
		for id, _ in pairs(byID) do
			if not visited[id] then
				tinsert(orderedIDs, id)
				visited[id] = true
			end
		end
	end

	---@generic T
	---@param baseVersion table<string, T>
	---@param localVersion table<string, T>
	---@param remoteVersion table<string, T>
	---@param IsEqual fun(a: T, b: T): boolean
	---@param GetConflicts fun(a: T, b: T, c: T): table
	---@param Merge fun(a: T, b: T)
	---@return table<integer, GenericDiffEntry>
	local function PerformDiffGeneric(baseVersion, localVersion, remoteVersion, IsEqual, GetConflicts, Merge)
		local visited = {}
		local orderedIDs = {}
		MergeIDsGeneric(baseVersion, orderedIDs, visited)
		MergeIDsGeneric(localVersion, orderedIDs, visited)
		MergeIDsGeneric(remoteVersion, orderedIDs, visited)
		sort(orderedIDs)

		---@type table<integer, GenericDiffEntry>
		local merged = {}
		for _, id in ipairs(orderedIDs) do
			local localEntry = localVersion[id]
			local remoteEntry = remoteVersion[id]
			local base = baseVersion[id]

			---@type GenericDiffEntry|nil
			local result = nil
			if base then
				if localEntry and remoteEntry then
					local localSame = IsEqual(base, localEntry)
					local remoteSame = IsEqual(base, remoteEntry)
					if localSame and remoteSame then
						result = {
							type = PlanDiffType.Equal,
							ID = id,
							result = false,
						}
					elseif remoteSame then
						result = {
							type = PlanDiffType.Change,
							ID = id,
							result = true,
							oldValue = base,
							newValue = localEntry,
							localOnlyChange = true,
						}
					else
						local conflicts = GetConflicts(base, localEntry, remoteEntry)
						if #conflicts > 0 then
							result = {
								type = PlanDiffType.Conflict,
								ID = id,
								localType = PlanDiffType.Change,
								remoteType = PlanDiffType.Change,
								conflicts = conflicts,
								result = true,
								chooseLocal = false,
								localValue = localEntry,
								remoteValue = remoteEntry,
							}
						else
							local mergedLocal = DeepCopy(localEntry)
							Merge(mergedLocal, remoteEntry)
							result = {
								type = PlanDiffType.Change,
								ID = id,
								result = true,
								oldValue = localEntry,
								newValue = mergedLocal,
							}
						end
					end
				elseif localEntry then
					if IsEqual(base, localEntry) then -- Remote delete with no local edits
						result = {
							type = PlanDiffType.Delete,
							ID = id,
							oldValue = localEntry,
							result = true,
						}
					else -- Remote delete with local edits - conflict
						---@cast result ConflictDiffEntry<`T`>
						result = {
							type = PlanDiffType.Conflict,
							ID = id,
							localType = PlanDiffType.Change,
							remoteType = PlanDiffType.Delete,
							result = true,
							chooseLocal = false,
							localValue = localEntry,
							remoteValue = base,
						}
					end
				elseif remoteEntry then
					if IsEqual(base, remoteEntry) then -- Local delete with no remote edits
						result = {
							type = PlanDiffType.Delete,
							ID = id,
							oldValue = remoteEntry,
							result = true,
						}
					else -- Local delete with remote edits - conflict
						result = {
							type = PlanDiffType.Conflict,
							ID = id,
							localType = PlanDiffType.Delete,
							remoteType = PlanDiffType.Change,
							result = true,
							chooseLocal = false,
							localValue = base,
							remoteValue = remoteEntry,
						}
					end
				end
			else
				if localEntry and remoteEntry then
					if IsEqual(localEntry, remoteEntry) then
						result = {
							type = PlanDiffType.Insert,
							ID = id,
							result = false,
							newValue = localEntry,
						}
					else
						local conflicts = GetConflicts(base, localEntry, remoteEntry)
						if #conflicts > 0 then
							result = {
								type = PlanDiffType.Conflict,
								ID = id,
								localType = PlanDiffType.Insert,
								remoteType = PlanDiffType.Insert,
								conflicts = conflicts,
								result = true,
								chooseLocal = false,
								localValue = localEntry,
								remoteValue = remoteEntry,
							}
						else
							local mergedLocal = DeepCopy(localEntry)
							Merge(mergedLocal, remoteEntry)
							result = {
								type = PlanDiffType.Insert,
								ID = id,
								result = true,
								newValue = mergedLocal,
							}
						end
					end
				elseif localEntry then
					result = {
						type = PlanDiffType.Insert,
						ID = id,
						localOnlyChange = true,
						result = true,
						newValue = localEntry,
					}
				elseif remoteEntry then
					result = {
						type = PlanDiffType.Insert,
						ID = id,
						result = true,
						newValue = remoteEntry,
					}
				end
			end
			tinsert(merged, result)
		end

		return merged
	end

	---@param a FlatAssigneeSpellSet
	---@param b FlatAssigneeSpellSet
	---@return boolean --True if equal
	local function AreFlatAssigneeSpellSetsEqual(a, b)
		return a.ID == b.ID
	end

	---@param a RosterEntry
	---@param b RosterEntry
	---@return boolean --True if equal
	local function AreRosterEntriesEqual(a, b)
		return a.class == b.class and a.role == b.role
	end

	local kNoCompareRosterFields = {
		["__index"] = true,
		["New"] = true,
		["classColoredName"] = true,
	}

	---@param baseVersion RosterEntry
	---@param localVersion RosterEntry
	---@param remoteVersion RosterEntry
	---@return table<integer, GenericConflict<RosterEntry>>|nil
	local function GetRosterConflicts(baseVersion, localVersion, remoteVersion)
		local localChanges, remoteChanges = {}, {}

		for field, baseValue in pairs(baseVersion) do
			if not kNoCompareRosterFields[field] then
				local localValue = localVersion[field]
				local remoteValue = remoteVersion[field]
				if localValue ~= baseValue then
					localChanges[field] = localValue
				end
				if remoteValue ~= baseValue then
					remoteChanges[field] = remoteValue
				end
			end
		end

		local conflicts = {}

		for field, localValue in pairs(localChanges) do
			local remoteValue = remoteChanges[field]
			if remoteValue and remoteValue ~= localValue then
				tinsert(conflicts, {
					field = field,
					baseValue = baseVersion[field],
					localValue = localValue,
					remoteValue = remoteValue,
				})
			end
		end

		return conflicts
	end

	local HasAnyOutdatedAssignmentIDs = assignmentUtilities.HasAnyOutdatedAssignmentIDs
	local CoalesceChanges = Diff.CoalesceChanges

	-- Creates a diff between two plans.
	---@param oldPlan Plan Existing plan.
	---@param newPlan Plan New plan.
	---@return PlanDiff
	function Diff.DiffPlans(oldPlan, newPlan)
		---@type PlanDiff
		local diff = {
			assignments = {},
			roster = {},
			content = CoalesceChanges(MyersDiff(oldPlan.content, newPlan.content, function(a, b)
				return a == b
			end)),
			metaData = {},
			assigneeSpellSets = {},
			empty = true,
			canUseNewAssignmentMerge = not HasAnyOutdatedAssignmentIDs(oldPlan.assignments)
				and not HasAnyOutdatedAssignmentIDs(newPlan.assignments)
				and oldPlan.lastSyncedSnapShot ~= nil,
		}

		---@type Plan|nil
		local deserializedPlan = nil
		if diff.canUseNewAssignmentMerge then
			deserializedPlan = Private.PlanSerializer.DeserializePlan(oldPlan.lastSyncedSnapShot)
		end

		-- Assignments
		if deserializedPlan then
			diff.assignments =
				PerformAssignmentDiff(deserializedPlan.assignments, oldPlan.assignments, newPlan.assignments)
		else
			diff.assignments = CoalesceChanges(MyersDiffAssignments(oldPlan.assignments, newPlan.assignments))
		end

		-- Metadata
		if oldPlan.difficulty ~= newPlan.difficulty then
			diff.metaData.difficulty = {}
			diff.metaData.difficulty.oldValue = oldPlan.difficulty
			diff.metaData.difficulty.newValue = newPlan.difficulty
			diff.metaData.difficulty.result = true
			diff.empty = false
		end
		if oldPlan.dungeonEncounterID ~= newPlan.dungeonEncounterID then
			diff.metaData.dungeonEncounterID = {}
			diff.metaData.dungeonEncounterID.oldValue = oldPlan.dungeonEncounterID
			diff.metaData.dungeonEncounterID.newValue = newPlan.dungeonEncounterID
			diff.metaData.dungeonEncounterID.result = true
			diff.empty = false
		end
		if oldPlan.instanceID ~= newPlan.instanceID then
			diff.metaData.instanceID = {}
			diff.metaData.instanceID.oldValue = oldPlan.instanceID
			diff.metaData.instanceID.newValue = newPlan.instanceID
			diff.metaData.instanceID.result = true
			diff.empty = false
		end

		-- Roster
		if deserializedPlan then
			diff.roster = PerformDiffGeneric(
				deserializedPlan.roster,
				oldPlan.roster,
				newPlan.roster,
				AreRosterEntriesEqual,
				GetRosterConflicts,
				MergeRosterEntries
			)
		else
			local oldRoster = oldPlan.roster
			local newRoster = newPlan.roster
			local seen = {}
			for newRosterName, newRosterEntry in pairs(newRoster) do
				local oldRosterEntry = oldRoster[newRosterName]
				if not oldRosterEntry then
					local planRosterDiff = {
						ID = newRosterName,
						type = PlanDiffType.Insert,
						newValue = DeepCopy(newRosterEntry),
						result = true,
					} ---@type InsertDiffEntry<RosterEntry>
					tinsert(diff.roster, planRosterDiff)
				else
					if oldRosterEntry.class ~= newRosterEntry.class or oldRosterEntry.role ~= newRosterEntry.role then
						local planRosterDiff = {
							ID = newRosterName,
							type = PlanDiffType.Change,
							oldValue = DeepCopy(oldRosterEntry),
							newValue = DeepCopy(newRosterEntry),
							result = true,
						} ---@type ChangeDiffEntry<RosterEntry>
						tinsert(diff.roster, planRosterDiff)
					end
					seen[newRosterName] = true
				end
			end
			for oldRosterName, oldRosterEntry in pairs(oldRoster) do
				if not seen[oldRosterName] then
					local planRosterDiff = {
						ID = oldRosterName,
						type = PlanDiffType.Delete,
						oldValue = DeepCopy(oldRosterEntry),
						result = true,
					} ---@as DeleteDiffEntry<RosterEntry>
					tinsert(diff.roster, planRosterDiff)
				end
			end
		end

		-- Assignee spell sets
		if deserializedPlan then
			SortAssigneeSpellSets(deserializedPlan.assigneeSpellSets)
			SortAssigneeSpellSets(oldPlan.assigneeSpellSets)
			SortAssigneeSpellSets(newPlan.assigneeSpellSets)
			local baseAssigneeSpellSets = FlattenAssigneeSpellSets(deserializedPlan.assigneeSpellSets)
			---@type table<string, FlatAssigneeSpellSet>
			local baseByID = {}
			for _, v in ipairs(baseAssigneeSpellSets) do
				baseByID[v.ID] = v
			end

			local localAssigneeSpellSets = FlattenAssigneeSpellSets(oldPlan.assigneeSpellSets)
			---@type table<string, FlatAssigneeSpellSet>
			local localByID = {}
			for _, v in ipairs(localAssigneeSpellSets) do
				localByID[v.ID] = v
			end

			local remoteAssigneeSpellSets = FlattenAssigneeSpellSets(newPlan.assigneeSpellSets)
			---@type table<string, FlatAssigneeSpellSet>
			local remoteByID = {}
			for _, v in ipairs(remoteAssigneeSpellSets) do
				remoteByID[v.ID] = v
			end
			diff.assigneeSpellSets = PerformDiffGeneric(
				baseByID,
				localByID,
				remoteByID,
				AreFlatAssigneeSpellSetsEqual,
				function()
					return {}
				end,
				MergeFlatAssigneeSpellSets
			)
		else
			SortAssigneeSpellSets(oldPlan.assigneeSpellSets)
			SortAssigneeSpellSets(newPlan.assigneeSpellSets)
			local oldAssigneeSpellSets = FlattenAssigneeSpellSets(oldPlan.assigneeSpellSets)
			local newAssigneeSpellSets = FlattenAssigneeSpellSets(newPlan.assigneeSpellSets)
			diff.assigneeSpellSets =
				CoalesceChanges(MyersDiff(oldAssigneeSpellSets, newAssigneeSpellSets, function(a, b)
					return a.assignee == b.assignee and a.spellID == b.spellID
				end))
		end

		---@param tbl table<integer, GenericDiffEntry>
		local function CheckIfNotEmpty(tbl)
			if diff.empty == true then
				for _, entry in ipairs(tbl) do
					if entry.result == true then
						diff.empty = false
						return
					end
				end
			end
		end

		CheckIfNotEmpty(diff.assignments)
		CheckIfNotEmpty(diff.assigneeSpellSets)
		CheckIfNotEmpty(diff.roster)
		CheckIfNotEmpty(diff.content)

		if diff.empty == true then
			if diff.metaData.difficulty then
				diff.empty = false
			elseif diff.metaData.dungeonEncounterID then
				diff.empty = false
			elseif diff.metaData.instanceID then
				diff.empty = false
			end
		end

		return diff
	end
end

-- Applies the diff with proper index handling.
---@generic T
---@param existingTable table<integer, T> Existing table to apply the diff to.
---@param tableDiff table<integer, GenericDiffEntry> Diff between existing and new table.
---@param changeFunc fun(newValue:T, ...:any):T Function to set new values from the new table.
---@param ... any Args for changeFunc
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyDiff(existingTable, tableDiff, changeFunc, ...)
	local addedCount, removedCount, changedCount = 0, 0, 0

	-- Apply deletes first (reverse order)
	for i = #tableDiff, 1, -1 do
		local diff = tableDiff[i]
		if diff.result and diff.type == PlanDiffType.Delete then
			---@cast diff IndexedDeleteDiffEntry<`T`>
			tremove(existingTable, diff.index)
			removedCount = removedCount + 1
		end
	end

	-- Apply inserts and changes in forward order
	for i = 1, #tableDiff do
		local diff = tableDiff[i]
		if diff.result then
			if diff.type == PlanDiffType.Insert then
				---@cast diff IndexedInsertDiffEntry<`T`>
				tinsert(existingTable, diff.index, diff.newValue)
				addedCount = addedCount + 1
			elseif diff.type == PlanDiffType.Change then
				---@cast diff IndexedChangeDiffEntry<`T`>
				existingTable[diff.aIndex] = changeFunc(diff.newValue, ...)
				changedCount = changedCount + 1
			end
		end
	end

	return addedCount, removedCount, changedCount
end

---@param existingAssignments table<integer, Assignment|TimedAssignment|CombatLogEventAssignment>
---@param assignmentDiff table<integer, GenericDiffEntry> Indexed = old, Generic = new
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyAssignmentDiffOld(existingAssignments, assignmentDiff)
	local DuplicateAssignment = Private.DuplicateAssignment
	---@param assignment Assignment|TimedAssignment|CombatLogEventAssignment
	local function SetFunction(assignment)
		local newAssignment = DuplicateAssignment(assignment)
		newAssignment.ID = assignment.ID
		return newAssignment
	end
	return Diff.ApplyDiff(existingAssignments, assignmentDiff, SetFunction)
end

---@param existingAssignments table<integer, Assignment|TimedAssignment|CombatLogEventAssignment>
---@param assignmentDiff table<integer, GenericDiffEntry>
---@param forceMergeFromRemote boolean|nil
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyAssignmentDiff(existingAssignments, assignmentDiff, forceMergeFromRemote)
	local addedCount, removedCount, changedCount = 0, 0, 0

	local function FindAssignmentIndex(id)
		for i = 1, #existingAssignments do
			if existingAssignments[i].ID == id then
				return i
			end
		end
	end

	for i = #assignmentDiff, 1, -1 do
		local diff = assignmentDiff[i]
		if diff.result and not diff.localOnlyChange and diff.type == PlanDiffType.Delete then
			local index = FindAssignmentIndex(diff.ID)
			if index then
				tremove(existingAssignments, index)
				removedCount = removedCount + 1
			end
		end
	end

	for i = 1, #assignmentDiff do
		local diff = assignmentDiff[i]
		if diff.result and not diff.localOnlyChange then
			if diff.type == PlanDiffType.Insert then
				---@cast diff InsertDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				if not FindAssignmentIndex(diff.ID) then
					tinsert(existingAssignments, diff.newValue)
					addedCount = addedCount + 1
				end
			elseif diff.type == PlanDiffType.Change then
				---@cast diff ChangeDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				local index = FindAssignmentIndex(diff.ID)
				if index then
					MergeAssignments(existingAssignments[index], diff.newValue)
					changedCount = changedCount + 1
				end
			elseif diff.type == PlanDiffType.Conflict then
				---@cast diff ConflictDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
				local index = FindAssignmentIndex(diff.ID)
				if index then
					if diff.chooseLocal == false or forceMergeFromRemote then
						if diff.remoteType == PlanDiffType.Delete then
							tremove(existingAssignments, index)
							removedCount = removedCount + 1
						elseif diff.remoteType == PlanDiffType.Change then
							MergeAssignments(existingAssignments[index], diff.remoteValue)
							changedCount = changedCount + 1
						end
					else
						if diff.localType == PlanDiffType.Delete then
							tremove(existingAssignments, index)
							removedCount = removedCount + 1
						elseif diff.localType == PlanDiffType.Change then
							local temp = DeepCopy(diff.localValue)
							setmetatable(temp, getmetatable(diff.localValue))
							MergeAssignments(existingAssignments[index], diff.remoteValue)
							MergeAssignments(existingAssignments[index], temp)
							changedCount = changedCount + 1
						end
					end
				end
			end
		end
	end

	return addedCount, removedCount, changedCount
end

---@generic K, V
---@param existing table<K, V>
---@param genericDiff table<integer, GenericDiffEntry>
---@param forceMergeFromRemote boolean|nil
---@param FindIndex fun(ID: string):`K`|nil
---@param keyType "number"|"string"
---@param Merge fun(a: V, b: V)
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyGenericDiff(existing, genericDiff, forceMergeFromRemote, FindIndex, Merge, keyType)
	local addedCount, removedCount, changedCount = 0, 0, 0

	for i = #genericDiff, 1, -1 do
		local diff = genericDiff[i]
		if diff.result and not diff.localOnlyChange and diff.type == PlanDiffType.Delete then
			local index = FindIndex(diff.ID)
			if index and existing[index] then
				if keyType == "number" then
					tremove(existing, index)
				else
					existing[index] = nil
				end
				removedCount = removedCount + 1
			end
		end
	end

	for i = 1, #genericDiff do
		local diff = genericDiff[i]
		if diff.result and not diff.localOnlyChange then
			local index = FindIndex(diff.ID)
			if diff.type == PlanDiffType.Insert then
				---@cast diff InsertDiffEntry<`K`>
				if not index then
					if keyType == "number" then
						tinsert(existing, diff.newValue)
					else
						existing[diff.ID] = diff.newValue
					end
					addedCount = addedCount + 1
				end
			elseif diff.type == PlanDiffType.Change then
				---@cast diff ChangeDiffEntry<`K`>
				if index and existing[index] then
					Merge(existing[index], diff.newValue)
					changedCount = changedCount + 1
				end
			elseif diff.type == PlanDiffType.Conflict then
				---@cast diff ConflictDiffEntry<`K`>
				if diff.chooseLocal == false or forceMergeFromRemote then
					if diff.remoteType == PlanDiffType.Delete then
						if index and existing[index] then
							if keyType == "number" then
								tremove(existing, index)
							else
								existing[index] = nil
							end
							removedCount = removedCount + 1
						end
					elseif diff.remoteType == PlanDiffType.Change or diff.localType == PlanDiffType.Insert then
						-- Change and insert are the same, merge remote on top of local
						if index and existing[index] then
							Merge(existing[index], diff.remoteValue)
						elseif index then
							existing[index] = diff.remoteValue
						end
						changedCount = changedCount + 1
					end
				else
					if diff.localType == PlanDiffType.Delete then
						if index and existing[index] then
							if keyType == "number" then
								tremove(existing, index)
							else
								existing[index] = nil
							end
							removedCount = removedCount + 1
						end
					elseif diff.localType == PlanDiffType.Change or diff.localType == PlanDiffType.Insert then
						if index and existing[index] then
							-- Change and insert are the same, merge local on top of remote
							local temp = DeepCopy(diff.localValue)
							setmetatable(temp, getmetatable(diff.localValue))
							Merge(existing[diff.ID], diff.remoteValue)
							Merge(existing[diff.ID], temp)
						elseif index then
							existing[index] = diff.localValue
						end
						changedCount = changedCount + 1
					end
				end
			end
		end
	end

	return addedCount, removedCount, changedCount
end

---@param existingPlan Plan
---@param templateDiff table<integer, GenericDiffEntry>
---@param forceMergeFromRemote boolean|nil
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyTemplateDiff(existingPlan, templateDiff, forceMergeFromRemote)
	local addedCount, removedCount, changedCount = 0, 0, 0

	local existingFlattened = FlattenAssigneeSpellSets(existingPlan.assigneeSpellSets)

	---@param ID string
	---@return integer?
	local function FindIndex(ID)
		for i = 1, #existingFlattened do
			if existingFlattened[i].ID == ID then
				return i
			end
		end
	end

	Diff.ApplyGenericDiff(
		existingFlattened,
		templateDiff,
		forceMergeFromRemote,
		FindIndex,
		MergeFlatAssigneeSpellSets,
		"number"
	)

	existingPlan.assigneeSpellSets = UnFlattenAssigneeSpellSets(existingFlattened)

	return addedCount, removedCount, changedCount
end

---@param existingPlan Plan Existing plan to apply the diff to.
---@param tableDiff table<integer, GenericDiffEntry> Diff between existing and new table.
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyTemplateDiffOld(existingPlan, tableDiff)
	local addedCount, removedCount, changedCount = 0, 0, 0

	local existingAssigneeSpellSets = existingPlan.assigneeSpellSets
	local flattenedAssigneeSpellSets = FlattenAssigneeSpellSets(existingAssigneeSpellSets)

	-- Apply deletes first (reverse order)
	for i = #tableDiff, 1, -1 do
		local diff = tableDiff[i]
		if diff.result and diff.type == PlanDiffType.Delete then
			---@cast diff IndexedDeleteDiffEntry<FlatAssigneeSpellSet>
			tremove(flattenedAssigneeSpellSets, diff.index)
			removedCount = removedCount + 1
		end
	end

	-- Apply inserts and changes in forward order
	for i = 1, #tableDiff do
		local diff = tableDiff[i]
		if diff.result then
			if diff.type == PlanDiffType.Insert then
				---@cast diff IndexedInsertDiffEntry<FlatAssigneeSpellSet>
				tinsert(flattenedAssigneeSpellSets, diff.index, diff.newValue)
				addedCount = addedCount + 1
			elseif diff.type == PlanDiffType.Change then
				---@cast diff IndexedChangeDiffEntry<FlatAssigneeSpellSet>
				flattenedAssigneeSpellSets[diff.aIndex].assignee = diff.newValue.assignee
				flattenedAssigneeSpellSets[diff.aIndex].spellID = diff.newValue.spellID
				changedCount = changedCount + 1
			end
		end
	end

	existingPlan.assigneeSpellSets = UnFlattenAssigneeSpellSets(flattenedAssigneeSpellSets)

	return addedCount, removedCount, changedCount
end

---@param existingRoster table<string, RosterEntry>
---@param rosterDiff table<integer, GenericDiffEntry>
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyRosterDiffOld(existingRoster, rosterDiff)
	local addedCount, removedCount, changedCount = 0, 0, 0

	for i = #rosterDiff, 1, -1 do
		local diff = rosterDiff[i]
		if diff.result == true then
			if diff.type == PlanDiffType.Delete then
				existingRoster[diff.ID] = nil
				removedCount = removedCount + 1
			elseif diff.type == PlanDiffType.Insert then
				---@cast diff InsertDiffEntry<RosterEntry>
				local rosterEntry = RosterEntry:New()
				rosterEntry.class = diff.newValue.class
				rosterEntry.classColoredName = diff.newValue.classColoredName
				rosterEntry.role = diff.newValue.role
				existingRoster[diff.ID] = rosterEntry
				addedCount = addedCount + 1
			elseif diff.type == PlanDiffType.Change then
				---@cast diff ChangeDiffEntry<RosterEntry>
				existingRoster[diff.ID].class = diff.newValue.class
				existingRoster[diff.ID].classColoredName = diff.newValue.classColoredName
				existingRoster[diff.ID].role = diff.newValue.role
				changedCount = changedCount + 1
			end
		end
	end

	return addedCount, removedCount, changedCount
end

---@param existingRoster table<string, RosterEntry>
---@param rosterDiff table<integer, GenericDiffEntry>
---@param forceMergeFromRemote boolean|nil
---@return integer addedCount
---@return integer removedCount
---@return integer changedCount
function Diff.ApplyRosterDiff(existingRoster, rosterDiff, forceMergeFromRemote)
	---@param ID string
	---@return string?
	local function FindIndex(ID)
		if existingRoster[ID] then
			return ID
		end
	end

	return Diff.ApplyGenericDiff(
		existingRoster,
		rosterDiff,
		forceMergeFromRemote,
		FindIndex,
		MergeRosterEntries,
		"string"
	)
end

do
	---@param messages table<integer, string>
	---@param added integer
	---@param removed integer
	---@param changed integer
	---@param typeString string
	local function MaybeAddUpdateString(messages, added, removed, changed, typeString)
		if added > 0 or removed > 0 or changed > 0 then
			local a, r, c = L["Added"], L["Removed"]:lower(), L["Changed"]:lower()
			tinsert(
				messages,
				format("%s %d, %s %d, %s %s %d %s.", a, added, r, removed, L["and"], c, changed, typeString)
			)
		end
	end

	local ChangePlanBoss = utilities.ChangePlanBoss

	-- Merges an existing plan using a plan diff.
	---@param plans table<string, Plan> All plans.
	---@param existingPlan Plan Existing plan to apply diff to.
	---@param planDiff PlanDiff Diff between existing and new plan.
	---@param forceMergeFromRemote boolean|nil
	---@return table<integer, string> messages
	function Diff.MergePlan(plans, existingPlan, planDiff, forceMergeFromRemote)
		local messages = {}

		local added, removed, changed = 0, 0, 0

		local existingAssignments = existingPlan.assignments
		if planDiff.canUseNewAssignmentMerge then
			added, removed, changed =
				Diff.ApplyAssignmentDiff(existingAssignments, planDiff.assignments, forceMergeFromRemote)
		else
			added, removed, changed = Diff.ApplyAssignmentDiffOld(existingAssignments, planDiff.assignments)
		end
		MaybeAddUpdateString(messages, added, removed, changed, L["assignments"])

		local existingRoster = existingPlan.roster
		if planDiff.canUseNewAssignmentMerge then
			added, removed, changed = Diff.ApplyRosterDiff(existingRoster, planDiff.roster, forceMergeFromRemote)
		else
			added, removed, changed = Diff.ApplyRosterDiffOld(existingRoster, planDiff.roster)
		end
		MaybeAddUpdateString(messages, added, removed, changed, L["roster members"])

		if planDiff.canUseNewAssignmentMerge then
			added, removed, changed =
				Diff.ApplyTemplateDiff(existingPlan, planDiff.assigneeSpellSets, forceMergeFromRemote)
		else
			added, removed, changed = Diff.ApplyTemplateDiffOld(existingPlan, planDiff.assigneeSpellSets)
		end
		MaybeAddUpdateString(messages, added, removed, changed, L["Templates"]:lower())

		local existingContent = existingPlan.content
		added, removed, changed = Diff.ApplyDiff(existingContent, planDiff.content, function(v)
			return v
		end)
		MaybeAddUpdateString(messages, added, removed, changed, L["lines of External Text"])

		local changedMetaData = false
		local metaDataMessages = {}
		if planDiff.metaData.instanceID and planDiff.metaData.instanceID.result == true then
			existingPlan.instanceID = planDiff.metaData.instanceID.newValue
			tinsert(metaDataMessages, L["Instance"]:lower())
			changedMetaData = true
		end
		if planDiff.metaData.dungeonEncounterID and planDiff.metaData.dungeonEncounterID.result == true then
			existingPlan.dungeonEncounterID = planDiff.metaData.dungeonEncounterID.newValue
			tinsert(metaDataMessages, L["Boss"]:lower())
			changedMetaData = true
		end
		if planDiff.metaData.difficulty and planDiff.metaData.difficulty.result == true then
			existingPlan.difficulty = planDiff.metaData.difficulty.newValue
			tinsert(metaDataMessages, L["Difficulty"]:lower())
			changedMetaData = true
		end

		if changedMetaData then
			ChangePlanBoss(plans, existingPlan.name, existingPlan.dungeonEncounterID, existingPlan.difficulty)
			if #metaDataMessages == 1 then
				tinsert(messages, format("%s %s %s.", L["Changed"], L["The"]:lower(), metaDataMessages[1]))
			elseif #metaDataMessages == 2 then
				local m1, m2 = metaDataMessages[1], metaDataMessages[2]
				tinsert(messages, format("%s %s %s %s %s.", L["Changed"], L["The"]:lower(), m1, L["and"], m2))
			elseif #metaDataMessages == 3 then
				local m1, m2, m3 = metaDataMessages[1], metaDataMessages[2], metaDataMessages[3]
				tinsert(messages, format("%s %s %s, %s, %s %s.", L["Changed"], L["The"]:lower(), m1, m2, L["and"], m3))
			end
		end

		return messages
	end
end
