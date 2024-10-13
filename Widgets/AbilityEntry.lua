local Type                = "EPAbilityEntry"
local Version             = 1
local AceGUI              = LibStub("AceGUI-3.0")
local LSM                 = LibStub("LibSharedMedia-3.0")
local frameWidth          = 200
local frameHeight         = 30
local padding             = { x = 2, y = 2 }
local zoomAmount          = 0.15
local iconSize            = frameHeight - 2 * padding.x
local listItemBackdrop    = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}
local AbilityEntryTooltip = CreateFrame("GameTooltip", "AbilityEntryTooltip", UIParent, "GameTooltipTemplate")

local function HandleIconEnter(frame)
	local self = frame.obj
	if self.spellID then
		AbilityEntryTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMLEFT", 0, frameHeight)
		AbilityEntryTooltip:SetSpellByID(self.spellID)
	end
end

local function HandleIconLeave(frame)
	local self = frame.obj
	if self.spellID then
		AbilityEntryTooltip:Hide()
	end
end

local function HandleCheckBoxEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function HandleCheckBoxLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function HandleCheckBoxMouseDown(frame)
	AceGUI:ClearFocus()
end

local function HandleCheckBoxMouseUp(frame)
	local self = frame.obj
	if not self.disabled then
		self:ToggleChecked()
		self:Fire("OnValueChanged", self.checked)
	end
end

local methods = {
	["OnAcquire"] = function(self)
		self:SetChecked(true)
		self:SetWidth(frameWidth)
	end,

	["OnWidthSet"] = function(self, width)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		self.checkbox:SetEnabled(self.disabled)
		if disabled then
			self.text:SetTextColor(0.5, 0.5, 0.5)
		else
			self.text:SetTextColor(1, 1, 1)
		end
	end,

	["SetChecked"] = function(self, value)
		local check = self.check
		self.checked = value
		if value then
			check:Show()
		else
			check:Hide()
		end
		self:SetDisabled(self.disabled)
	end,

	["GetChecked"] = function(self)
		return self.checked
	end,

	["ToggleChecked"] = function(self)
		self:SetChecked(not self:GetChecked())
	end,

	["SetAbility"] = function(self, spellID)
		local icon = self.icon
		local text = self.text
		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if spellInfo then
			self.spellID = spellID
			text:SetText(spellInfo.name)
			icon:SetTexture(spellInfo.iconID)
		end
	end,
}

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. num, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetBackdrop(listItemBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	frame:SetSize(frameWidth, frameHeight)

	local icon = frame:CreateTexture(Type .. "Icon" .. num, "ARTWORK")
	icon:SetPoint("TOPLEFT", frame, "TOPLEFT", padding.x, -padding.y)
	icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", padding.x, padding.y)
	icon:SetWidth(iconSize)
	icon:SetScript("OnEnter", HandleIconEnter)
	icon:SetScript("OnLeave", HandleIconLeave)

	local text = frame:CreateFontString(Type .. "Text" .. num, "OVERLAY", "GameFontNormal")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then text:SetFont(fPath, 12, "OUTLINE") end
	text:SetPoint("LEFT", icon, "RIGHT", 5, 0)

	local checkbox = CreateFrame("Button", Type .. "CheckBox" .. num, frame)
	checkbox:EnableMouse(true)
	checkbox:SetScript("OnEnter", HandleCheckBoxEnter)
	checkbox:SetScript("OnLeave", HandleCheckBoxLeave)
	checkbox:SetScript("OnMouseDown", HandleCheckBoxMouseDown)
	checkbox:SetScript("OnMouseUp", HandleCheckBoxMouseUp)
	checkbox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
	checkbox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	checkbox:SetWidth(iconSize)

	local checkbg = frame:CreateTexture(Type .. "CheckBoxBackground" .. num, "ARTWORK")
	checkbg:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-square-64]])
	checkbg:SetTexCoord(zoomAmount, 1 - zoomAmount, zoomAmount, 1 - zoomAmount)
	checkbg:SetAllPoints(checkbox)
	checkbg:SetVertexColor(0.25, 0.25, 0.25)

	local check = frame:CreateTexture(Type .. "CheckBoxCheck" .. num, "OVERLAY")
	check:SetAllPoints(checkbg)
	check:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64_1_]])

	local highlight = checkbox:CreateTexture(Type .. "CheckBoxHighlight" .. num, "HIGHLIGHT")
	highlight:SetColorTexture(0.25, 0.25, 0.5, 0.5)
	highlight:SetTexelSnappingBias(0.0)
	highlight:SetSnapToPixelGrid(false)
	highlight:SetPoint("TOPLEFT", 4, -4)
	highlight:SetPoint("BOTTOMRIGHT", -4, 4)
	highlight:SetSize(iconSize, iconSize)
	highlight:SetBlendMode("ADD")

	local widget = {
		checkbg   = checkbg,
		check     = check,
		checkbox  = checkbox,
		text      = text,
		highlight = highlight,
		frame     = frame,
		type      = Type,
		icon      = icon,
		spellID   = nil,
	}
	checkbox.obj = widget
	frame.obj = widget
	---@diagnostic disable-next-line: inject-field
	icon.obj = widget

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
