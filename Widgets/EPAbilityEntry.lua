local Type             = "EPAbilityEntry"
local Version          = 1
local AceGUI           = LibStub("AceGUI-3.0")
local frameWidth       = 200
local frameHeight      = 30
local padding          = { x = 2, y = 2 }
local zoomAmount       = 0.15
local listItemBackdrop = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}

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

---@param self EPAbilityEntry
local function OnAcquire(self)
	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame --[[@as Frame]])
	self.label.frame:SetPoint("LEFT")
	self.label:SetIconPadding(padding.x, padding.y)
	self.label:SetTextPadding(padding.x * 2, "none")
	self.label:SetHeight(frameHeight)
	self:SetDisabled(false)
	self:SetChecked(true)
end

---@param self EPAbilityEntry
local function OnRelease(self)
	self.label:Release()
	self.label = nil
end

---@param self EPAbilityEntry
---@param disabled boolean
local function SetDisabled(self, disabled)
	self.disabled = disabled
	self.label:SetDisabled(disabled)
end

---@param self EPAbilityEntry
---@param value boolean
local function SetChecked(self, value)
	local check = self.check
	self.checked = value
	if value then
		check:Show()
	else
		check:Hide()
	end
end

---@param self EPAbilityEntry
---@return boolean
local function GetChecked(self)
	return self.checked
end

---@param self EPAbilityEntry
local function ToggleChecked(self)
	self:SetChecked(not self:GetChecked())
end

---@param self EPAbilityEntry
---@param spellID number
local function SetAbility(self, spellID)
	local spellInfo = C_Spell.GetSpellInfo(spellID)
	if spellInfo then
		self.label:SetText(spellInfo.name)
		self.label:SetIcon(spellInfo.iconID, spellInfo.spellID)
	else
		self.label:SetIcon(nil)
	end
end

---@param self EPAbilityEntry
---@param str string
local function SetText(self, str)
	self.label:SetText(str)
	self.label:SetIcon(nil)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(listItemBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)

	local checkbox = CreateFrame("CheckButton", nil, frame)
	checkbox:SetPoint("RIGHT", frame, "RIGHT", -padding.x, 0)
	checkbox:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	checkbox:EnableMouse(true)
	checkbox:SetScript("OnMouseDown", HandleCheckBoxMouseDown)
	checkbox:SetScript("OnMouseUp", HandleCheckBoxMouseUp)

	local checkbg = checkbox:CreateTexture(Type .. "CheckBoxBackground" .. count, "ARTWORK")
	checkbg:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-square-64]])
	checkbg:SetTexCoord(zoomAmount, 1 - zoomAmount, zoomAmount, 1 - zoomAmount)
	checkbg:SetAllPoints(checkbox)
	checkbg:SetVertexColor(0.25, 0.25, 0.25)

	local check = checkbox:CreateTexture(Type .. "CheckBoxCheck" .. count, "ARTWORK")
	check:SetAllPoints(checkbox)
	check:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])

	local highlight = checkbox:CreateTexture(Type .. "CheckBoxHighlight" .. count, "HIGHLIGHT")
	highlight:SetColorTexture(0.25, 0.25, 0.5, 0.5)
	highlight:SetTexelSnappingBias(0.0)
	highlight:SetSnapToPixelGrid(false)
	highlight:SetAllPoints(checkbox)

	---@class EPAbilityEntry
	local widget = {
		OnAcquire     = OnAcquire,
		OnRelease     = OnRelease,
		SetDisabled   = SetDisabled,
		SetChecked    = SetChecked,
		GetChecked    = GetChecked,
		ToggleChecked = ToggleChecked,
		SetAbility    = SetAbility,
		SetText       = SetText,
		frame         = frame,
		type          = Type,
		count         = count,
		checkbg       = checkbg,
		check         = check,
		checkbox      = checkbox,
		highlight     = highlight,
	}

	checkbox.obj = widget
	frame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
