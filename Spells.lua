local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local pairs = pairs

-- Credit to Treebonker and OmniCD for this entire data structure
Private.spellDB = {
	classes = {
		["WARRIOR"] = {
			{
				["type"] = L["Other"],
				["name"] = "Taunt",
				["spellID"] = 355,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Shield Block",
				["spellID"] = 2565,
			},
			{
				["type"] = L["Other"],
				["name"] = "Pummel",
				["spellID"] = 6552,
			},
			{
				["type"] = L["Other"],
				["name"] = "Charge",
				["spellID"] = 100,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Sweeping Strikes",
				["spellID"] = 260708,
			},
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Die by the Sword",
				["spellID"] = 118038,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Colossus Smash",
				["spellID"] = 167105,
				["talent"] = 262161,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Last Stand",
				["spellID"] = 12975,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Demoralizing Shout",
				["spellID"] = 1160,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Disrupting Shout",
				["spellID"] = 386071,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Challenging Shout",
				["spellID"] = 1161,
				["talent"] = 386071,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Shield Wall",
				["spellID"] = 871,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Shield Charge",
				["spellID"] = 385952,
			},
			{
				["type"] = L["Other"],
				["name"] = "Impending Victory",
				["spellID"] = 202168,
			},
			{
				["type"] = L["Other"],
				["name"] = "Intervene",
				["spellID"] = 3411,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Rallying Cry",
				["spellID"] = 97462,
			},
			{
				["type"] = L["Other"],
				["name"] = "Storm Bolt",
				["spellID"] = 107570,
			},
			{
				["type"] = L["Other"],
				["name"] = "Heroic Leap",
				["spellID"] = 6544,
			},
			{
				["type"] = L["Other"],
				["name"] = "Piercing Howl",
				["spellID"] = 12323,
			},
			{
				["type"] = L["Other"],
				["name"] = "Berserker Shout",
				["spellID"] = 384100,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shattering Throw",
				["spellID"] = 64382,
			},
			{
				["type"] = L["Other"],
				["name"] = "Wrecking Throw",
				["spellID"] = 384110,
			},
			{
				["type"] = L["Other"],
				["name"] = "Bitter Immunity",
				["spellID"] = 383762,
			},
			{
				["type"] = L["Core"],
				["name"] = "Avatar",
				["spellID"] = 107574,
			},
			{
				["type"] = L["Other"],
				["name"] = "Berserker Rage",
				["spellID"] = 18499,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shockwave",
				["spellID"] = 46968,
			},
			{
				["type"] = L["Core"],
				["name"] = "Champion's Spear",
				["spellID"] = 376079,
			},
			{
				["type"] = L["Other"],
				["name"] = "Intimidating Shout",
				["spellID"] = 5246,
			},
			{
				["type"] = L["Core"],
				["name"] = "Spell Reflection",
				["spellID"] = 23920,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Ravager",
				["spellID"] = 228920,
			},
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Enraged Regeneration",
				["spellID"] = 184364,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Recklessness",
				["spellID"] = 1719,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Odyn's Fury",
				["spellID"] = 385059,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Bladestorm",
				["spellID"] = 227847,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Demolish",
				["spellID"] = 436358,
			},
		},
		["ROGUE"] = {
			{
				["type"] = L["Other"],
				["name"] = "Between the Eyes",
				["spellID"] = 315341,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Shroud of Concealment",
				["spellID"] = 114018,
			},
			{
				["type"] = L["Other"],
				["name"] = "Kidney Shot",
				["spellID"] = 408,
			},
			{
				["type"] = L["Other"],
				["name"] = "Kick",
				["spellID"] = 1766,
			},
			{
				["type"] = L["Other"],
				["name"] = "Distract",
				["spellID"] = 1725,
			},
			{
				["type"] = L["Other"],
				["name"] = "Crimson Vial",
				["spellID"] = 185311,
			},
			{
				["type"] = L["Core"],
				["name"] = "Vanish",
				["spellID"] = 1856,
			},
			{
				["type"] = L["Other"],
				["name"] = "Sprint",
				["spellID"] = 2983,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Feint",
				["spellID"] = 1966,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blade Rush",
				["spellID"] = 271877,
			},
			{
				["type"] = L["Core"],
				["name"] = "Keep It Rolling",
				["spellID"] = 381989,
			},
			{
				["type"] = L["Core"],
				["name"] = "Roll the Bones",
				["spellID"] = 315508,
			},
			{
				["type"] = L["Core"],
				["name"] = "Adrenaline Rush",
				["spellID"] = 13750,
			},
			{
				["type"] = L["Core"],
				["name"] = "Killing Spree",
				["spellID"] = 51690,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blade Flurry",
				["spellID"] = 13877,
			},
			{
				["type"] = L["Other"],
				["name"] = "Grappling Hook",
				["spellID"] = 195457,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blind",
				["spellID"] = 2094,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tricks of the Trade",
				["spellID"] = 57934,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shadowstep",
				["spellID"] = 36554,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Cloak of Shadows",
				["spellID"] = 31224,
			},
			{
				["type"] = L["Core"],
				["name"] = "Secret Technique",
				["spellID"] = 280719,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shuriken Tornado",
				["spellID"] = 277925,
			},
			{
				["type"] = L["Core"],
				["name"] = "Shadow Blades",
				["spellID"] = 121471,
			},
			{
				["type"] = L["Core"],
				["name"] = "Shiv",
				["spellID"] = 5938,
			},
			{
				["type"] = L["Other"],
				["name"] = "Gouge",
				["spellID"] = 1776,
			},
			{
				["type"] = L["Other"],
				["name"] = "Thistle Tea",
				["spellID"] = 381623,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Evasion",
				["spellID"] = 5277,
			},
			{
				["type"] = L["Core"],
				["name"] = "Deathmark",
				["spellID"] = 360194,
			},
			{
				["type"] = L["Core"],
				["name"] = "Kingsbane",
				["spellID"] = 385627,
			},
		},
		["DEMONHUNTER"] = {
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Blur",
				["spellID"] = 198589,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Infernal Strike",
				["spellID"] = 189110,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Fel Rush",
				["spellID"] = 195072,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Demon Spikes",
				["spellID"] = 203720,
			},
			{
				["type"] = L["Other"],
				["name"] = "Torment",
				["spellID"] = 185245,
			},
			{
				["type"] = L["Other"],
				["name"] = "Spectral Sight",
				["spellID"] = 188501,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Metamorphosis",
				["spellID"] = 187827,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Metamorphosis",
				["spellID"] = 191427,
			},
			{
				["type"] = L["Other"],
				["name"] = "Immolation Aura",
				["spellID"] = 258920,
			},
			{
				["type"] = L["Other"],
				["name"] = "Disrupt",
				["spellID"] = 183752,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "The Hunt",
				["spellID"] = 370965,
			},
			{
				["type"] = L["Other"],
				["name"] = "Felblade",
				["spellID"] = 232893,
			},
			{
				["type"] = L["Other"],
				["name"] = "Vengeful Retreat",
				["spellID"] = 198793,
			},
			{
				["type"] = L["Other"],
				["name"] = "Sigil of Flame",
				["spellID"] = 204596,
			},
			{
				["type"] = L["Other"],
				["name"] = "Sigil of Misery",
				["spellID"] = 207684,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Fiery Brand",
				["spellID"] = 204021,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Sigil of Chains",
				["spellID"] = 202138,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Soul Barrier",
				["spellID"] = 263648,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Sigil of Spite",
				["spellID"] = 390163,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Soul Carver",
				["spellID"] = 207407,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Sigil of Silence",
				["spellID"] = 202137,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Fel Devastation",
				["spellID"] = 212084,
			},
			{
				["type"] = L["Other"],
				["name"] = "Chaos Nova",
				["spellID"] = 179057,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Darkness",
				["spellID"] = 196718,
			},
			{
				["type"] = L["Other"],
				["name"] = "Consume Magic",
				["spellID"] = 278326,
			},
			{
				["type"] = L["Other"],
				["name"] = "Imprison",
				["spellID"] = 217832,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Eye Beam",
				["spellID"] = 198013,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Glaive Tempest",
				["spellID"] = 342817,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Essence Break",
				["spellID"] = 258860,
			},
		},
		["MONK"] = {
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Detox",
				["spellID"] = 115450,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Mana Tea",
				["spellID"] = 115869,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Touch of Death",
				["spellID"] = 322109,
			},
			{
				["type"] = L["Other"],
				["name"] = "Provoke",
				["spellID"] = 115546,
			},
			{
				["type"] = L["Other"],
				["name"] = "Leg Sweep",
				["spellID"] = 119381,
			},
			{
				["type"] = L["Other"],
				["name"] = "Transcendence: Transfer",
				["spellID"] = 119996,
			},
			{
				["type"] = L["Other"],
				["name"] = "Roll",
				["spellID"] = 109132,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Jadefire Stomp",
				["spellID"] = 388193,
			},
			{
				["type"] = L["Other"],
				["name"] = "Song of Chi-Ji",
				["spellID"] = 198898,
			},
			{
				["type"] = L["Other"],
				["name"] = "Refreshing Jade Wind",
				["spellID"] = 196725,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Restoral",
				["spellID"] = 388615,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Revival",
				["spellID"] = 115310,
			},
			{
				["type"] = L["External Defensive"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Life Cocoon",
				["spellID"] = 116849,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Invoke Yu'lon, the Jade Serpent",
				["spellID"] = 322118,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Invoke Chi-Ji, the Red Crane",
				["spellID"] = 325197,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Thunder Focus Tea",
				["spellID"] = 116680,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true, ["role:damager"] = true },
				["name"] = "Detox",
				["spellID"] = 218164,
			},
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Touch of Karma",
				["spellID"] = 122470,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Fists of Fury",
				["spellID"] = 113656,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Flying Serpent Kick",
				["spellID"] = 101545,
			},
			{
				["type"] = L["Other"],
				["name"] = "Clash",
				["spellID"] = 324312,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Black Ox Brew",
				["spellID"] = 115399,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Summon Black Ox Statue",
				["spellID"] = 115315,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Celestial Brew",
				["spellID"] = 322507,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Celestial Infusion",
				["spellID"] = 1241059,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Invoke Xuen, the White Tiger",
				["spellID"] = 123904,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Whirling Dragon Punch",
				["spellID"] = 152175,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Strike of the Windlord",
				["spellID"] = 392983,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Fortifying Brew",
				["spellID"] = 115203,
			},
			{
				["type"] = L["Other"],
				["name"] = "Chi Torpedo",
				["spellID"] = 115008,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true, ["role:tank"] = true },
				["name"] = "Spear Hand Strike",
				["spellID"] = 116705,
			},
			{
				["type"] = L["Other"],
				["name"] = "Paralysis",
				["spellID"] = 115078,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tiger's Lust",
				["spellID"] = 116841,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Diffuse Magic",
				["spellID"] = 122783,
			},
			{
				["type"] = L["Other"],
				["name"] = "Ring of Peace",
				["spellID"] = 116844,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Chi Burst",
				["spellID"] = 123986,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Exploding Keg",
				["spellID"] = 325153,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Invoke Niuzao, the Black Ox",
				["spellID"] = 132578,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Purifying Brew",
				["spellID"] = 119582,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true, ["role:healer"] = true },
				["name"] = "Celestial Conduit",
				["spellID"] = 443028,
			},
		},
		["DEATHKNIGHT"] = {
			{
				["type"] = L["Other"],
				["name"] = "Lichborne",
				["spellID"] = 49039,
			},
			{
				["type"] = L["Other"],
				["name"] = "Death's Advance",
				["spellID"] = 48265,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Death Grip",
				["spellID"] = 49576,
			},
			{
				["type"] = L["Other"],
				["name"] = "Dark Command",
				["spellID"] = 56222,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Remorseless Winter",
				["spellID"] = 196770,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blinding Sleet",
				["spellID"] = 207167,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Empower Rune Weapon",
				["spellID"] = 47568,
			},
			{
				["type"] = L["Other"],
				["name"] = "Asphyxiate",
				["spellID"] = 221562,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Anti-Magic Zone",
				["spellID"] = 51052,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Anti-Magic Shell",
				["spellID"] = 48707,
			},
			{
				["type"] = L["Other"],
				["name"] = "Raise Dead",
				["spellID"] = 46585,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Death Pact",
				["spellID"] = 48743,
			},
			{
				["type"] = L["Other"],
				["name"] = "Wraith Walk",
				["spellID"] = 212552,
			},
			{
				["type"] = L["Other"],
				["name"] = "Mind Freeze",
				["spellID"] = 47528,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Icebound Fortitude",
				["spellID"] = 48792,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Breath of Sindragosa",
				["spellID"] = 152279,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Frostwyrm's Fury",
				["spellID"] = 279302,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Pillar of Frost",
				["spellID"] = 51271,
			},
			{
				["type"] = L["Group Utility"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Gorefiend's Grasp",
				["spellID"] = 108199,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Dancing Rune Weapon",
				["spellID"] = 49028,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Consumption",
				["spellID"] = 274156,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Unholy Assault",
				["spellID"] = 207289,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Vampiric Blood",
				["spellID"] = 55233,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Summon Gargoyle",
				["spellID"] = 49206,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Dark Transformation",
				["spellID"] = 63560,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Army of the Dead",
				["spellID"] = 42650,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Frostscythe",
				["spellID"] = 207230,
			},
			{
				["type"] = L["Core"],
				["name"] = "Reaper's Mark",
				["spellID"] = 439843,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Death Charge",
				["spellID"] = 444347,
			},
		},
		["HUNTER"] = {
			{
				["type"] = L["Other"],
				["name"] = "Freezing Trap",
				["spellID"] = 187650,
			},
			{
				["type"] = L["Other"],
				["name"] = "Flare",
				["spellID"] = 1543,
			},
			{
				["type"] = L["Other"],
				["name"] = "Feign Death",
				["spellID"] = 5384,
			},
			{
				["type"] = L["Other"],
				["name"] = "Disengage",
				["spellID"] = 781,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Aspect of the Turtle",
				["spellID"] = 186265,
			},
			{
				["type"] = L["Other"],
				["name"] = "Aspect of the Cheetah",
				["spellID"] = 186257,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Exhilaration",
				["spellID"] = 109304,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Survival of the Fittest",
				["spellID"] = 264735,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Fortitude of the Bear",
				["spellID"] = 392956,
			},
			{
				["type"] = L["Other"],
				["name"] = "Muzzle",
				["spellID"] = 187707,
			},
			{
				["type"] = L["Other"],
				["name"] = "Harpoon",
				["spellID"] = 190925,
			},
			{
				["type"] = L["Other"],
				["name"] = "Bursting Shot",
				["spellID"] = 186387,
			},
			{
				["type"] = L["Other"],
				["name"] = "Rapid Fire",
				["spellID"] = 257044,
			},
			{
				["type"] = L["Core"],
				["name"] = "Trueshot",
				["spellID"] = 288613,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tranquilizing Shot",
				["spellID"] = 19801,
			},
			{
				["type"] = L["Other"],
				["name"] = "Intimidation",
				["spellID"] = 19577,
			},
			{
				["type"] = L["Other"],
				["name"] = "High Explosive Trap",
				["spellID"] = 236776,
			},
			{
				["type"] = L["Core"],
				["name"] = "Explosive Shot",
				["spellID"] = 212431,
			},
			{
				["type"] = L["Other"],
				["name"] = "Misdirection",
				["spellID"] = 34477,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tar Trap",
				["spellID"] = 187698,
			},
			{
				["type"] = L["Other"],
				["name"] = "Camouflage",
				["spellID"] = 199483,
			},
			{
				["type"] = L["Other"],
				["name"] = "Scatter Shot",
				["spellID"] = 213691,
			},
			{
				["type"] = L["Other"],
				["name"] = "Binding Shot",
				["spellID"] = 109248,
			},
			{
				["type"] = L["Core"],
				["name"] = "Bloodshed",
				["spellID"] = 321530,
			},
			{
				["type"] = L["Core"],
				["name"] = "Bestial Wrath",
				["spellID"] = 19574,
			},
			{
				["type"] = L["Core"],
				["name"] = "Call of the Wild",
				["spellID"] = 359844,
			},
			{
				["type"] = L["Other"],
				["name"] = "Black Arrow",
				["spellID"] = 468037,
			},
			{
				["type"] = L["Other"],
				["name"] = "Implosive Trap",
				["spellID"] = 462031,
			},
			{
				["type"] = L["Core"],
				["name"] = "Aspect of the Eagle",
				["spellID"] = 186289,
			},
		},
		["EVOKER"] = {
			{
				["type"] = L["Other"],
				["name"] = "Fury of the Aspects",
				["spellID"] = 390386,
			},
			{
				["type"] = L["Other"],
				["name"] = "Emerald Blossom",
				["spellID"] = 355913,
			},
			{
				["type"] = L["Other"],
				["name"] = "Nullifying Shroud",
				["spellID"] = 378464,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Deep Breath",
				["spellID"] = 357210,
			},
			{
				["type"] = L["Other"],
				["name"] = "Terror of the Skies",
				["spellID"] = 371032,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Breath of Eons",
				["spellID"] = 403631,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Fire Breath",
				["spellID"] = 357208,
			},
			{
				["type"] = L["Other"],
				["name"] = "Hover",
				["spellID"] = 358267,
			},
			{
				["type"] = L["Other"],
				["name"] = "Sleep Walk",
				["spellID"] = 360806,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Dream Flight",
				["spellID"] = 359816,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Stasis",
				["spellID"] = 370537,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Rewind",
				["spellID"] = 363534,
			},
			{
				["type"] = L["External Defensive"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Time Dilation",
				["spellID"] = 357170,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Dream Breath",
				["spellID"] = 355936,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Eternity Surge",
				["spellID"] = 359073,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Dragonrage",
				["spellID"] = 375087,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Time Spiral",
				["spellID"] = 374968,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Renewing Blaze",
				["spellID"] = 374348,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Zephyr",
				["spellID"] = 374227,
			},
			{
				["type"] = L["Other"],
				["name"] = "Rescue",
				["spellID"] = 370665,
			},
			{
				["type"] = L["Other"],
				["name"] = "Quell",
				["role"] = { ["role:damager"] = true },
				["spellID"] = 351338,
			},
			{
				["type"] = L["Other"],
				["name"] = "Oppressing Roar",
				["spellID"] = 372048,
			},
			{
				["type"] = L["Other"],
				["name"] = "Cauterizing Flame",
				["spellID"] = 374251,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Obsidian Scales",
				["spellID"] = 363916,
			},
			{
				["type"] = L["Other"],
				["name"] = "Landslide",
				["spellID"] = 358385,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tip the Scales",
				["spellID"] = 370553,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Verdant Embrace",
				["spellID"] = 360995,
			},
			{
				["type"] = L["Other"],
				["name"] = "Expunge",
				["spellID"] = 365585,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Naturalize",
				["spellID"] = 360823,
			},
			{
				["type"] = L["Other"],
				["name"] = "Spatial Paradox",
				["spellID"] = 406732,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Time Skip",
				["spellID"] = 404977,
			},
			{
				["type"] = L["External Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Blistering Scales",
				["spellID"] = 360827,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Upheaval",
				["spellID"] = 396286,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Ebon Might",
				["spellID"] = 395152,
			},
		},
		["DRUID"] = {
			{
				["type"] = L["Other"],
				["name"] = "Dash",
				["spellID"] = 1850,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Thorns",
				["spellID"] = 305497,
			},
			{
				["type"] = L["Other"],
				["name"] = "Nature's Cure",
				["spellID"] = 88423,
			},
			{
				["type"] = L["Other"],
				["name"] = "Prowl",
				["spellID"] = 5215,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Barkskin",
				["spellID"] = 22812,
			},
			{
				["type"] = L["Other"],
				["name"] = "Growl",
				["spellID"] = 6795,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Nature's Swiftness",
				["spellID"] = 132158,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Tranquility",
				["spellID"] = 740,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Incarnation: Tree of Life",
				["spellID"] = 33891,
			},
			{
				["type"] = L["Core"],
				["name"] = "Convoke the Spirits",
				["spellID"] = 391528,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Flourish",
				["spellID"] = 197721,
			},
			{
				["type"] = L["External Defensive"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Ironbark",
				["spellID"] = 102342,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Berserk",
				["spellID"] = 106951,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Feral Frenzy",
				["spellID"] = 274837,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Incarnation: Avatar of Ashamane",
				["spellID"] = 102543,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Survival Instincts",
				["spellID"] = 61336,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Tiger's Fury",
				["spellID"] = 5217,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Incarnation: Guardian of Ursoc",
				["spellID"] = 102558,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Rage of the Sleeper",
				["spellID"] = 200851,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Pulverize",
				["spellID"] = 80313,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Bristling Fur",
				["spellID"] = 155835,
			},
			{
				["type"] = L["Other"],
				["name"] = "Wild Charge",
				["spellID"] = 102401,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tiger Dash",
				["spellID"] = 252216,
			},
			{
				["type"] = L["Other"],
				["name"] = "Remove Corruption",
				["spellID"] = 2782,
			},
			{
				["type"] = L["Other"],
				["name"] = "Typhoon",
				["spellID"] = 132469,
			},
			{
				["type"] = L["Other"],
				["name"] = "Frenzied Regeneration",
				["spellID"] = 22842,
			},
			{
				["type"] = L["Other"],
				["name"] = "Maim",
				["spellID"] = 22570,
			},
			{
				["type"] = L["Other"],
				["name"] = "Skull Bash",
				["role"] = { ["role:damager"] = true, ["role:tank"] = true },
				["spellID"] = 106839,
			},
			{
				["type"] = L["Other"],
				["name"] = "Soothe",
				["spellID"] = 2908,
			},
			{
				["type"] = L["Core"],
				["name"] = "Heart of the Wild",
				["spellID"] = 319454,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Stampeding Roar",
				["spellID"] = 77764,
			},
			{
				["type"] = L["Other"],
				["name"] = "Mighty Bash",
				["spellID"] = 5211,
			},
			{
				["type"] = L["Other"],
				["name"] = "Incapacitating Roar",
				["spellID"] = 99,
			},
			{
				["type"] = L["Other"],
				["name"] = "Mass Entanglement",
				["spellID"] = 102359,
			},
			{
				["type"] = L["Other"],
				["name"] = "Ursol's Vortex",
				["spellID"] = 102793,
			},
			{
				["type"] = L["Other"],
				["name"] = "Innervate",
				["spellID"] = 29166,
			},
			{
				["type"] = L["Other"],
				["name"] = "Force of Nature",
				["spellID"] = 205636,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Celestial Alignment",
				["spellID"] = 194223,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Wild Mushroom",
				["spellID"] = 88747,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Fury of Elune",
				["spellID"] = 202770,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "New Moon",
				["spellID"] = 274281,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Solar Beam",
				["spellID"] = 78675,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Lunar Beam",
				["spellID"] = 204066,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Berserk",
				["spellID"] = 50334,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Grove Guardians",
				["spellID"] = 102693,
			},
		},
		["WARLOCK"] = {
			{
				["type"] = L["Other"],
				["name"] = "Call Observer",
				["spellID"] = 201996,
			},
			{
				["type"] = L["Other"],
				["name"] = "Bane of Havoc",
				["spellID"] = 200546,
			},
			{
				["type"] = L["Other"],
				["name"] = "Felstorm",
				["spellID"] = 89751,
			},
			{
				["type"] = L["Other"],
				["name"] = "Command Demon",
				["spellID"] = 119898,
			},
			{
				["type"] = L["Other"],
				["name"] = "Demonic Circle: Teleport",
				["spellID"] = 48020,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Unending Resolve",
				["spellID"] = 104773,
			},
			{
				["type"] = L["Other"],
				["name"] = "Fel Domination",
				["spellID"] = 333889,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Dark Pact",
				["spellID"] = 108416,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shadowfury",
				["spellID"] = 30283,
			},
			{
				["type"] = L["Other"],
				["name"] = "Howl of Terror",
				["spellID"] = 5484,
			},
			{
				["type"] = L["Other"],
				["name"] = "Mortal Coil",
				["spellID"] = 6789,
			},
			{
				["type"] = L["Other"],
				["name"] = "Dimensional Rift",
				["spellID"] = 387976,
			},
			{
				["type"] = L["Other"],
				["name"] = "Cataclysm",
				["spellID"] = 152108,
			},
			{
				["type"] = L["Other"],
				["name"] = "Soul Fire",
				["spellID"] = 6353,
			},
			{
				["type"] = L["Core"],
				["name"] = "Havoc",
				["spellID"] = 80240,
			},
			{
				["type"] = L["Core"],
				["name"] = "Summon Infernal",
				["spellID"] = 1122,
			},
			{
				["type"] = L["Other"],
				["name"] = "Power Siphon",
				["spellID"] = 264130,
			},
			{
				["type"] = L["Other"],
				["name"] = "Summon Vilefiend",
				["spellID"] = 264119,
			},
			{
				["type"] = L["Other"],
				["name"] = "Call Dreadstalkers",
				["spellID"] = 104316,
			},
			{
				["type"] = L["Core"],
				["name"] = "Summon Demonic Tyrant",
				["spellID"] = 265187,
			},
			{
				["type"] = L["Core"],
				["name"] = "Summon Darkglare",
				["spellID"] = 205180,
			},
			{
				["type"] = L["Other"],
				["name"] = "Grimoire of Sacrifice",
				["spellID"] = 108503,
			},
			{
				["type"] = L["Other"],
				["name"] = "Channel Demonfire",
				["spellID"] = 196447,
			},
			{
				["type"] = L["Other"],
				["name"] = "Malevolence",
				["spellID"] = 442726,
			},
			{
				["type"] = L["Other"],
				["name"] = "Demonic Healthstone",
				["spellID"] = 452930,
			},
		},
		["PRIEST"] = {
			{
				["type"] = L["Other"],
				["name"] = "Mindgames",
				["spellID"] = 375901,
			},
			{
				["type"] = L["Other"],
				["name"] = "Purify",
				["spellID"] = 527,
			},
			{
				["type"] = L["Other"],
				["name"] = "Psychic Scream",
				["spellID"] = 8122,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Fade",
				["spellID"] = 586,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Desperate Prayer",
				["spellID"] = 19236,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Tentacle Slam",
				["spellID"] = 1227280,
			},
			{
				["type"] = L["Group Utility"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Power Word: Barrier",
				["spellID"] = 62618,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Evangelism",
				["spellID"] = 472433,
			},
			{
				["type"] = L["Core"],
				["name"] = "Mindbender",
				["spellID"] = 123040,
			},
			{
				["type"] = L["External Defensive"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Pain Suppression",
				["spellID"] = 33206,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Apotheosis",
				["spellID"] = 200183,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Divine Hymn",
				["spellID"] = 64843,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Holy Word: Sanctify",
				["spellID"] = 34861,
			},
			{
				["type"] = L["External Defensive"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Guardian Spirit",
				["spellID"] = 47788,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Holy Word: Serenity",
				["spellID"] = 2050,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Power Word: Radiance",
				["spellID"] = 194509,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Holy Word: Chastise",
				["spellID"] = 88625,
			},
			{
				["type"] = L["Other"],
				["name"] = "Silence",
				["spellID"] = 15487,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Void Torrent",
				["spellID"] = 263165,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Void Eruption",
				["spellID"] = 228260,
			},
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Dispersion",
				["spellID"] = 47585,
			},
			{
				["type"] = L["Core"],
				["name"] = "Halo",
				["spellID"] = 120517,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Vampiric Embrace",
				["spellID"] = 15286,
			},
			{
				["type"] = L["Core"],
				["name"] = "Power Infusion",
				["spellID"] = 10060,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Mass Dispel",
				["spellID"] = 32375,
			},
			{
				["type"] = L["Other"],
				["name"] = "Angelic Feather",
				["spellID"] = 121536,
			},
			{
				["type"] = L["Other"],
				["name"] = "Purify Disease",
				["spellID"] = 213634,
			},
			{
				["type"] = L["Other"],
				["name"] = "Void Tendrils",
				["spellID"] = 108920,
			},
			{
				["type"] = L["Other"],
				["name"] = "Dominate Mind",
				["spellID"] = 205364,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shadow Word: Death",
				["spellID"] = 32379,
			},
			{
				["type"] = L["Core"],
				["name"] = "Shadowfiend",
				["spellID"] = 34433,
			},
			{
				["type"] = L["Other"],
				["name"] = "Leap of Faith",
				["spellID"] = 73325,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Ultimate Penitence",
				["spellID"] = 421453,
			},
			{
				["type"] = L["Other"],
				["name"] = "Mind Blast",
				["spellID"] = 8092,
			},
			{
				["type"] = L["Core"],
				["name"] = "Voidwraith",
				["role"] = { ["role:healer"] = true },
				["spellID"] = 451234,
			},
		},
		["PALADIN"] = {
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Cleanse",
				["spellID"] = 4987,
			},
			{
				["type"] = L["Other"],
				["name"] = "Hammer of Justice",
				["spellID"] = 853,
			},
			{
				["type"] = L["Other"],
				["name"] = "Hand of Reckoning",
				["spellID"] = 62124,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Divine Shield",
				["spellID"] = 642,
			},
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:healer"] = true, ["role:damager"] = true },
				["name"] = "Divine Protection",
				["spellID"] = 498,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Ardent Defender",
				["spellID"] = 31850,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Gift of the Golden Val'kyr",
				["spellID"] = 378279,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Guardian of Ancient Kings",
				["spellID"] = 86659,
			},
			{
				["type"] = L["Core"],
				["name"] = "Divine Toll",
				["spellID"] = 375576,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:tank"] = true },
				["name"] = "Avenger's Shield",
				["spellID"] = 31935,
			},
			{
				["type"] = L["Other"],
				["name"] = "Cleanse Toxins",
				["spellID"] = 213644,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Wake of Ashes",
				["spellID"] = 255937,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Crusade",
				["spellID"] = 231895,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Execution Sentence",
				["spellID"] = 343527,
			},
			{
				["type"] = L["Personal Defensive"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Shield of Vengeance",
				["spellID"] = 184662,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Aura Mastery",
				["spellID"] = 31821,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Holy Prism",
				["spellID"] = 114165,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Avenging Crusader",
				["spellID"] = 216331,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Tyr's Deliverance",
				["spellID"] = 200652,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Blessing of Summer",
				["spellID"] = 388007,
			},
			{
				["type"] = L["External Defensive"],
				["name"] = "Lay on Hands",
				["spellID"] = 633,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blinding Light",
				["spellID"] = 115750,
			},
			{
				["type"] = L["Other"],
				["name"] = "Repentance",
				["spellID"] = 20066,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blessing of Freedom",
				["spellID"] = 1044,
			},
			{
				["type"] = L["Other"],
				["name"] = "Rebuke",
				["role"] = { ["role:damager"] = true, ["role:tank"] = true },
				["spellID"] = 96231,
			},
			{
				["type"] = L["Core"],
				["name"] = "Avenging Wrath",
				["spellID"] = 31884,
			},
			{
				["type"] = L["External Defensive"],
				["name"] = "Blessing of Sacrifice",
				["spellID"] = 6940,
			},
			{
				["type"] = L["External Defensive"],
				["name"] = "Blessing of Protection",
				["spellID"] = 1022,
			},
			{
				["type"] = L["Other"],
				["name"] = "Turn Evil",
				["spellID"] = 10326,
			},
			{
				["type"] = L["Other"],
				["name"] = "Divine Steed",
				["spellID"] = 190784,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Hand of Divinity",
				["spellID"] = 414273,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Divine Hammer",
				["spellID"] = 198034,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true, ["role:damager"] = true },
				["name"] = "Holy Bulwark",
				["spellID"] = 432472,
			},
		},
		["SHAMAN"] = {
			{
				["type"] = L["Other"],
				["name"] = "Earthbind Totem",
				["spellID"] = 2484,
			},
			{
				["type"] = L["Other"],
				["name"] = "Bloodlust",
				["spellID"] = 2825,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Purify Spirit",
				["spellID"] = 77130,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Feral Lunge",
				["spellID"] = 196884,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Doom Winds",
				["spellID"] = 384352,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Feral Spirit",
				["spellID"] = 51533,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Stormkeeper",
				["spellID"] = 191634,
			},
			{
				["type"] = L["Core"],
				["name"] = "Ascendance",
				["spellID"] = 114049,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Healing Tide Totem",
				["spellID"] = 108280,
			},
			{
				["type"] = L["Core"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Spirit Link Totem",
				["spellID"] = 98008,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:healer"] = true },
				["name"] = "Mana Tide Totem",
				["spellID"] = 16191,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Astral Shift",
				["spellID"] = 108271,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Earth Elemental",
				["spellID"] = 198103,
			},
			{
				["type"] = L["Other"],
				["name"] = "Spiritwalker's Grace",
				["spellID"] = 79206,
			},
			{
				["type"] = L["Other"],
				["name"] = "Wind Shear",
				["spellID"] = 57994,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tremor Totem",
				["spellID"] = 8143,
			},
			{
				["type"] = L["Other"],
				["name"] = "Capacitor Totem",
				["spellID"] = 192058,
			},
			{
				["type"] = L["Other"],
				["name"] = "Cleanse Spirit",
				["spellID"] = 51886,
			},
			{
				["type"] = L["Other"],
				["name"] = "Greater Purge",
				["spellID"] = 378773,
			},
			{
				["type"] = L["Other"],
				["name"] = "Hex",
				["spellID"] = 51514,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Nature's Guardian",
				["spellID"] = 30884,
			},
			{
				["type"] = L["Other"],
				["name"] = "Earthgrab Totem",
				["spellID"] = 51485,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Wind Rush Totem",
				["spellID"] = 192077,
			},
			{
				["type"] = L["Other"],
				["name"] = "Gust of Wind",
				["spellID"] = 192063,
			},
			{
				["type"] = L["Other"],
				["name"] = "Spirit Walk",
				["spellID"] = 58875,
			},
			{
				["type"] = L["Other"],
				["name"] = "Poison Cleansing Totem",
				["spellID"] = 383013,
			},
			{
				["type"] = L["Other"],
				["name"] = "Tranquil Air Totem",
				["spellID"] = 383019,
			},
			{
				["type"] = L["Other"],
				["name"] = "Thunderstorm",
				["spellID"] = 51490,
			},
			{
				["type"] = L["Other"],
				["name"] = "Healing Stream Totem",
				["spellID"] = 5394,
			},
			{
				["type"] = L["Other"],
				["role"] = { ["role:damager"] = true },
				["name"] = "Sundering",
				["spellID"] = 197214,
			},
			{
				["type"] = L["Other"],
				["name"] = "Nature's Swiftness",
				["spellID"] = 378081,
			},
			{
				["type"] = L["Other"],
				["name"] = "Ancestral Swiftness",
				["spellID"] = 443454,
			},
			{
				["type"] = L["Other"],
				["name"] = "Surging Totem",
				["spellID"] = 444995,
			},
		},
		["MAGE"] = {
			{
				["type"] = L["Other"],
				["name"] = "Time Warp",
				["spellID"] = 80353,
			},
			{
				["type"] = L["Other"],
				["name"] = "Counterspell",
				["spellID"] = 2139,
			},
			{
				["type"] = L["Other"],
				["name"] = "Frost Nova",
				["spellID"] = 122,
			},
			{
				["type"] = L["Other"],
				["name"] = "Blink",
				["spellID"] = 1953,
			},
			{
				["type"] = L["Other"],
				["name"] = "Invisibility",
				["spellID"] = 66,
			},
			{
				["type"] = L["Other"],
				["name"] = "Ring of Frost",
				["spellID"] = 113724,
			},
			{
				["type"] = L["Core"],
				["name"] = "Meteor",
				["spellID"] = 153561,
			},
			{
				["type"] = L["Other"],
				["name"] = "Dragon's Breath",
				["spellID"] = 31661,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Greater Invisibility",
				["spellID"] = 110959,
			},
			{
				["type"] = L["Other"],
				["name"] = "Shimmer",
				["spellID"] = 212653,
			},
			{
				["type"] = L["Other"],
				["name"] = "Ice Floes",
				["spellID"] = 108839,
			},
			{
				["type"] = L["Other"],
				["name"] = "Mass Polymorph",
				["spellID"] = 383121,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Alter Time",
				["spellID"] = 342245,
			},
			{
				["type"] = L["Other"],
				["name"] = "Remove Curse",
				["spellID"] = 475,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Ice Barrier",
				["spellID"] = 11426,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Blazing Barrier",
				["spellID"] = 235313,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Prismatic Barrier",
				["spellID"] = 235450,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Ice Block",
				["spellID"] = 45438,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Mirror Image",
				["spellID"] = 55342,
			},
			{
				["type"] = L["Other"],
				["name"] = "Ice Nova",
				["spellID"] = 157997,
			},
			{
				["type"] = L["Other"],
				["name"] = "Presence of Mind",
				["spellID"] = 205025,
			},
			{
				["type"] = L["Core"],
				["name"] = "Evocation",
				["spellID"] = 12051,
			},
			{
				["type"] = L["Core"],
				["name"] = "Ray of Frost",
				["spellID"] = 205021,
			},
			{
				["type"] = L["Other"],
				["name"] = "Summon Water Elemental",
				["spellID"] = 31687,
			},
			{
				["type"] = L["Core"],
				["name"] = "Frozen Orb",
				["spellID"] = 84714,
			},
			{
				["type"] = L["Other"],
				["name"] = "Flurry",
				["spellID"] = 44614,
			},
			{
				["type"] = L["Core"],
				["name"] = "Comet Storm",
				["spellID"] = 153595,
			},
			{
				["type"] = L["Core"],
				["name"] = "Combustion",
				["spellID"] = 190319,
			},
			{
				["type"] = L["Other"],
				["name"] = "Supernova",
				["spellID"] = 157980,
			},
			{
				["type"] = L["Core"],
				["name"] = "Arcane Surge",
				["spellID"] = 365350,
			},
			{
				["type"] = L["Core"],
				["name"] = "Touch of the Magi",
				["spellID"] = 321507,
			},
			{
				["type"] = L["Other"],
				["name"] = "Arcane Orb",
				["spellID"] = 153626,
			},
			{
				["type"] = L["Group Utility"],
				["name"] = "Mass Invisibility",
				["spellID"] = 414664,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Cauterize",
				["spellID"] = 86949,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Cold Snap",
				["spellID"] = 235219,
			},
			{
				["type"] = L["Personal Defensive"],
				["name"] = "Ice Cold",
				["spellID"] = 414658,
			},
			{
				["type"] = L["Other"],
				["name"] = "Cone of Cold",
				["spellID"] = 120,
			},
		},
	},
	other = {
		["RACIAL"] = {
			{
				["type"] = L["Racial"],
				["name"] = "Will to Survive",
				["race"] = 1,
				["spellID"] = 59752,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Blood Fury",
				["race"] = 2,
				["spellID"] = 20572,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Stoneform",
				["race"] = 3,
				["spellID"] = 20594,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Shadowmeld",
				["race"] = 4,
				["spellID"] = 58984,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Will of the Forsaken",
				["race"] = 5,
				["spellID"] = 7744,
			},
			{
				["type"] = L["Racial"],
				["name"] = "War Stomp",
				["race"] = 6,
				["spellID"] = 20549,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Escape Artist",
				["race"] = 7,
				["spellID"] = 20589,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Berserking",
				["race"] = 8,
				["spellID"] = 26297,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Rocket Jump",
				["race"] = 9,
				["spellID"] = 69070,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Arcane Torrent",
				["race"] = 10,
				["spellID"] = 129597,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Gift of the Naaru",
				["race"] = 11,
				["spellID"] = 59542,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Darkflight",
				["race"] = 22,
				["spellID"] = 68992,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Quaking Palm",
				["race"] = { 25, 26 },
				["spellID"] = 107079,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Arcane Pulse",
				["race"] = 27,
				["spellID"] = 260364,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Bull Rush",
				["race"] = 28,
				["spellID"] = 255654,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Spatial Rift",
				["race"] = 29,
				["spellID"] = 256948,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Light's Judgment",
				["race"] = 30,
				["spellID"] = 255647,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Regeneratin'",
				["race"] = 31,
				["spellID"] = 291944,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Haymaker",
				["race"] = 32,
				["spellID"] = 287712,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Fireblood",
				["race"] = 34,
				["spellID"] = 265221,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Bag of Tricks",
				["race"] = 35,
				["spellID"] = 312411,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Ancestral Call",
				["race"] = 36,
				["spellID"] = 274738,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Hyper Organic Light Originator",
				["race"] = 37,
				["spellID"] = 312924,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Emergency Failsafe",
				["race"] = 37,
				["spellID"] = 312916,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Tail Swipe",
				["race"] = { 52, 70 },
				["spellID"] = 368970,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Wing Buffet",
				["race"] = { 52, 70 },
				["spellID"] = 357214,
			},
			{
				["type"] = L["Racial"],
				["name"] = "Azerite Surge",
				["race"] = { 84, 85 },
				["spellID"] = 436344,
			},
		},
		["CONSUMABLE"] = {
			{
				["type"] = L["Consumable"],
				["name"] = "Tempered Potion",
				["spellID"] = 431932,
			},
			{
				["type"] = L["Consumable"],
				["name"] = "Invigorating Healing Potion",
				["spellID"] = 1238009,
			},
			{
				["type"] = L["Consumable"],
				["name"] = "Algari Mana Potion",
				["spellID"] = 431418,
			},
			{
				["type"] = L["Consumable"],
				["name"] = "Activate Weyrnstone",
				["spellID"] = 408234,
			},
			{
				["type"] = L["Consumable"],
				["name"] = "Healthstone",
				["spellID"] = 6262,
			},
			{
				["type"] = L["Consumable"],
				["name"] = "Demonic Gateway",
				["spellID"] = 113942,
			},
		},
	},
}

do
	---@type table<integer, boolean> Keeps track of which spells are already registered in the spellDB.
	local registeredSpells = {}

	for _, classSpells in pairs(Private.spellDB.classes) do
		for _, spell in pairs(classSpells) do
			registeredSpells[spell["spellID"]] = true
		end
	end
	for _, racialAndConsumableSpells in pairs(Private.spellDB.other) do
		for _, spell in pairs(racialAndConsumableSpells) do
			registeredSpells[spell["spellID"]] = true
		end
	end

	-- Returns true if spell is registered. A spell may registered by default or when a user adds a custom spell.
	---@param spellID integer
	---@return boolean
	function Private.spellDB.IsSpellRegistered(spellID)
		return registeredSpells[spellID] == true
	end

	-- Adds a spell to be considered "registered".
	---@param spellID integer
	function Private.spellDB.RegisterSpell(spellID)
		registeredSpells[spellID] = true
	end

	-- Remove a spell from being "registered".
	---@param spellID integer
	function Private.spellDB.UnregisterSpell(spellID)
		registeredSpells[spellID] = nil
	end
end

---@return table<integer, integer>
function Private.spellDB.GetSpellRemappings()
	return {
		[430703] = 468037, -- Black Arrow
		[246287] = 472433, -- Evangelism
		[200174] = 123040, -- Mindbender
	}
end
