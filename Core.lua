--@type string
local AddOnName = ...
---@class Private
local Private = select(2, ...)
local AddOn = Private.AddOn

local function NewBoss(name, bossIds, journalEncounterId, dungeonEncounterId)
	return {
		name = name,
		bossIds = bossIds,
		journalEncounterId = journalEncounterId,
		dungeonEncounterId = dungeonEncounterId
	}
end

AddOn.Defaults         = {
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
				order = { 1, 2, 3, 4, 5, 6, 7, 8 }
			}
		}
	}
}

local colors           = {
	{ 255, 87,  51, 1 },
	{ 51,  255, 87, 1 }, { 51, 87, 255, 1 }, { 255, 51, 184, 1 }, { 255, 214, 51, 1 },
	{ 51, 255, 249, 1 }, { 184, 51, 255, 1 } }

local bosses           = {
	["Ulgrax the Devourer"] = {
		["abilities"] = {
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
		["phases"] = {
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
		},
		sortedAbilityIDs = {}
	}
}

local firstAppearances = {}
for spellID, data in pairs(bosses["Ulgrax the Devourer"]["abilities"]) do
	local earliestCastTime = math.huge
	for phaseNumber, phase in pairs(data.phases) do
		for _, castTime in ipairs(phase.castTimes) do
			if phaseNumber > 1 then
				earliestCastTime = math.min(earliestCastTime,
					castTime + bosses["Ulgrax the Devourer"]["phases"][phaseNumber].duration)
			else
				earliestCastTime = math.min(earliestCastTime, castTime)
			end
		end
	end
	table.insert(firstAppearances, { spellID = spellID, firstAppearance = earliestCastTime })
end

-- Step 3: Sort by first appearance time
table.sort(firstAppearances, function(a, b)
	return a.firstAppearance < b.firstAppearance
end)

for _, entry in ipairs(firstAppearances) do
	table.insert(bosses["Ulgrax the Devourer"].sortedAbilityIDs, entry.spellID)
end

-- Addon is first loaded
function AddOn:OnInitialize()
	self.DB = LibStub("AceDB-3.0"):New(AddOnName .. "DB", self.Defaults)
	self.DB.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.DB.RegisterCallback(self, "OnProfileReset", "Refresh")
	self:RegisterChatCommand("ep", "SlashCommand")
	self:RegisterChatCommand(AddOnName, "SlashCommand")

	Private.mainFrame = Private.Libs.AGUI:Create("EPMainFrame")
	Private.mainFrame:SetLayout("flow")
	Private.mainFrame:SetFullWidth(true)
	Private.selectedBoss = nil

	local listFrame = Private.Libs.AGUI:Create("SimpleGroup")
	listFrame:SetRelativeWidth(0.2)
	listFrame:SetLayout("List")

	local dropdown = Private.Libs.AGUI:Create("EPDropdown")
	local items = {}
	for index, instance in pairs(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterId)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterId)
		local iconText = string.format("|T%s:16|t %s", iconImage, instance.name)
		table.insert(items, index, iconText)
	end
	dropdown:SetList(items, AddOn.Defaults.profile.instances["Nerub'ar Palace"].order, "EPDropdownItemToggle")
	listFrame:AddChild(dropdown)

	local sorted = {}
	for _, spellID in ipairs(bosses["Ulgrax the Devourer"].sortedAbilityIDs) do
		local abilityEntry = Private.Libs.AGUI:Create("EPAbilityEntry")
		abilityEntry:SetAbility(spellID)
		listFrame:AddChild(abilityEntry)
		local spacer = Private.Libs.AGUI:Create("EPSpacer")
		spacer:SetHeight(4)
		listFrame:AddChild(spacer)
		table.insert(sorted, bosses["Ulgrax the Devourer"]["abilities"][spellID])
	end
	local spacer = Private.Libs.AGUI:Create("EPSpacer")
	spacer:SetHeight(128)
	listFrame:AddChild(spacer)
	local timeline = Private.Libs.AGUI:Create("EPTimeline")
	timeline:SetRelativeWidth(0.8)
	timeline:SetHeight(400)
	Private.mainFrame:AddChild(listFrame)
	Private.mainFrame:AddChild(timeline)

	timeline:SetEntries(sorted, bosses["Ulgrax the Devourer"]["phases"])

	self.OnInitialize = nil
end

function AddOn:OnEnable()
	self:Refresh()
end

function AddOn:Refresh()
end

-- slash command functionality
function AddOn:SlashCommand(input)
	Private.mainFrame:Show()
	if AddOn:GetModule("Options") then
		AddOn.OptionsModule:OpenOptions()
	end
end

-- loads all the set options after game loads and player enters world
function AddOn:PLAYER_ENTERING_WORLD(eventName)
end
