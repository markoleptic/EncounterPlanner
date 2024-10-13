local Type    = "EPDropdown"
local Version = 1
local AceGUI  = LibStub("AceGUI-3.0")
local LSM     = LibStub("LibSharedMedia-3.0")

local function CreateBorder(frame, colorTexture, thickness, extendo)
	for i = 1, 4 do
		local border = frame:CreateTexture(nil, "OVERLAY")
		border:SetColorTexture(unpack(colorTexture))
		border:SetTexelSnappingBias(0.0)
		border:SetSnapToPixelGrid(false)
		if i == 1 then -- top
			border:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
			border:SetPoint("TOPRIGHT", frame, "TOPRIGHT", extendo, 0)
		elseif i == 2 then -- bottom
			border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
			border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", extendo, 0)
		elseif i == 3 then --left
			border:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
			border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
		else --right
			border:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
			border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		end

		if i == 1 or i == 2 then
			border:SetHeight(thickness)
		else
			border:SetWidth(thickness)
		end
	end
end

local function createDropdown(parent)
	local dropdown = LibStub("AceGUI-3.0"):Create("Dropdown")
	local dropdownList = {}
	for _, instance in pairs(AddOn.Defaults.profile.instances["Nerub'ar Palace"].bosses) do
		EJ_SelectEncounter(instance.journalEncounterId)
		local _, _, _, _, iconImage, _ = EJ_GetCreatureInfo(1, instance.journalEncounterId)
		local iconText = string.format("|T%s:16|t %s", iconImage, instance.name)
		dropdownList[instance.name] = iconText
	end
	dropdown:SetList(dropdownList)
	dropdown:SetCallback("OnValueChanged", function(widget, event, key) end)
	local pullout = dropdown.frame.obj.pullout.frame
	pullout:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 1,
	})

	dropdown.frame.obj.pullout.scrollFrame:SetPoint("TOPLEFT", 0, 0)
	dropdown.frame.obj.pullout.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
	dropdown.frame.obj.pullout.itemFrame:SetPoint("TOPLEFT", dropdown.frame.obj.pullout.scrollFrame, "TOPLEFT")
	dropdown.frame.obj.pullout.itemFrame:SetPoint("BOTTOMRIGHT", dropdown.frame.obj.pullout.scrollFrame, "BOTTOMRIGHT")
	for _, item in pairs(dropdown.frame.obj.pullout.items) do
		if item then
			item:ClearAllPoints()
			item:SetPoint("LEFT", 0, 0)
			item:SetPoint("RIGHT", 0, 0)
			item.frame:ClearAllPoints()
			item.frame:SetPoint("LEFT", 0, 0)
			item.frame:SetPoint("RIGHT", 0, 0)
			item.frame:SetHeight(22)
			item:SetHeight(22)
			item.check:ClearAllPoints()
			item.check:SetPoint("RIGHT", 0, 0)
			item.text:ClearAllPoints()
			item.text:SetPoint("LEFT", 0, 0)
			item.highlight:SetHeight(22)
			local fPath = Private.Libs.LSM:Fetch("font", "PT Sans Narrow")
			if fPath then item.text:SetFont(fPath, 12, "OUTLINE") end
		end
	end

	pullout:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
	pullout:SetBackdropBorderColor(0, 0, 0, 1)

	dropdown.frame.obj.dropdown.Middle:Hide()
	dropdown.frame.obj.dropdown.Left:Hide()
	dropdown.frame.obj.dropdown.Right:Hide()
	dropdown.frame.obj.text:ClearAllPoints()
	dropdown.frame.obj.text:SetPoint("LEFT", 25, 0)

	local r, g, b, a = 0.8, 0.8, 0.8, 1 -- White border, fully opaque

	local frame = dropdown.frame


	local button = dropdown.frame.obj.button
	CreateBorder(frame, { r, g, b, a }, 1, button:GetWidth())
	button:ClearAllPoints()
	button:SetPoint("LEFT", frame, "RIGHT")

	button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
	button.NormalTexture:SetAllPoints()

	button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
	button.PushedTexture:SetAllPoints()

	button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
	button.HighlightTexture:SetAllPoints()

	button:SetDisabledTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
	button.DisabledTexture:SetAllPoints()
	dropdown:SetCallback("OnOpened",
		function()
			button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown-rotated]])
			button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown-rotated]])
			button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown-rotated]])
		end)
	dropdown:SetCallback("OnClosed",
		function()
			button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
			button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
			button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\dropdown]])
		end)

	-- 2nd Right border
	local right2 = frame:CreateTexture(nil, "OVERLAY")
	right2:SetColorTexture(r, g, b, a)
	right2:SetTexelSnappingBias(0.0)
	right2:SetSnapToPixelGrid(false)
	right2:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 1)
	right2:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 0, -1)
	right2:SetWidth(1) -- Adjust thickness

	return dropdown
end
