--@type string
local AddOnName = ...

---@class Private
local Private = select(2, ...) --[[@as Private]]

local AddOn = Private.AddOn
local ipairs = ipairs
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert

function AddOn:NewBoss(name, bossIds, journalEncounterId, dungeonEncounterId)
	return {
		name = name,
		bossIds = bossIds,
		journalEncounterId = journalEncounterId,
		dungeonEncounterId = dungeonEncounterId,
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
					AddOn:NewBoss("Ulgrax the Devourer", 215657, 2607, 2902),
					AddOn:NewBoss("The Bloodbound Horror", 214502, 2611, 2917),
					AddOn:NewBoss("Sikran, Captain of the Sureki", 214503, 2599, 2898),
					AddOn:NewBoss("Rasha'nan", 214504, 2609, 2918),
					AddOn:NewBoss("Broodtwister Ovi'nax", 214506, 2612, 2919),
					AddOn:NewBoss("Nexus-Princess Ky'veza", 217748, 2601, 2920),
					AddOn:NewBoss("The Silken Court", { 217489, 217491 }, 2608, 2921),
					AddOn:NewBoss("Queen Ansurek", 218370, 2602, 2922),
				},
				order = { 1, 2, 3, 4, 5, 6, 7, 8 },
			},
		},
	},
}

local bosses = {
	["Ulgrax the Devourer"] = {
		abilities = {
			[435136] = { -- Venomous Lash
				phases = {
					[1] = {
						castTimes = { 5.0, 25.0, 28.0 },
						repeatInterval = nil,
					},
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[435138] = { -- Digestive Acid
				phases = {
					[1] = {
						castTimes = { 20.0, 47.0 },
						repeatInterval = nil,
					},
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[434803] = { -- Carnivorous Contest
				phases = {
					[1] = {
						castTimes = { 38.0, 36.0 },
						repeatInterval = nil,
					},
				},
				duration = 6.0,
				castTime = 4.0,
			},
			[445123] = { -- Hulking Crash
				phases = {
					[1] = {
						castTimes = { 90.0 },
						repeatInterval = nil,
					},
				},
				duration = 0.0,
				castTime = 5.0,
			},
			[436200] = { -- Juggernaut Charge
				phases = {
					[2] = {
						castTimes = { 16.7, 7.1, 7.1, 7.1 },
						repeatInterval = nil,
					},
				},
				duration = 8.0,
				castTime = 4.0,
			},
			[438012] = { -- Hungering Bellows
				phases = {
					[2] = {
						castTimes = { 60.8 },
						repeatInterval = 7,
					},
				},
				duration = 3.0,
				castTime = 3.0,
			},
			[445052] = { -- Chittering Swarm
				phases = {
					[2] = {
						castTimes = { 6 },
						repeatInterval = nil,
					},
				},
				duration = 0.0,
				castTime = 3.0,
			},
		},
		phases = {
			[1] = {
				duration = 90,
				defaultDuration = 90,
				count = 3,
				defaultCount = 3,
				repeatAfter = 2,
			},
			[2] = {
				duration = 80,
				defaultDuration = 80,
				count = 3,
				defaultCount = 3,
				repeatAfter = 1,
			},
		},
	},
	["Broodtwister Ovi'nax"] = {
		abilities = {
			[441362] = { -- Volatile Concoction
				phases = {
					[1] = {
						castTimes = { 2.0 },
						repeatInterval = nil,
					},
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 18.5, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0, 20.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 20.0 },
						},
					},
				},
				duration = 0.0,
				castTime = 1.5,
			},
			[446349] = { -- Sticky Web
				phases = {
					[1] = {
						castTimes = { 15.0 },
						repeatInterval = nil,
					},
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 30.0, 30.0, 30.0, 30.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 30.0 },
						},
					},
				},
				duration = 6.0,
				castTime = 2.0,
			},
			[442432] = { -- Ingest Black Blood
				phases = {
					[1] = {
						castTimes = { 19.0, 171.0, 172.0 },
						repeatInterval = nil,
					},
				},
				duration = 15.0,
				castTime = 1.0,
			},
			[442526] = { -- Experimental Dosage
				phases = {
					[1] = {
						castTimes = nil,
						repeatInterval = nil,
					},
				},
				eventTriggers = {
					[442432] = { -- Ingest Black Blood
						cleuEventType = "SCS",
						castTimes = { 16.0, 50.0, 50.0 },
						repeatCriteria = {
							castOccurance = 3,
							castTimes = { 50.0 },
						},
					},
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
				repeatAfter = nil,
			},
		},
	},
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
						earliestCastTime = min(earliestCastTime, phaseTimeOffset + castTime)
					else
						earliestCastTime = min(earliestCastTime, castTime)
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
				local castTime = earliestTriggerCastTime
					+ boss.abilities[triggerSpellID].castTime
					+ eventTrigger.castTimes[1]
				earliestCastTime = min(earliestCastTime, castTime)
			end
			firstEventTriggerAppearancesMap[spellID] = earliestCastTime
		end
	end

	for _, data in pairs(firstAppearances) do
		if firstEventTriggerAppearancesMap[data.spellID] then
			data.earliestCastTime = min(data.earliestCastTime, firstEventTriggerAppearancesMap[data.spellID])
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

	sort(firstAppearances, function(a, b)
		return a.earliestCastTime < b.earliestCastTime
	end)
	boss.sortedAbilityIDs = {}
	for _, entry in ipairs(firstAppearances) do
		tinsert(boss.sortedAbilityIDs, entry.spellID)
	end
end

---@param bossName string
---@return table|nil
function AddOn:GetBossDefinition(bossName)
	local bossDefinition = AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses[bossName]
	if bossDefinition then
		return bossDefinition
	end
	return nil
end

---@param bossName string
---@return Boss|nil
function AddOn:GetBoss(bossName)
	local boss = bosses[bossName]
	if boss then
		return boss
	end
	return nil
end

---@param spellID number
---@return BossAbility|nil
function AddOn:FindBossAbility(spellID)
	for _, boss in pairs(bosses) do
		if boss.abilities[spellID] then
			return boss.abilities[spellID]
		end
	end
	return nil
end
