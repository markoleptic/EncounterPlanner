---@module "Options"

--@type string
local AddOnName = ...
---@class Private
local Private = select(2, ...) --[[@as Private]]
local AddOn = Private.AddOn



local function NewBoss(name, bossIds, journalEncounterId, dungeonEncounterId)
	return {
		name = name,
		bossIds = bossIds,
		journalEncounterId = journalEncounterId,
		dungeonEncounterId = dungeonEncounterId
	}
end

AddOn.Defaults = {
	profile = {
		instances = {
			["Nerub'ar Palace"] = {
				name = "Nerub'ar Palace",
				journalInstanceId = 1273, -- all bosses share same JournalInstanceID
				instanceId = 2657, -- the instance id for the zone the boss is located in (?)
				bosses = {
					NewBoss("Ulgrax the Devourer", 215657, 2607, 2902),
					NewBoss("The Bloodbound Horror", 214502, 2611, 2917),
					NewBoss("Sikran, Captain of the Sureki", 214503, 2599, 2898),
					NewBoss("Rasha'nan", 214504, 2609, 2918),
					NewBoss("Broodtwister Ovi'nax", 214506, 2612, 2919),
					NewBoss("Nexus-Princess Ky'veza", 217748, 2601, 2920),
					NewBoss("The Silken Court", { 217489, 217491 }, 2608, 2921),
					NewBoss("Queen Ansurek", 218370, 2602, 2922),
				},
				order = { 1, 2, 3, 4, 5, 6, 7, 8 },
			}
		}
	}
}

local bosses   = {
	["Ulgrax the Devourer"] = {
		abilities = {
			[435136] = { -- Venomous Lash
				phases = {
					[1] = {
						castTimes = { 5.0, 25.0, 28.0 },
						repeatInterval = nil
					}
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[435138] = { -- Digestive Acid
				phases = {
					[1] = {
						castTimes = { 20.0, 47.0 },
						repeatInterval = nil
					}
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[434803] = { -- Carnivorous Contest
				phases = {
					[1] = {
						castTimes = { 38.0, 36.0 },
						repeatInterval = nil
					}
				},
				duration = 6.0,
				castTime = 4.0,
			},
			[445123] = { -- Hulking Crash
				phases = {
					[1] = {
						castTimes = { 90.0 },
						repeatInterval = nil
					}
				},
				duration = 0.0,
				castTime = 5.0,
			},
			[436200] = { -- Juggernaut Charge
				phases = {
					[2] = {
						castTimes = { 16.7, 7.1, 7.1, 7.1 },
						repeatInterval = nil
					}
				},
				duration = 8.0,
				castTime = 4.0,
			},
			[438012] = { -- Hungering Bellows
				phases = {
					[2] = {
						castTimes = { 60.8 },
						repeatInterval = 7
					}
				},
				duration = 3.0,
				castTime = 3.0,
			},
			[445052] = { -- Chittering Swarm
				phases = {
					[2] = {
						castTimes = { 6 },
						repeatInterval = nil
					}
				},
				duration = 0.0,
				castTime = 3.0,
			}
		},
		phases = {
			[1] = {
				duration = 90,
				defaultDuration = 90,
				count = 3,
				defaultCount = 3,
				repeatAfter = 2
			},
			[2] = {
				duration = 80,
				defaultDuration = 80,
				count = 3,
				defaultCount = 3,
				repeatAfter = 1
			}
		}
	},
	["Broodtwister Ovi'nax"] = {
		abilities = {
			[441362] = { -- Volatile Concoction
				phases = {
					[1] = {
						castTimes = { 2.0 },
						repeatInterval = nil
					}
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 18.5, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 20.0 },
						}
					}
				},
				duration = 0.0,
				castTime = 1.5,
			},
			[446349] = { -- Sticky Web
				phases = {
					[1] = {
						castTimes = { 15.0 },
						repeatInterval = nil
					}
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 30.0, 30.0, 30.0, 30.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 30.0 },
						}
					}
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[442432] = { -- Ingest Black Blood
				phases = {
					[1] = {
						castTimes = { 19.0, 171.0, 172.0 },
						repeatInterval = nil
					}
				},
				duration = 15.0,
				castTime = 1.0,
			},
			[442526] = { -- Experimental Dosage
				phases = {
					[1] = {
						castTimes = nil,
						repeatInterval = nil
					}
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 16.0, 50.0, 50.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 50.0 },
						}
					}
				},
				duration = 8.0,
				castTime = 1.5,
			},

		},
		phases = {
			[1] = {
				duration = 600,
				defaultDuration = 600,
				count = 1,
				defaultCount = 1,
				repeatAfter = nil
			},
		}
	}
} --[[@as table<integer, Boss>]]

