local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L
---@class EventTrigger
local EventTrigger = Private.classes.EventTrigger
---@class Boss
local Boss = Private.classes.Boss
---@class BossAbility
local BossAbility = Private.classes.BossAbility
---@class BossAbilityPhase
local BossAbilityPhase = Private.classes.BossAbilityPhase
---@class BossPhase
local BossPhase = Private.classes.BossPhase
---@class DungeonInstance
local DungeonInstance = Private.classes.DungeonInstance

Private.dungeonInstances[2912] = DungeonInstance:New({
	journalInstanceID = 1307,
	instanceID = 2912,
	customGroups = { "MidnightSeasonOne" },
	bosses = {
		Boss:New({ -- Averzian
			bossIDs = {
				240435, -- Averzian
				252918, -- Abyssal Voidshaper
				251176, -- Voidmaw
				255304, -- Shadowguard Stalwart
				251267, -- Obscurion Endwalker
				257950, -- Abyssal Malus
				256757, -- Voidbound Annihilator
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5911] = 240435, -- Averzian
				[6065] = 252918, -- Abyssal Voidshaper
				[6073] = 251176, -- Voidmaw
				[6064] = 255304, -- Shadowguard Stalwart
				[6063] = 251267, -- Obscurion Endwalker
				[6143] = 257950, -- Abyssal Malus
				[6152] = 256757, -- Voidbound Annihilator
			},
			journalEncounterID = 2733,
			dungeonEncounterID = 3176,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
		Boss:New({ -- Vorasius
			bossIDs = {
				240434, -- Vorasius
				250564, -- Blistercreep
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5913] = 240434, -- Vorasius
				[5981] = 250564, -- Blistercreep
			},
			journalEncounterID = 2734,
			dungeonEncounterID = 3177,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
		Boss:New({ -- Vaelgor & Ezzorak
			bossIDs = {
				242056, -- Vaelgor
				254109, -- Ezzorak
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5949] = 242056, -- Vaelgor
				[6006] = 254109, -- Ezzorak
			},
			journalEncounterID = 2735,
			dungeonEncounterID = 3178,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
		Boss:New({ -- Fallen-King Salhadaar
			bossIDs = {
				240432, -- Fallen-King Salhadaar
				246665, -- Concentrated Void
				251791, -- Fractured Image
				255280, -- Enduring Void
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5908] = 240432, -- Fallen-King Salhadaar
				[6090] = 246665, -- Concentrated Void
				[6067] = 251791, -- Fractured Image
				[6154] = 255280, -- Enduring Void
			},
			journalEncounterID = 2736,
			dungeonEncounterID = 3179,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
		Boss:New({ -- Lightblinded Vanguard
			bossIDs = {
				250589, -- War Chaplain Senn
				250587, -- General Amias Bellamy
				250588, -- Commander Venel Lightblood
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5972] = 250589, -- War Chaplain Senn
				[5971] = 250587, -- General Amias Bellamy
				[5970] = 250588, -- Commander Venel Lightblood
			},
			journalEncounterID = 2737,
			dungeonEncounterID = 3180,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
		Boss:New({ -- Crown of the Cosmos
			bossIDs = {
				244761, -- Alleria Windrunner
				254172, -- Vorelus
				254173, -- Demiar
				254174, -- Morium
			},
			journalEncounterCreatureIDsToBossIDs = {
				[5906] = 244761, -- Alleria Windrunner
				[5975] = 254172, -- Vorelus
				[5976] = 254173, -- Demiar
				[5977] = 254174, -- Morium
			},
			journalEncounterID = 2738,
			dungeonEncounterID = 3181,
			instanceID = 2912,
			abilities = {},
			phases = {},
			abilitiesHeroic = {},
			phasesHeroic = {},
		}),
	},
	isRaid = true,
})
