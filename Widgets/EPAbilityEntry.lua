local Type = "EPAbilityEntry"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetSpellInfo = C_Spell.GetSpellInfo
local pi = math.pi

local frameWidth = 200
local frameHeight = 30
local padding = { x = 2, y = 2 }
local zoomAmount = 0.15
local listItemBackdrop = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}

local function HandleCheckBoxMouseUp(frame)
	local self = frame.obj
	if not self.disabled then
		self:ToggleChecked()
		self:Fire("OnValueChanged", self.checked)
	end
end

local function HandleCollapseButtonMouseUp(frame)
	local self = frame.obj
	self:SetCollapsed(not self.collapsed)
	self:Fire("CollapseButtonToggled", self.collapsed)
end

---@class EPAbilityEntry : AceGUIWidget
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field count number
---@field checkbg Texture
---@field check table|Frame
---@field checkbox table|Frame
---@field label EPLabel
---@field highlight Texture
---@field collapseButton Button|table
---@field disabled boolean
---@field checked boolean
---@field key string|table|nil
---@field collapsed boolean

---@param self EPAbilityEntry
local function OnAcquire(self)
	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame --[[@as Frame]])
	self.label.frame:SetPoint("LEFT")
	self.label.frame:SetPoint("RIGHT", self.checkbox, "LEFT", -padding.x, 0)
	self.label:SetHeight(frameHeight)
	self:SetCheckedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	self:SetDisabled(false)
	self:SetChecked(true)
	self:SetCollapsible(false)
	self:SetCollapsed(false)
	self.frame:Show()
end

---@param self EPAbilityEntry
local function OnRelease(self)
	self.label:Release()
	self.label = nil
	self.key = nil
end

---@param self EPAbilityEntry
---@param disabled boolean
local function SetDisabled(self, disabled)
	self.disabled = disabled
	self.label:SetDisabled(disabled)
end

---@param self EPAbilityEntry
---@param textureAsset? string|number
local function SetCheckedTexture(self, textureAsset)
	local check = self.check
	check:SetTexture(textureAsset)
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
---@param key string|table|nil
local function SetAbility(self, spellID, key)
	local spellInfo = GetSpellInfo(spellID)
	if spellInfo then
		self.label:SetText(spellInfo.name, padding.x * 2)
		self.label:SetIcon(spellInfo.iconID, padding.x, padding.y, spellInfo.spellID)
	else
		self.label:SetIcon(nil)
	end
	self.key = key
end

---@param self EPAbilityEntry
---@param key string|table|nil
local function SetNullAbility(self, key)
	self.label:SetText("Unknown", padding.x * 2)
	self.label:SetIcon("Interface\\Icons\\INV_MISC_QUESTIONMARK", padding.x, padding.y, 0)
	self.key = key
end

---@param self EPAbilityEntry
---@param str string
---@param key string|table|nil
local function SetText(self, str, key)
	self.label:SetText(str, padding.x * 2)
	self.label:SetIcon(nil)
	self.key = key
end

---@param self EPAbilityEntry
---@param indent number
local function SetLeftIndent(self, indent)
	self.label.frame:SetPoint("LEFT", indent, 0)
end

---@param self EPAbilityEntry
---@return string|table|nil
local function GetKey(self)
	return self.key
end

---@param self EPAbilityEntry
---@return string
local function GetText(self)
	return self.label:GetText()
end

---@param self EPAbilityEntry
---@param collapsible boolean
local function SetCollapsible(self, collapsible)
	if collapsible then
		self.label.frame:SetPoint("LEFT", padding.x + (frameHeight - 2 * padding.y), 0)
		self.collapseButton:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
		self.collapseButton:SetScript("OnClick", HandleCollapseButtonMouseUp)
		self.collapseButton:Show()
	else
		self.label.frame:SetPoint("LEFT")
		self.collapseButton:SetSize(0, frameHeight - 2 * padding.y)
		self.collapseButton:SetScript("OnClick", nil)
		self.collapseButton:Hide()
	end
end

---@param self EPAbilityEntry
---@param collapsed boolean
local function SetCollapsed(self, collapsed)
	self.collapsed = collapsed
	if collapsed then
		self.collapseButton:GetNormalTexture():SetRotation(pi / 2)
		self.collapseButton:GetPushedTexture():SetRotation(pi / 2)
		self.collapseButton:GetHighlightTexture():SetRotation(pi / 2)
	else
		self.collapseButton:GetNormalTexture():SetRotation(0)
		self.collapseButton:GetPushedTexture():SetRotation(0)
		self.collapseButton:GetHighlightTexture():SetRotation(0)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(listItemBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)

	local button = CreateFrame("Button", Type .. "CollapseButton" .. count, frame)
	button:SetPoint("LEFT", frame, "LEFT", padding.x, 0)
	button:SetSize(0, frameHeight - 2 * padding.y)
	button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	button:RegisterForClicks("LeftButtonUp")
	button:Hide()

	local checkbox = CreateFrame("CheckButton", Type .. "CheckBox" .. count, frame)
	checkbox:SetPoint("RIGHT", frame, "RIGHT", -padding.x, 0)
	checkbox:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	checkbox:EnableMouse(true)
	checkbox:RegisterForClicks("LeftButtonUp")
	checkbox:SetScript("OnClick", HandleCheckBoxMouseUp)

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
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetDisabled = SetDisabled,
		SetCheckedTexture = SetCheckedTexture,
		SetChecked = SetChecked,
		GetChecked = GetChecked,
		ToggleChecked = ToggleChecked,
		SetAbility = SetAbility,
		SetNullAbility = SetNullAbility,
		SetLeftIndent = SetLeftIndent,
		SetCollapsible = SetCollapsible,
		SetCollapsed = SetCollapsed,
		SetText = SetText,
		GetText = GetText,
		GetKey = GetKey,
		frame = frame,
		type = Type,
		count = count,
		checkbg = checkbg,
		check = check,
		checkbox = checkbox,
		highlight = highlight,
		collapseButton = button,
	}

	checkbox.obj = widget
	frame.obj = widget
	button.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
