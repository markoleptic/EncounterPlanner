local AddOnName, Namespace = ...

---@class Private
local Private = Namespace

local L = Namespace.L
local Type = "EPAbilityEntry"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture
local unpack = unpack
local pi = math.pi
local piOverTwo = pi / 2

local frameWidth = 200
local frameHeight = 30
local padding = { x = 2, y = 2 }
local backdropColor = { 0, 0, 0, 0.9 }
local checkBackdropColor = { 0, 0, 0, 0 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local textAssignmentTexture = Private.constants.kTextAssignmentTexture
local neutralButtonColor = Private.constants.colors.kNeutralButtonActionColor
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

---@class EPAbilityEntry : AceGUIWidget
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field count number
---@field label EPLabel
---@field check EPButton
---@field swap EPButton|nil
---@field dropdown EPDropdown
---@field checkBackground table|BackdropTemplate|Frame
---@field collapseButton Button|table
---@field enabled boolean
---@field key string|table|nil
---@field collapsed boolean

---@param self EPAbilityEntry
local function OnAcquire(self)
	self.frame:Show()
	self.frame:SetSize(frameWidth, frameHeight)

	local buttonSize = frameHeight - 2 * padding.y

	self.collapseButton:SetPoint("LEFT", self.frame, "LEFT")
	self.collapseButton:SetSize(buttonSize, buttonSize)

	self.checkBackground:SetSize(buttonSize, buttonSize)
	self.checkBackground:SetPoint("RIGHT", -padding.x, 0)
	self.checkBackground:Show()

	self.swapBackground:SetSize(buttonSize, buttonSize)
	self.swapBackground:SetPoint("RIGHT", self.checkBackground, "LEFT", -padding.x / 2, 0)
	self.swapBackground:Hide()

	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame --[[@as Frame]])
	self.label.frame:SetPoint("LEFT")
	self.label.frame:SetPoint("RIGHT", self.checkBackground, "LEFT")
	self.label:SetHorizontalTextAlignment("LEFT")
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
	self.check:SetBackdropColor(unpack(checkBackdropColor))
	self.check:SetCallback("Clicked", function()
		if self.enabled then
			self:Fire("OnValueChanged")
		end
	end)

	self:SetEnabled(true)
	self:SetCollapsible(false)
	self:SetCollapsed(false)
	self:SetRoleOrSpec(nil)
end

---@param self EPAbilityEntry
local function OnRelease(self)
	self.label.icon:SetTexCoord(0, 1, 0, 1)
	self.label:Release()
	self.label = nil

	if self.check then
		self.check:Release()
	end
	self.check = nil

	if self.swap then
		self.swap:Release()
	end
	self.swap = nil

	if self.dropdown then
		self.dropdown:Release()
	end
	self.dropdown = nil

	self.key = nil

	self.frame:ClearAllPoints()
	self.frame:Hide()
	self.collapseButton:ClearAllPoints()
	self.collapseButton:Hide()
	self.checkBackground:ClearAllPoints()
	self.checkBackground:Hide()
	self.swapBackground:ClearAllPoints()
	self.swapBackground:Hide()
end

---@param self EPAbilityEntry
---@param enabled boolean
local function SetEnabled(self, enabled)
	self.enabled = enabled
	self.label:SetEnabled(enabled)
	if self.check then
		self.check:SetEnabled(enabled)
	end
	if self.swap then
		self.swap:SetEnabled(enabled)
	end
	if self.dropdown then
		self.dropdown:SetEnabled(enabled)
	end
end

---@param self EPAbilityEntry
---@param textureAsset? string|number
local function SetCheckedTexture(self, textureAsset)
	if self.check then
		self.check:SetIcon(textureAsset)
	end
end

---@param self EPAbilityEntry
---@param r number
---@param g number
---@param b number
---@param a number
local function SetCheckedTextureColor(self, r, g, b, a)
	if self.check then
		self.check:SetIconColor(r, g, b, a)
	end
end

---@param self EPAbilityEntry
---@param spellID number
---@param key string|table|nil
---@param textToAppend string|nil
local function SetAbility(self, spellID, key, textToAppend)
	local spellName = GetSpellName(spellID)
	local iconID = GetSpellTexture(spellID)
	if spellName and iconID then
		if textToAppend then
			self.label:SetText(spellName .. " " .. textToAppend, padding.x * 2)
		else
			self.label:SetText(spellName, padding.x * 2)
		end
		self.label:SetIcon(iconID, padding.x, padding.y, spellID)
	else
		self.label:SetIcon(nil)
	end
	self.key = key
end

---@param self EPAbilityEntry
---@param key string|table|nil
---@param text string|nil
local function SetNullAbility(self, key, text)
	self.label:SetText(text or L["Unknown"], padding.x * 2)
	self.label:SetIcon("Interface\\Icons\\INV_MISC_QUESTIONMARK", padding.x, padding.y, 0)
	self.key = key
end

---@param self EPAbilityEntry
---@param key string|table|nil
local function SetGeneralAbility(self, key)
	self.label:SetText(L["Text"], padding.x * 2)
	self.label:SetIcon(textAssignmentTexture, padding.x, padding.y, 0)
	self.key = key
end