-- Generate a list of abilities for each boss sorted by their first cast time
for _, boss in pairs(bosses) do
	local firstAppearances = {}
	local firstAppearancesMap = {}
	for spellID, data in pairs(boss.abilities) do
		local earliestCastTime = math.huge
		for phaseNumber, phase in pairs(data.phases) do
			if phase.castTimes then
				for _, castTime in ipairs(phase.castTimes) do
					if phaseNumber > 1 then
						local phaseTimeOffset = boss.phases[phaseNumber].duration
						earliestCastTime = math.min(earliestCastTime, phaseTimeOffset + castTime)
					else
						earliestCastTime = math.min(earliestCastTime, castTime)
					end
				end
			end
		end
		firstAppearancesMap[spellID] = earliestCastTime
		tinsert(firstAppearances, { spellID = spellID, earliestCastTime = earliestCastTime })
	end
	local firstEventTriggerAppearancesMap = {}
	for spellID, data in pairs(boss.abilities) do
		local earliestCastTime = math.huge
		if data.eventTriggers then
			for triggerSpellID, eventTrigger in pairs(data.eventTriggers) do
				local earliestTriggerCastTime = firstAppearancesMap[triggerSpellID]
				local castTime = earliestTriggerCastTime + boss.abilities[triggerSpellID].castTime +
					eventTrigger.castTimes[1]
				earliestCastTime = math.min(earliestCastTime, castTime)
			end
			firstEventTriggerAppearancesMap[spellID] = earliestCastTime
		end
	end

	for _, data in pairs(firstAppearances) do
		if firstEventTriggerAppearancesMap[data.spellID] then
			data.earliestCastTime = math.min(data.earliestCastTime, firstEventTriggerAppearancesMap[data.spellID])
		end
	end

	for spellID, earliestCastTime in pairs(firstEventTriggerAppearancesMap) do
		local found = false
		for _, data in pairs(firstAppearances) do
			if data.spellID == spellID then
				found = true
				break
			end
		end
		if not found then
			tinsert(firstAppearances, { spellID = spellID, earliestCastTime = earliestCastTime })
		end
	end

	table.sort(firstAppearances, function(a, b)
		return a.earliestCastTime < b.earliestCastTime
	end)
	boss.sortedAbilityIDs = {}
	for _, entry in ipairs(firstAppearances) do
		table.insert(boss.sortedAbilityIDs, entry.spellID)
	end
end

---comment
---@param spellID number
---@return Boss|nil,BossAbility|nil
local function findBossAbility(spellID)
	for _, boss in pairs(bosses) do
		if boss.abilities[spellID] then return boss, boss.abilities[spellID] end
	end
	return nil, nil
end

---@generic T
---@param inTable table<number, T>
---@return table<number, number>
local function CreateSortedTable(inTable)
	local sorted = {}
	for entry in pairs(inTable) do
		table.insert(sorted, entry)
	end
	table.sort(sorted)
	return sorted
end

