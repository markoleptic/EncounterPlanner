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
	} --[[@as Boss]],
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
	} --[[@as Boss]]
}

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
---@return BossAbility|nil
local function findBossAbility(spellID)
	for _, boss in pairs(bosses) do
		if boss.abilities[spellID] then return boss.abilities[spellID] end
	end
	return nil
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

---@param combatLogEventBasedAssignments CombatLogEventBasedTimers
---@param absoluteTimeBasedTimers table<integer, table<number, table<integer, AbsoluteTimeBasedTimer>>>
---@return table<integer, TimelineAssignment>, table<integer, string>
local function CreateSortedAssignmentTables(combatLogEventBasedAssignments, absoluteTimeBasedTimers)
	local sortedAssignments = {}

	-- Add combat log event based assignments first, use ipairs and CreateSortedTable to make sure start time is accurate
	for _, combatLogEvent in pairs(combatLogEventBasedAssignments) do
		for spellID, spellOccurances in pairs(combatLogEvent) do
			local ability = findBossAbility(spellID)
			if ability then
				local cumTime = 0
				for _, spellOccuranceNumber in ipairs(CreateSortedTable(spellOccurances)) do
					cumTime = cumTime + ability.phases[1].castTimes[spellOccuranceNumber] + ability.castTime
					local timeEntries = spellOccurances[spellOccuranceNumber]
					for _, time in ipairs(CreateSortedTable(timeEntries)) do
						for _, entry in pairs(timeEntries[time]) do
							if entry.spellInfo.spellID == 1044 then
								print(cumTime, time)
							end
							tinsert(sortedAssignments, {
								assignedUnit = entry.assignedUnit,
								assigneeNameOrRole = entry.assigneeNameOrRole,
								spellInfo = entry.spellInfo,
								strWithIconReplacements = entry.strWithIconReplacements,
								startTime = cumTime + time,
								offset = nil
							})
						end
					end
				end
			end
		end
	end

	-- Add absolute time based assignments
	for _, timerGroup in pairs(absoluteTimeBasedTimers) do
		for _, entries in pairs(timerGroup) do
			for _, entry in pairs(entries) do
				tinsert(sortedAssignments, {
					assignedUnit = entry.assignedUnit,
					assigneeNameOrRole = entry.assigneeNameOrRole,
					spellInfo = entry.spellInfo,
					strWithIconReplacements = entry.strWithIconReplacements,
					startTime = entry.time,
					offset = nil
				})
			end
		end
	end

	-- Sort by first appearance
	table.sort(sortedAssignments, function(a, b)
		return a.startTime < b.startTime
	end)

	local assigneeIndex = 1
	local offsets = {}
	local assigneeOrder = {}

	-- Create assigneeOrder table and assign offsets
	for _, entry in ipairs(sortedAssignments) do
		if offsets[entry.assigneeNameOrRole] == nil then
			local offset = 0
			if assigneeIndex ~= 1 then
				offset = (assigneeIndex - 1) * (30 + 2)
			end
			assigneeOrder[assigneeIndex] = entry.assigneeNameOrRole
			offsets[entry.assigneeNameOrRole] = offset
			assigneeIndex = assigneeIndex + 1
		end
		entry.offset = offsets[entry.assigneeNameOrRole]
	end

	return sortedAssignments, assigneeOrder
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
	local items = {}
	for index, instance in pairs(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterId)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterId)
		local iconText = string.format("|T%s:16|t %s", iconImage, instance.name)
		table.insert(items, index, iconText)
	end
	dropdown:SetList(items, AddOn.Defaults.profile.instances["Nerub'ar Palace"].order, "EPDropdownItemToggle")
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

	local sortedAssignments, assigneeOrder = CreateSortedAssignmentTables(Private.combatLogEventBasedTimers,
		Private.absoluteTimeBasedTimers)
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
	self:CreateGUI()
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