---@param self EPAbilityEntry
---@param str string
---@param key string|table|nil
local function SetText(self, str, key)
	self.label:SetText(str, 0)
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
---@param role RaidGroupRole|integer|nil
local function SetRoleOrSpec(self, role)
	if role == "role:tank" or role == "role:healer" or role == "role:damager" then
		self.label:SetHorizontalTextPadding(padding.x, 0)
		self.label:SetIcon("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", 0, 7, nil, nil, 7)
		if role == "role:tank" then
			self.label.icon:SetTexCoord(0, 19 / 64, 22 / 64, 41 / 64)
		elseif role == "role:healer" then
			self.label.icon:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)
		elseif role == "role:damager" then
			self.label.icon:SetTexCoord(20 / 64, 39 / 64, 22 / 64, 41 / 64)
		end
		if self.collapseButton:IsShown() then
			self.label.frame:SetPoint("LEFT", self.collapseButton:GetWidth())
		else
			self.label.frame:SetPoint("LEFT")
		end
	elseif type(role) == "number" then
		self.label:SetHorizontalTextPadding(padding.x, 0)
		self.label:SetIcon(role, 0, 7, nil, nil, 7)
	end
end

---@param self EPAbilityEntry
---@param collapsible boolean
local function SetCollapsible(self, collapsible)
	if collapsible then
		self.collapseButton:Show()
		self.collapseButton:SetScript("OnClick", function()
			self:SetCollapsed(not self.collapsed)
			self:Fire("CollapseButtonToggled", self.collapsed)
		end)
		self.label.frame:SetPoint("LEFT", self.collapseButton:GetWidth(), 0)
	else
		self.collapseButton:Hide()
		self.collapseButton:SetScript("OnClick", nil)
		self.label.frame:SetPoint("LEFT")
	end
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

---@param self EPAbilityEntry
---@param items DropdownItemData
local function SetAssigneeDropdownItems(self, items)
	self.dropdown:AddItems(items, "EPDropdownItemToggle", true)
	self.dropdown.frame:Show()
	self.dropdown:Open()
end

---@param self EPAbilityEntry
---@param show boolean
local function ShowSwapIcon(self, show)
	if show and not self.swap then
		self.swapBackground:Show()
		self.label.frame:SetPoint("RIGHT", self.swapBackground, "LEFT")

		local checkSpacing = checkBackdrop.edgeSize
		local checkSize = frameHeight - 2 * checkSpacing

		self.swap = AceGUI:Create("EPButton")
		self.swap:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-swap-32]])
		self.swap.frame:SetParent(self.swapBackground --[[@as Frame]])
		self.swap.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
		self.swap.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
		self.swap:SetWidth(checkSize)
		self.swap:SetHeight(checkSize)
		self.swap:SetBackdropColor(unpack(checkBackdropColor))
		self.swap:SetColor(unpack(neutralButtonColor))
		self.swap:SetCallback("Clicked", function()
			if self.enabled then
				if self.dropdown.frame:IsShown() then
					self.dropdown:Close()
					self.dropdown:Clear()
				else
					self:Fire("SwapButtonClicked")
				end
			end
		end)

		self.dropdown = AceGUI:Create("EPDropdown")
		self.dropdown.frame:SetParent(self.swap.frame --[[@as Frame]])
		self.dropdown.frame:SetPoint("BOTTOMLEFT", self.swapBackground --[[@as Frame]], "BOTTOMLEFT", 0, -1)
		self.dropdown.frame:SetWidth(1)
		self.dropdown.frame:ClearBackdrop()
		self.dropdown.text:Hide()
		self.dropdown.buttonCover:Hide()
		self.dropdown.button:Hide()
		self.dropdown.text:Hide()
		self.dropdown.frame:Hide()
		self.dropdown:SetMaxVisibleItems(8)
		self.dropdown:SetCallback("OnClosed", function()
			self.dropdown.frame:Hide()
		end)
		self.dropdown:SetCallback("OnValueChanged", function(_, _, value)
			self:Fire("AssigneeSwapped", value)
		end)
	else
		self.label.frame:SetPoint("RIGHT", self.checkBackground, "LEFT")
		self.swapBackground:Hide()
		if self.swap then
			self.swap:Release()
			self.swap = nil
		end
	end
end

local function HideCheckBox(self)
	if self.check then
		self.check:Release()
	end
	self.check = nil
	self.checkBackground:ClearAllPoints()
	self.checkBackground:Hide()
	self.label.frame:SetPoint("RIGHT", self.frame, "RIGHT")
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(listItemBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)

	local collapseButton = CreateFrame("Button", Type .. "CollapseButton" .. count, frame)
	collapseButton:SetPoint("LEFT", frame, "LEFT", padding.x, 0)
	collapseButton:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	collapseButton:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	collapseButton:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	collapseButton:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	collapseButton:RegisterForClicks("LeftButtonUp")
	collapseButton:Hide()

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(checkBackdrop)
	checkBackground:SetBackdropColor(unpack(checkBackdropColor))
	checkBackground:SetBackdropBorderColor(unpack(backdropBorderColor))
	checkBackground:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	checkBackground:SetPoint("RIGHT", -padding.x, 0)

	local swapBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	swapBackground:SetBackdrop(checkBackdrop)
	swapBackground:SetBackdropColor(unpack(checkBackdropColor))
	swapBackground:SetBackdropBorderColor(unpack(backdropBorderColor))
	swapBackground:SetSize(frameHeight - 2 * padding.y, frameHeight - 2 * padding.y)
	swapBackground:SetPoint("RIGHT", checkBackground, "LEFT", -padding.x / 2, 0)
	swapBackground:Hide()

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
		SetRoleOrSpec = SetRoleOrSpec,
		SetCheckedTextureColor = SetCheckedTextureColor,
		ShowSwapIcon = ShowSwapIcon,
		SetAssigneeDropdownItems = SetAssigneeDropdownItems,
		HideCheckBox = HideCheckBox,
		frame = frame,
		type = Type,
		count = count,
		checkBackground = checkBackground,
		swapBackground = swapBackground,
		collapseButton = collapseButton,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
