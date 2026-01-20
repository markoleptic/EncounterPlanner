local _, Namespace = ...

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

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 },
	BackdropColor = { 0, 0, 0, 0.9 },
	CheckBackdrop = {
		bgFile = nil,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = false,
		tileSize = nil,
		edgeSize = 1,
	},
	CheckBackdropColor = { 0, 0, 0, 0 },
	CheckTexture = Private.constants.textures.kCheck,
	DropdownTexture = Private.constants.textures.kDropdown,
	FrameHeight = 30,
	FrameWidth = 200,
	ListItemBackdrop = {
		bgFile = nil,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 1,
	},
	LfgPortraitRolesTexture = Private.constants.textures.kLfgPortraitRoles,
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	Padding = { x = 2, y = 2 },
	PiOverTwo = math.pi / 2,
	SwapTexture = Private.constants.textures.kSwap,
	TextAssignmentTexture = Private.constants.kTextAssignmentTexture,
	kUnknownTexture = Private.constants.textures.kUnknown,
}

---@param self EPAbilityEntry
local function OnAcquire(self)
	self.frame:Show()
	self.frame:SetSize(k.FrameWidth, k.FrameHeight)

	local buttonSize = k.FrameHeight - 2 * k.Padding.y

	self.collapseButton:SetPoint("LEFT", self.frame, "LEFT")
	self.collapseButton:SetSize(buttonSize, buttonSize)

	self.checkBackground:SetSize(buttonSize, buttonSize)
	self.checkBackground:SetPoint("RIGHT", -k.Padding.x, 0)
	self.checkBackground:Show()

	self.swapBackground:SetSize(buttonSize, buttonSize)
	self.swapBackground:SetPoint("RIGHT", self.checkBackground, "LEFT", -k.Padding.x / 2, 0)
	self.swapBackground:Hide()

	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame)
	self.label.frame:SetPoint("LEFT")
	self.label.frame:SetPoint("RIGHT", self.checkBackground, "LEFT")
	self.label:SetHorizontalTextAlignment("LEFT")
	self.label:SetHeight(k.FrameHeight)

	local checkSpacing = k.CheckBackdrop.edgeSize
	local checkSize = k.FrameHeight - 2 * checkSpacing

	self.check = AceGUI:Create("EPButton")
	self.check:SetIcon(k.CheckTexture)
	self.check.frame:SetParent(self.checkBackground)
	self.check.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
	self.check.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
	self.check:SetWidth(checkSize)
	self.check:SetHeight(checkSize)
	self.check:SetBackdropColor(unpack(k.CheckBackdropColor))
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
	self.role = nil

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
local function SetAbility(self, spellID, key)
	local spellName = GetSpellName(spellID)
	local iconID = GetSpellTexture(spellID)
	if spellName and iconID then
		self.label:SetText(spellName, k.Padding.x * 2)
		self.label:SetIcon(iconID, k.Padding.x, k.Padding.y, spellID)
	else
		self.label:SetText(L["Unknown"], k.Padding.x * 2)
		self.label:SetIcon(k.kUnknownTexture)
	end
	self.key = key
end

---@param self EPAbilityEntry
---@param key string|table|nil
local function SetGeneralAbility(self, key)
	self.label:SetText(L["Text"], k.Padding.x * 2)
	self.label:SetIcon(k.TextAssignmentTexture, k.Padding.x, k.Padding.y, 0)
	self.key = key
end

---@param self EPAbilityEntry
---@param spellID number
---@param text string
---@param iconID number
---@param key string|table|nil
local function SetBossAbility(self, spellID, text, iconID, key)
	if text and iconID then
		self.label:SetText(text, k.Padding.x * 2)
		self.label:SetIcon(iconID, k.Padding.x, k.Padding.y, spellID)
	else
		self.label:SetIcon(nil)
	end
	self.key = key
end

