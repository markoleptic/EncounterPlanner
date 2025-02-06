local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

-- Public facing API.
---@class EncounterPlannerAPI
local EncounterPlannerAPI = {}

---@param dungeonEncounterID integer Dungeon encounter ID of the boss encounter.
function EncounterPlannerAPI.GetTextForEncounter(dungeonEncounterID)
	local profile = Private.addOn.db.profile ---@type DefaultProfile
	if profile then
		for _, plan in pairs(profile.plans) do
			if plan.dungeonEncounterID == dungeonEncounterID then
				return plan.content
			end
		end
	end
end

_G["EncounterPlannerAPI"] = EncounterPlannerAPI