-- Sorts assignments based on first appearance in the fight.
---@param assignments table<integer, Assignment>
---@return table<integer, TimelineAssignment>, table<integer, string>
local function CreateSortedAssignmentTables(assignments)
	local sortedAssignments = {} --[[@as table<integer, TimelineAssignment>]]
	for _, assignment in pairs(assignments) do
		if getmetatable(assignment) == Private.CombatLogEventAssignment then
			assignment = assignment --[[@as CombatLogEventAssignment]]
			local _, ability = findBossAbility(assignment.combatLogEventSpellID)
			if ability then
				local startTime = assignment.time
				if assignment.combatLogEventType == "SCC" or assignment.combatLogEventType == "SCS" then
					for i = 1, math.min(assignment.spellCount, #ability.phases[1].castTimes) do
						startTime = startTime + ability.phases[1].castTimes[i]
					end
				end
				if assignment.combatLogEventType == "SCC" then
					startTime = startTime + ability.castTime
				end
				-- TODO: Implement other combat log event types
				tinsert(sortedAssignments,
					Private.TimelineAssignment:new({
						assignment = assignment,
						startTime = startTime,
						offset = nil,
						order = nil
					}))
			end
		elseif getmetatable(assignment) == Private.TimedAssignment then
			assignment = assignment --[[@as TimedAssignment]]
			tinsert(sortedAssignments,
				Private.TimelineAssignment:new({
					assignment = assignment,
					startTime = assignment.time,
					offset = nil,
					order = nil
				}))
		elseif getmetatable(assignment) == Private.PhasedAssignment then
			assignment = assignment --[[@as PhasedAssignment]]
			local boss = bosses["Broodtwister Ovi'nax"]
			if boss then
				local totalOccurances = 0
				for _, phaseData in pairs(boss.phases) do
					totalOccurances = totalOccurances + phaseData.count
				end
				local currentPhase = 1
				local bossPhaseOrder = {}
				local runningStartTime = 0
				while #bossPhaseOrder < totalOccurances and currentPhase ~= nil do
					table.insert(bossPhaseOrder, currentPhase)
					if currentPhase == assignment.phase then
						tinsert(sortedAssignments,
							Private.TimelineAssignment:new({
								assignment = assignment,
								startTime = runningStartTime,
								offset = nil,
								order = nil
							})
						)
					end
					runningStartTime = runningStartTime + boss.phases[currentPhase].duration
					currentPhase = boss.phases[currentPhase].repeatAfter
				end
			end
		end
	end

	-- Sort by first appearance
	table.sort(sortedAssignments --[[@as table<integer, TimelineAssignment>]], function(a, b)
		return a.startTime < b.startTime
	end)

	local order = 1
	local orderAndOffsets = {}
	local assigneeOrder = {}

	for _, entry in ipairs(sortedAssignments --[[@as table<integer, TimelineAssignment>]]) do
		if orderAndOffsets[entry.assignment.assigneeNameOrRole] == nil then
			local offset = 0
			if order ~= 1 then
				offset = (order - 1) * (30 + 2)
			end
			orderAndOffsets[entry.assignment.assigneeNameOrRole] = { order = order, offset = offset }
			entry.order = order
			entry.offset = offset
			assigneeOrder[order] = entry.assignment.assigneeNameOrRole
			order = order + 1
		end
		entry.offset = orderAndOffsets[entry.assignment.assigneeNameOrRole].offset
		entry.order = orderAndOffsets[entry.assignment.assigneeNameOrRole].order
	end
	return sortedAssignments, assigneeOrder
end

---@param data table<integer, DropdownItemData>
local function SortDropdownDataByItemValue(data)
	-- Sort the top-level table
	table.sort(data, function(a, b)
		return a.itemValue < b.itemValue
	end)

	-- Recursively sort any nested dropdownItemMenuData tables
	for _, item in ipairs(data) do
		if item.dropdownItemMenuData and #item.dropdownItemMenuData > 0 then
			SortDropdownDataByItemValue(item.dropdownItemMenuData)
		end
	end
end

---@return table<integer, DropdownItemData>
local function CreateSpellDropdownItems()
	local dropdownItems = {} --[[@as table<integer, DropdownItemData>]]
	local classIndex = 1
	for className, classSpells in pairs(Private.spellDB.classes) do
		local colorMixin = C_ClassColor.GetClassColor(className)
		local coloredName = colorMixin:WrapTextInColorCode(className)
		local classDropdownData = {
			itemValue = className,
			text = coloredName,
			dropdownItemMenuData = {}
		}
		local spellTypeIndex = 1
		local spellTypeIndexMap = {}
		for _, spell in ipairs(classSpells) do
			if not spellTypeIndexMap[spell["type"]] then
				classDropdownData.dropdownItemMenuData[spellTypeIndex] =
				{
					itemValue = spell["type"],
					text = spell["type"],
					dropdownItemMenuData = {}
				}
				spellTypeIndexMap[spell["type"]] = spellTypeIndex
				spellTypeIndex = spellTypeIndex + 1
			end
			local iconText = string.format("|T%s:16|t %s", spell["icon"], spell["name"])
			tinsert(classDropdownData.dropdownItemMenuData[spellTypeIndexMap[spell["type"]]].dropdownItemMenuData, {

				itemValue = spell["name"],
				text = iconText,
				dropdownItemMenuData = {}
			})
		end
		dropdownItems[classIndex] = classDropdownData
		classIndex = classIndex + 1
	end
	SortDropdownDataByItemValue(dropdownItems)
	return { [1] = { itemValue = "Class", text = "Class", dropdownItemMenuData = dropdownItems } }
end

function AddOn:CreateGUI()
	Private.mainFrame = Private.Libs.AGUI:Create("EPMainFrame")
	Private.mainFrame:SetLayout("EPContentFrameLayout")
	Private.mainFrame:SetCallback("OnRelease", function()
		Private.mainFrame = nil
	end)

	local leftSideFrame = Private.Libs.AGUI:Create("SimpleGroup")
	leftSideFrame:SetRelativeWidth(0.2)
	leftSideFrame:SetAutoAdjustHeight(true)
	leftSideFrame:SetLayout("List")

	local dropdown = Private.Libs.AGUI:Create("EPDropdown") --[[@as EPDropdown]]
	dropdown:SetFullWidth(true)
	local dropdownData = {}
	for index, instance in ipairs(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterId)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterId)
		local iconText = string.format("|T%s:16|t %s", iconImage, instance.name)
		tinsert(dropdownData, index, iconText)
	end
	dropdown:AddItems(dropdownData, "EPDropdownItemToggle")
	leftSideFrame:AddChild(dropdown)

	local dropdownSpacer = Private.Libs.AGUI:Create("EPSpacer")
	dropdownSpacer:SetHeight(11)
	leftSideFrame:AddChild(dropdownSpacer)

	local listFrame = Private.Libs.AGUI:Create("SimpleGroup")
	listFrame:SetLayout("List")
	listFrame:SetAutoAdjustHeight(true)
	listFrame:SetFullWidth(true)
	leftSideFrame:AddChild(listFrame)

	local listFrameSpacer = Private.Libs.AGUI:Create("EPSpacer")
	listFrameSpacer:SetHeight(30)
	leftSideFrame:AddChild(listFrameSpacer)

	local assignmentListFrame = Private.Libs.AGUI:Create("SimpleGroup")
	assignmentListFrame:SetLayout("List")
	assignmentListFrame:SetAutoAdjustHeight(true)
	assignmentListFrame:SetFullWidth(true)

	Private:Note()

	local sortedAssignments, assigneeOrder = CreateSortedAssignmentTables(Private.assignments)
	for index = 1, #assigneeOrder do
		local abilityEntry = Private.Libs.AGUI:Create("EPAbilityEntry") --[[@as EPAbilityEntry]]
		abilityEntry:SetText(assigneeOrder[index])
		abilityEntry:SetFullWidth(true)
		abilityEntry:SetHeight(30)
		assignmentListFrame:AddChild(abilityEntry)
		if index ~= #assigneeOrder then
			local spacer = Private.Libs.AGUI:Create("EPSpacer")
			spacer:SetHeight(2)
			spacer:SetFullWidth(true)
			assignmentListFrame:AddChild(spacer)
		end
	end
	assignmentListFrame:DoLayout()
	leftSideFrame:AddChild(assignmentListFrame)

	local timelineSpacer = Private.Libs.AGUI:Create("EPSpacer")
	timelineSpacer:SetHeight(37)
	timelineSpacer:SetRelativeWidth(0.8)

	local timeline = Private.Libs.AGUI:Create("EPTimeline") --[[@as EPTimeline]]
	timeline:SetNewAssignmentFunc(function()
		return Private.Assignment:new({})
	end)
	timeline:SetSpellDropdownItemsFunc(function()
		return CreateSpellDropdownItems()
	end)
	timeline:SetRelativeWidth(0.8)

	Private.mainFrame:AddChild(leftSideFrame)
	Private.mainFrame:AddChild(timelineSpacer)
	Private.mainFrame:AddChild(timeline)

	local function dropdownCallback(frame, callbackName, value)
		if AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses[value] then
			local boss = bosses[AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses[value].name]
			if boss then
				listFrame:ReleaseChildren()
				for index = 1, #boss.sortedAbilityIDs do
					local abilityEntry = Private.Libs.AGUI:Create("EPAbilityEntry") --[[@as EPAbilityEntry]]
					abilityEntry:SetFullWidth(true)
					abilityEntry:SetAbility(boss.sortedAbilityIDs[index])
					listFrame:AddChild(abilityEntry)
					if index ~= #boss.sortedAbilityIDs then
						local spacer = Private.Libs.AGUI:Create("EPSpacer")
						spacer:SetHeight(4)
						spacer:SetFullWidth(true)
						listFrame:AddChild(spacer)
					end
				end
				listFrame:DoLayout()
				timeline:SetEntries(boss.abilities, boss.sortedAbilityIDs, boss.phases, sortedAssignments, assigneeOrder)
			end
		end
	end
	dropdown:SetCallback("OnValueChanged", dropdownCallback)

	dropdown:SetValue(5)
	dropdownCallback(nil, nil, 5)
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.DB = LibStub("AceDB-3.0"):New(AddOnName .. "DB", self.Defaults)
	self.DB.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("ep", "SlashCommand")
	self:RegisterChatCommand(AddOnName, "SlashCommand")
	self.OnInitialize = nil
end

function AddOn:OnEnable()
	self:Refresh()
end

function AddOn:Refresh()
end

-- Slash command functionality
function AddOn:SlashCommand(input)
	DevTool:AddData(Private)
	if not Private.mainFrame then
		self:CreateGUI()
		-- if AddOn:GetModule("Options") then
		-- 	AddOn.OptionsModule:OpenOptions()
		-- end
	end
end

-- Loads all the set options after game loads and player enters world
function AddOn:PLAYER_ENTERING_WORLD(eventName)
end