---@param self EPAbilityEntry
---@param key string|table|nil
---@param text string|nil
local function SetNullAbility(self, key, text)
	self.label:SetText(text or L["Unknown"], k.Padding.x * 2)
	self.label:SetIcon(k.kUnknownTexture, k.Padding.x, k.Padding.y, 0)
	self.key = key
end

---@param self EPAbilityEntry
---@param str string
---@param key string|table|nil
---@param horizontalTextPadding number|nil
local function SetText(self, str, key, horizontalTextPadding)
	self.label:SetText(str, horizontalTextPadding)
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
		self.label:SetHorizontalTextPadding(k.Padding.x * 2)
		local iconPadding = self.frame:GetHeight() * 0.25
		self.label:SetIcon(k.LfgPortraitRolesTexture, k.Padding.x, iconPadding)
		if role == "role:tank" then
			self.label.icon:SetTexCoord(0, 19 / 64, 22 / 64, 41 / 64)
		elseif role == "role:healer" then
			self.label.icon:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)
		elseif role == "role:damager" then
			self.label.icon:SetTexCoord(20 / 64, 39 / 64, 22 / 64, 41 / 64)
		end
		if self.collapseButton:IsShown() then
			self.label.frame:SetPoint("LEFT", self.collapseButton:GetWidth(), 0)
		else
			self.label.frame:SetPoint("LEFT")
		end
		self.role = role
	elseif type(role) == "number" then
		self.label:SetHorizontalTextPadding(k.Padding.x * 2)
		self.label:SetIcon(role, k.Padding.x, k.Padding.y)
		if self.collapseButton:IsShown() then
			self.label.frame:SetPoint("LEFT", self.collapseButton:GetWidth(), 0)
		else
			self.label.frame:SetPoint("LEFT")
		end
		self.role = role
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
		self.collapseButton:GetNormalTexture():SetRotation(k.PiOverTwo)
		self.collapseButton:GetPushedTexture():SetRotation(k.PiOverTwo)
		self.collapseButton:GetHighlightTexture():SetRotation(k.PiOverTwo)
	else
		self.collapseButton:GetNormalTexture():SetRotation(0)
		self.collapseButton:GetPushedTexture():SetRotation(0)
		self.collapseButton:GetHighlightTexture():SetRotation(0)
	end
end

---@param self EPAbilityEntry
---@param items DropdownItemData
local function SetAssigneeDropdownItems(self, items)
	self.dropdown:AddItems(items, "EPDropdownItemToggle")
	self.dropdown.frame:Show()
	self.dropdown:Open()
end

---@param self EPAbilityEntry
---@param show boolean
local function ShowSwapIcon(self, show)
	if show and not self.swap then
		self.swapBackground:Show()
		self.label.frame:SetPoint("RIGHT", self.swapBackground, "LEFT")

		local checkSpacing = k.CheckBackdrop.edgeSize
		local checkSize = self.frame:GetHeight() - 2 * checkSpacing

		self.swap = AceGUI:Create("EPButton")
		self.swap:SetIcon(k.SwapTexture)
		self.swap.frame:SetParent(self.swapBackground)
		self.swap.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
		self.swap.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
		self.swap:SetWidth(checkSize)
		self.swap:SetHeight(checkSize)
		self.swap:SetBackdropColor(unpack(k.CheckBackdropColor))
		self.swap:SetColor(unpack(k.NeutralButtonColor))
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
		self.dropdown.frame:SetParent(self.swap.frame)
		self.dropdown.frame:SetPoint("BOTTOMLEFT", self.swapBackground, "BOTTOMLEFT", 0, -1)
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

---@param self EPAbilityEntry
local function HideCheckBox(self)
	if self.check then
		self.check:Release()
	end
	self.check = nil
	self.checkBackground:ClearAllPoints()
	self.checkBackground:Hide()
	self.label.frame:SetPoint("RIGHT", self.frame, "RIGHT")
end

