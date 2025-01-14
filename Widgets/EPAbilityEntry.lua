local _, Namespace = ...

---@class Constants
local constants = Namespace.constants

local Type = "EPAbilityEntry"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetSpellInfo = C_Spell.GetSpellInfo
local unpack = unpack
local pi = math.pi
local piOverTwo = pi / 2

local frameWidth = 200
local frameHeight = 30
local padding = { x = 2, y = 2 }
local backdropColor = { 0, 0, 0, 0.9 }
local checkBackdropColor = { 0, 0, 0, 0 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
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
local roleTextures = {
	["role:tank"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:0:19:22:41|t",
	["role:healer"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:20:39:1:20|t",
	["role:damager"] = "|T" .. "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES" .. ":16:16:0:0:64:64:20:39:22:41|t",
}

---@class EPAbilityEntry : AceGUIWidget
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field count number
---@field label EPLabel
---@field check EPButton
---@field checkBackground table|BackdropTemplate|Frame
---@field collapseButton Button|table
---@field enabled boolean
---@field key string|table|nil
---@field collapsed boolean

---@param self EPAbilityEntry
local function OnAcquire(self)
	self.frame:Show()

	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame --[[@as Frame]])
	self.label.frame:SetPoint("LEFT")
	self.label.frame:SetPoint("RIGHT", self.checkBackground, "LEFT", -padding.x, 0)
	self.label:SetHeight(frameHeight)

	self.roleTexture:SetPoint("RIGHT", self.label.frame, "LEFT", -padding.x, 0)

	local checkSpacing = checkBackdrop.edgeSize
	local checkSize = frameHeight - 2 * checkSpacing

	self.check = AceGUI:Create("EPButton")
	self.check:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	self.check.frame:SetParent(self.checkBackground --[[@as Frame]])
	self.check.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
	self.check.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
	self.check:SetWidth(checkSize)
	self.check:SetHeight(checkSize)
	self.check:SetBackdropColor(unpack(checkBackdropColor))
	self.check:SetCallback("Clicked", function()
		if self.enabled then
			self:Fire("OnValueChanged")
		end
	end)

	self:SetEnabled(true)
	self:SetCollapsible(false)
	self:SetCollapsed(false)
	self:SetRole(nil)
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
---@param enabled boolean
local function SetEnabled(self, enabled)
	self.enabled = enabled
	self.label:SetEnabled(enabled)
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
---@param key string|table|nil
local function SetGeneralAbility(self, key)
	self.label:SetText("General", padding.x * 2)
	self.label:SetIcon(constants.kTextAssignmentTexture, padding.x, padding.y, 0)
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
---@param role RaidGroupRole|nil
local function SetRole(self, role)
	local left = 0.0
	if role == "role:tank" or role == "role:healer" or role == "role:damager" then
		self.roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		self.roleTexture:Show()
		if self.collapseButton:IsShown() then
			left = self.collapseButton:GetWidth() + self.roleTexture:GetWidth() + 2 * padding.x
		else
			left = self.roleTexture:GetWidth() + padding.x
		end
		if role == "role:tank" then
			self.roleTexture:SetTexCoord(0, 19 / 64, 22 / 64, 41 / 64)
		elseif role == "role:healer" then
			self.roleTexture:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)
		elseif role == "role:damager" then
			self.roleTexture:SetTexCoord(20 / 64, 39 / 64, 22 / 64, 41 / 64)
		end
	else
		if self.collapseButton:IsShown() then
			left = self.collapseButton:GetWidth() + padding.x
		end
		self.roleTexture:Hide()
	end
	self.label.frame:SetPoint("LEFT", left, 0)
end

---@param self EPAbilityEntry
---@param collapsible boolean
local function SetCollapsible(self, collapsible)
	local left = 0.0
	if collapsible then
		self.collapseButton:Show()
		self.collapseButton:SetScript("OnClick", function()
			self:SetCollapsed(not self.collapsed)
			self:Fire("CollapseButtonToggled", self.collapsed)
		end)
		local collapseButtonWidth = self.collapseButton:GetWidth()
		if self.roleTexture:IsShown() then
			left = collapseButtonWidth + self.roleTexture:GetWidth() + 2 * padding.x
		else
			left = collapseButtonWidth + padding.x
		end
	else
		self.collapseButton:Hide()
		self.collapseButton:SetScript("OnClick", nil)
		if self.roleTexture:IsShown() then
			left = self.roleTexture:GetWidth() + padding.x
		end
	end
	self.label.frame:SetPoint("LEFT", left, 0)
end

---@param self EPAbilityEntry
---@param collapsed boolean
local function SetCollapsed(self, collapsed)
	self.collapsed = collapsed
	if collapsed then
		self.collapseButton:GetNormalTexture():SetRotation(piOverTwo)
		self.collapseButton:GetPushedTexture():SetRotation(piOverTwo)
		self.collapseButton:GetHighlightTexture():SetRotation(piOverTwo)
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
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)

	local button = CreateFrame("Button", Type .. "CollapseButton" .. count, frame)
	button:SetPoint("LEFT", frame, "LEFT", padding.x, 0)
	button:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	button:RegisterForClicks("LeftButtonUp")
	button:Hide()

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(checkBackdrop)
	checkBackground:SetBackdropColor(unpack(checkBackdropColor))
	checkBackground:SetBackdropBorderColor(unpack(backdropBorderColor))
	checkBackground:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	checkBackground:SetPoint("RIGHT", -padding.x, 0)

	local roleTexture = frame:CreateTexture(nil, "OVERLAY")
	roleTexture:SetSize(16, 16)
	roleTexture:Hide()

	---@class EPAbilityEntry
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetCheckedTexture = SetCheckedTexture,
		SetAbility = SetAbility,
		SetGeneralAbility = SetGeneralAbility,
		SetNullAbility = SetNullAbility,
		SetLeftIndent = SetLeftIndent,
		SetCollapsible = SetCollapsible,
		SetCollapsed = SetCollapsed,
		SetText = SetText,
		GetText = GetText,
		GetKey = GetKey,
		SetRole = SetRole,
		SetCheckedTextureColor = SetCheckedTextureColor,
		frame = frame,
		type = Type,
		count = count,
		checkBackground = checkBackground,
		collapseButton = button,
		roleTexture = roleTexture,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
