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
local listItemBackdrop = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}

local checkBackdrop = {
	bgFile = nil,
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	tileSize = nil,
	edgeSize = 1,
}

local function HandleCollapseButtonMouseUp(frame)
	local self = frame.obj
	self:SetCollapsed(not self.collapsed)
	self:Fire("CollapseButtonToggled", self.collapsed)
end

---@class EPAbilityEntry : AceGUIWidget
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field count number
---@field label EPLabel
---@field check EPButton
---@field checkBackground table|BackdropTemplate|Frame
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
	self.label.frame:SetPoint("RIGHT", self.checkBackground, "LEFT", -padding.x, 0)
	self.label:SetHeight(frameHeight)

	local checkSpacing = checkBackdrop.edgeSize
	local checkSize = frameHeight - 2 * checkSpacing

	self.check = AceGUI:Create("EPButton")
	self.check:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	self.check.frame:SetParent(self.checkBackground --[[@as Frame]])
	self.check.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
	self.check.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
	self.check:SetWidth(checkSize)
	self.check:SetHeight(checkSize)
	self.check:SetBackdropColor(0, 0, 0, 0)
	self.check:SetCallback("Clicked", function()
		if not self.disabled then
			self:ToggleChecked()
			self:Fire("OnValueChanged", self.checked)
		end
	end)

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
	self.check:Release()
	self.check = nil
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
	self.check:SetIcon(textureAsset)
end

---@param self EPAbilityEntry
---@param r number
---@param g number
---@param b number
---@param a number
local function SetCheckedTextureColor(self, r, g, b, a)
	self.check:SetIconColor(r, g, b, a)
end

---@param self EPAbilityEntry
---@param value boolean
local function SetChecked(self, value)
	self.checked = value
	if value then
		self.check.frame:Show()
	else
		self.check.frame:Hide()
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

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(checkBackdrop)
	checkBackground:SetBackdropColor(0, 0, 0, 0)
	checkBackground:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	checkBackground:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	checkBackground:SetPoint("RIGHT", -padding.x, 0)

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
		SetCheckedTextureColor = SetCheckedTextureColor,
		frame = frame,
		type = Type,
		count = count,
		checkBackground = checkBackground,
		collapseButton = button,
	}

	frame.obj = widget
	button.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