---@param self EPAbilityEntry
local function OnHeightSet(self)
	local height = self.frame:GetHeight()
	self.collapseButton:SetPoint("LEFT", self.frame, "LEFT", k.Padding.x, 0)
	self.collapseButton:SetSize(height - 2 * k.Padding.y, height - 2 * k.Padding.y)

	self.checkBackground:SetSize(height - 2 * k.Padding.y, height - 2 * k.Padding.y)
	self.checkBackground:SetPoint("RIGHT", -k.Padding.x, 0)

	self.swapBackground:SetSize(height - 2 * k.Padding.y, height - 2 * k.Padding.y)
	self.swapBackground:SetPoint("RIGHT", self.checkBackground, "LEFT", -k.Padding.x / 2, 0)

	local checkSpacing = k.CheckBackdrop.edgeSize
	local checkSize = height - 2 * checkSpacing

	if self.check then
		self.check.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
		self.check.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
		self.check:SetWidth(checkSize)
		self.check:SetHeight(checkSize)
	end

	if self.swap then
		self.swap.frame:SetPoint("TOPLEFT", checkSpacing, -checkSpacing)
		self.swap.frame:SetPoint("BOTTOMRIGHT", -checkSpacing, checkSpacing)
		self.swap:SetWidth(checkSize)
		self.swap:SetHeight(checkSize)
	end

	if self.collapseButton:IsShown() then
		self.label.frame:SetPoint("LEFT", self.collapseButton:GetWidth(), 0)
	end

	self.label:SetHeight(height)
	if self.role then
		if type(self.role) == "string" then
			local iconPadding = self.frame:GetHeight() * 0.25
			self.label:SetIconPadding(k.Padding.x, iconPadding)
		elseif type(self.role) == "number" then
			self.label:SetIconPadding(k.Padding.x, k.Padding.y)
		end
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(k.ListItemBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.FrameWidth, k.FrameHeight)
	frame:EnableMouse(true)

	local collapseButton = CreateFrame("Button", Type .. "CollapseButton" .. count, frame)
	collapseButton:SetPoint("LEFT", frame, "LEFT", k.Padding.x, 0)
	collapseButton:SetSize(k.FrameHeight - 2 * k.Padding.y, k.FrameHeight - 2 * k.Padding.y)
	collapseButton:SetNormalTexture(k.DropdownTexture)
	collapseButton:SetPushedTexture(k.DropdownTexture)
	collapseButton:SetHighlightTexture(k.DropdownTexture)
	collapseButton:RegisterForClicks("LeftButtonUp")
	collapseButton:Hide()

	local checkBackground = CreateFrame("Frame", Type .. "CheckBackground" .. count, frame, "BackdropTemplate")
	checkBackground:SetBackdrop(k.CheckBackdrop)
	checkBackground:SetBackdropColor(unpack(k.CheckBackdropColor))
	checkBackground:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	checkBackground:SetSize(k.FrameHeight - 2 * k.Padding.y, k.FrameHeight - 2 * k.Padding.y)
	checkBackground:SetPoint("RIGHT", -k.Padding.x, 0)

	local swapBackground = CreateFrame("Frame", Type .. "SwapBackground" .. count, frame, "BackdropTemplate")
	swapBackground:SetBackdrop(k.CheckBackdrop)
	swapBackground:SetBackdropColor(unpack(k.CheckBackdropColor))
	swapBackground:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	swapBackground:SetSize(k.FrameHeight - 2 * k.Padding.y, k.FrameHeight - 2 * k.Padding.y)
	swapBackground:SetPoint("RIGHT", checkBackground, "LEFT", -k.Padding.x / 2, 0)
	swapBackground:Hide()

	---@class EPAbilityEntry : AceGUIWidget
	---@field label EPLabel
	---@field check EPButton
	---@field swap EPButton|nil
	---@field dropdown EPDropdown
	---@field enabled boolean
	---@field key string|table|nil
	---@field collapsed boolean
	---@field role string|number|nil
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetCheckedTexture = SetCheckedTexture,
		SetAbility = SetAbility,
		SetGeneralAbility = SetGeneralAbility,
		SetBossAbility = SetBossAbility,
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
		OnHeightSet = OnHeightSet,
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
