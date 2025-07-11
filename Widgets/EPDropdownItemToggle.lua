local _, Namespace = ...

---@class Private
local Private = Namespace

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local ipairs = ipairs
local pairs = pairs
local select = select
local tinsert = table.insert
local unpack = unpack
local pi = math.pi

local textOffsetX = 4
local checkOffsetX = 2
local childSelectedIndicatorOffsetX = 3
local childSelectedIndicatorOffsetY = 1
local checkSize = 16
local fontSize = 14
local dropdownItemHeight = 24
local subHeight = 18
local neutralButtonColor = Private.constants.colors.kNeutralButtonActionColor
local checkedVertexColor = { 226.0 / 255, 180.0 / 255, 36.0 / 255.0, 1.0 }
local disabledTextColor = { 0.5, 0.5, 0.5, 1 }
local enabledTextColor = { 1, 1, 1, 1 }
local rightArrow = " |TInterface\\AddOns\\EncounterPlanner\\Media\\icons8-right-arrow-32:16|t "

local function FixLevels(parent, ...)
	local i = 1
	local child = select(i, ...)
	while child do
		child:SetFrameLevel(parent:GetFrameLevel() + 1)
		FixLevels(child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

---@class EPItemBase : AceGUIWidget
---@field type string
---@field version integer
---@field counter integer
---@field frame Frame
---@field parentPullout EPDropdownPullout
---@field highlight Texture
---@field useHighlight boolean
---@field text FontString
---@field check Texture
---@field childSelectedIndicator Texture
---@field enabled boolean
---@field specialOnEnter function
---@field changedFont boolean|nil
---@field parentDropdownItemMenu EPDropdownItemMenu|nil
---@field parentDropdown EPDropdown|nil

local EPItemBase = {
	version = 1000,
	counter = 0,
}

---@param self EPItemBase
local function HandleItemBaseFrameEnter(self)
	if self.useHighlight then
		self.highlight:Show()
	end
	if self.specialOnEnter then
		self.specialOnEnter(self)
	end
end

---@param self EPItemBase
local function HandleItemBaseFrameLeave(self)
	if not self.customTextureFrame:IsShown() or not self.customTextureFrame:IsMouseOver() then
		self.highlight:Hide()
	end
end

---@param self EPItemBase
---@param color [integer]
function EPItemBase.SetTextColor(self, color)
	self.text:SetTextColor(unpack(color))
end

---@param self EPItemBase
---@param enabled boolean
function EPItemBase.SetEnabled(self, enabled)
	self.enabled = enabled
	if enabled then
		self.useHighlight = true
		self.text:SetTextColor(unpack(enabledTextColor))
	else
		self.useHighlight = false
		self.text:SetTextColor(unpack(disabledTextColor))
	end
end

---@param self EPItemBase
function EPItemBase.OnAcquire(self)
	self.checkOffsetX = textOffsetX
	self.textOffsetX = textOffsetX
	self.frame:SetToplevel(true)
	self.frame:SetFrameStrata("DIALOG")
	self.text:SetPoint("LEFT", self.frame, "LEFT", self.textOffsetX, 0)
	self.check:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX, 0)
end

---@param self EPItemBase
function EPItemBase.OnRelease(self)
	self:SetEnabled(true)
	self.parentPullout = nil
	self.parentDropdown = nil
	self.parentDropdownItemMenu = nil
	self.frame:SetParent(nil)
	self.frame:ClearAllPoints()
	self.frame:Hide()
	self.text:ClearAllPoints()
	self.check:ClearAllPoints()
	self.highlight:Hide()
	self.customTextureFrame:Hide()
	self.customTexture:SetTexture(nil)
	if self.changedFont then
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		local _, size, _ = self.text:GetFont()
		if fPath and size then
			self.text:SetFont(fPath, fontSize)
		end
	end
	self.changedFont = nil
end

---@param self EPItemBase
---@param pullout EPDropdownPullout
function EPItemBase.SetPullout(self, pullout)
	self.parentPullout = pullout
	self.frame:SetParent(nil)
	self.frame:SetParent(pullout.itemFrame)
	FixLevels(pullout.itemFrame, pullout.itemFrame:GetChildren())
end

---@param self EPItemBase
---@param text string
function EPItemBase.SetText(self, text)
	self.text:SetText(text or "")
end

---@param self EPItemBase
---@param padding number
function EPItemBase.SetHorizontalPadding(self, padding)
	self.textOffsetX = padding
	self.text:SetPoint("LEFT", self.frame, "LEFT", self.textOffsetX, 0)
end

---@param self EPItemBase
---@param size integer
function EPItemBase.SetFontSize(self, size)
	local font, _, flags = self.text:GetFont()
	if font then
		self.text:SetFont(font, size, flags)
	end
end

---@param self EPItemBase
---@return string
function EPItemBase.GetText(self)
	return self.text:GetText()
end

---@param self EPItemBase
---@param ... any
function EPItemBase.SetPoint(self, ...)
	self.frame:SetPoint(...)
end

---@param self EPItemBase
function EPItemBase.Show(self)
	self.frame:Show()
end

---@param self EPItemBase
function EPItemBase.Hide(self)
	self.frame:Hide()
end

---@param self EPItemBase
---@param texture string|integer
---@param vertexColor number[]
---@param customTextureClickable boolean
---@param neverChecked? boolean
function EPItemBase.SetCustomTexture(self, texture, vertexColor, customTextureClickable, neverChecked)
	if neverChecked then
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - checkSize, 0)
	else
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - checkSize * 2, 0)
	end
	self.check:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - checkSize, 0)
	self.customTexture:SetTexture(texture)
	self.customTexture:SetVertexColor(unpack(vertexColor))
	if customTextureClickable then
		self.customTextureFrame:RegisterForClicks("LeftButtonUp")
	else
		self.customTextureFrame:RegisterForClicks()
	end
	self.customTextureFrame:Show()
end

-- This is called by a Dropdown-Pullout. Do not call this method directly
function EPItemBase.SetOnEnter(self, func)
	self.specialOnEnter = func
end

function EPItemBase.Create(type)
	local count = AceGUI:GetNextWidgetNum(type)

	local frame = CreateFrame("Button", type .. count)
	frame:SetHeight(dropdownItemHeight)
	frame:SetFrameStrata("DIALOG")

	local text = frame:CreateFontString(type .. "Text" .. count, "OVERLAY", "GameFontNormalSmall")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("MIDDLE")
	text:SetPoint("LEFT", frame, "LEFT", textOffsetX, 0)
	text:SetWordWrap(false)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, fontSize)
	end

	local highlight = frame:CreateTexture(type .. "Highlight" .. count, "OVERLAY")
	highlight:SetColorTexture(unpack(neutralButtonColor))
	highlight:SetPoint("TOPLEFT", 1, 0)
	highlight:SetPoint("BOTTOMRIGHT", -1, 0)
	highlight:SetBlendMode("ADD")
	highlight:Hide()

	local check = frame:CreateTexture(type .. "Check" .. count, "OVERLAY")
	check:SetWidth(checkSize)
	check:SetHeight(checkSize)
	check:SetPoint("RIGHT", frame, "RIGHT", -checkOffsetX, 0)
	check:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	check:Hide()

	local customTextureFrame = CreateFrame("Button", type .. "CustomTextureFrame" .. count, frame)
	customTextureFrame:SetWidth(checkSize)
	customTextureFrame:SetHeight(checkSize)
	customTextureFrame:SetPoint("RIGHT", frame, "RIGHT", -checkOffsetX, 0)
	customTextureFrame:Hide()

	local customTexture = customTextureFrame:CreateTexture(type .. "CustomTexture" .. count, "OVERLAY")
	customTexture:SetAllPoints(customTextureFrame)

	local childSelectedIndicator = frame:CreateTexture(type .. "ChildSelectedIndicator" .. count, "OVERLAY")
	childSelectedIndicator:SetWidth(subHeight)
	childSelectedIndicator:SetHeight(subHeight)
	childSelectedIndicator:SetPoint(
		"RIGHT",
		frame,
		"RIGHT",
		-childSelectedIndicatorOffsetX,
		-childSelectedIndicatorOffsetY
	)
	childSelectedIndicator:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	childSelectedIndicator:SetRotation(pi / 2)
	childSelectedIndicator:Hide()

	---@class EPItemBase
	local widget = {
		frame = frame,
		type = type,
		useHighlight = true,
		check = check,
		childSelectedIndicator = childSelectedIndicator,
		highlight = highlight,
		text = text,
		customTexture = customTexture,
		customTextureFrame = customTextureFrame,
		enabled = true,
		OnAcquire = EPItemBase.OnAcquire,
		OnRelease = EPItemBase.OnRelease,
		SetPullout = EPItemBase.SetPullout,
		GetText = EPItemBase.GetText,
		SetText = EPItemBase.SetText,
		SetEnabled = EPItemBase.SetEnabled,
		SetPoint = EPItemBase.SetPoint,
		Show = EPItemBase.Show,
		Hide = EPItemBase.Hide,
		SetOnEnter = EPItemBase.SetOnEnter,
		SetFontSize = EPItemBase.SetFontSize,
		SetHorizontalPadding = EPItemBase.SetHorizontalPadding,
		SetCustomTexture = EPItemBase.SetCustomTexture,
		SetTextColor = EPItemBase.SetTextColor,
		textOffsetX = textOffsetX,
		checkOffsetX = checkOffsetX,
		childSelectedIndicatorOffsetX = childSelectedIndicatorOffsetX,
	}

	frame:SetScript("OnEnter", function()
		HandleItemBaseFrameEnter(widget)
	end)
	frame:SetScript("OnLeave", function()
		HandleItemBaseFrameLeave(widget)
	end)

	customTextureFrame:SetScript("OnClick", function()
		if widget.enabled then
			widget:Fire("Clicked")
		end
	end)
	customTextureFrame:SetScript("OnLeave", function()
		if not frame:IsMouseOver() then
			widget.highlight:Hide()
		end
	end)

	return widget
end

---@class EPDropdownItemToggle : EPItemBase
---@field selected boolean
---@field neverShowItemsAsSelected boolean
do
	local widgetType = "EPDropdownItemToggle"
	local widgetVersion = 1

	-- Updates the visibility of the check texture based on selected and neverShowItemsAsSelected
	---@param self EPDropdownItemToggle
	local function UpdateCheckVisibility(self)
		if self.selected and not self.neverShowItemsAsSelected then
			self.check:Show()
		else
			self.check:Hide()
		end
	end

	---@param self EPDropdownItemToggle
	local function HandleFrameClick(self)
		if not self.enabled then
			return
		end
		self.selected = not self.selected
		UpdateCheckVisibility(self)
		self:Fire("OnValueChanged", self.selected)
	end

	---@param self EPDropdownItemToggle
	---@param selected boolean
	local function SetIsSelected(self, selected)
		self.selected = selected
		UpdateCheckVisibility(self)
	end

	---@param self EPDropdownItemToggle
	---@param neverShow boolean
	local function SetNeverShowItemsAsSelected(self, neverShow)
		self.neverShowItemsAsSelected = neverShow
		if neverShow then
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)
		else
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - checkSize, 0)
		end
	end

	---@param self EPDropdownItemToggle
	local function OnAcquire(self)
		EPItemBase.OnAcquire(self)
		self:SetNeverShowItemsAsSelected(false)
		self:SetIsSelected(false)
	end

	---@param self EPDropdownItemToggle
	local function OnRelease(self)
		EPItemBase.OnRelease(self)
		self:SetNeverShowItemsAsSelected(false)
		self:SetIsSelected(false)
	end

	---@param self EPDropdownItemToggle
	local function GetIsSelected(self)
		return self.selected
	end

	---@param self EPDropdownItemToggle
	---@param value any
	local function SetValue(self, value)
		self:GetUserDataTable().value = value
	end

	---@param self EPDropdownItemToggle
	local function GetValue(self)
		return self:GetUserDataTable().value
	end

	local function Constructor()
		---@class EPDropdownItemToggle
		local widget = EPItemBase.Create(widgetType)
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.GetIsSelected = GetIsSelected
		widget.SetIsSelected = SetIsSelected
		widget.SetValue = SetValue
		widget.GetValue = GetValue
		widget.SetNeverShowItemsAsSelected = SetNeverShowItemsAsSelected

		widget.frame:SetScript("OnClick", function()
			HandleFrameClick(widget)
		end)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end

---@class EPDropdownItemMenu : EPItemBase
---@field childPullout EPDropdownPullout
---@field selected boolean
---@field neverShowItemsAsSelected boolean
---@field multiselect boolean|nil
---@field open boolean
---@field clickable boolean|nil

do
	local widgetType = "EPDropdownItemMenu"
	local widgetVersion = 1

	---@param self EPDropdownItemMenu
	local function HandleFrameEnter(self)
		if self.specialOnEnter then
			self.specialOnEnter(self)
		end
		if self.useHighlight then
			self.highlight:Show()
		else
			self.highlight:Hide()
		end
		if self.enabled and self.childPullout and #self.childPullout.items > 0 then
			self.childPullout:Open("TOPLEFT", self.frame, "TOPRIGHT", -1, 1, nil)
		end
	end

	---@param self EPDropdownItemMenu
	local function HandleFrameHide(self)
		if self.childPullout then
			self.childPullout:Close()
		end
	end

	---@param self EPDropdownItemMenu
	---@param childPullout EPDropdownPullout
	local function HandleChildPulloutOpen(self, childPullout)
		local value = self.parentDropdown.value
		if not self.multiselect then
			for _, pulloutItem in ipairs(childPullout.items) do
				pulloutItem:SetIsSelected(pulloutItem:GetValue() == value)
			end
		end
		self.open = true
	end

	---@param self EPDropdownItemMenu
	local function HandleChildPulloutClose(self)
		self.open = false
	end

	---@param self EPDropdownItemMenu
	---@param dropdownParent EPDropdown
	local function CreateChildPullout(self, dropdownParent)
		local autoWidth, height = dropdownParent.pullout.autoWidth, dropdownParent.dropdownItemHeight
		local childPullout = AceGUI:Create("EPDropdownPullout")
		childPullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		childPullout:SetCallback("OnOpen", function(widget)
			HandleChildPulloutOpen(self, widget)
		end)
		childPullout:SetCallback("OnClose", function()
			HandleChildPulloutClose(self)
		end)
		childPullout:SetItemHeight(height)
		childPullout:SetAutoWidth(autoWidth)
		childPullout:SetMaxVisibleItems(dropdownParent.maxItems)
		return childPullout
	end

	---@param self EPDropdownItemMenu
	---@param selected boolean
	---@param value any
	---@param textLevels table<string>
	local function HandleMenuItemValueChanged(self, selected, value, textLevels)
		self:SetChildValue(value)

		if not self.parentDropdownItemMenu and not self.neverShowItemsAsSelected then
			local parent = self.parentDropdown
			if parent and parent.showPathText then
				tinsert(textLevels, 1, self:GetText())
				local combinedLevelString = ""
				local levelsToInclude = parent.levelsToInclude
				if #levelsToInclude == 0 then
					for _, textLevel in ipairs(textLevels) do
						if combinedLevelString:len() == 0 then
							combinedLevelString = textLevel
						else
							combinedLevelString = combinedLevelString .. rightArrow .. textLevel
						end
					end
				else
					for _, levelToInclude in ipairs(levelsToInclude) do
						if levelToInclude == "n" then
							if combinedLevelString:len() == 0 then
								combinedLevelString = textLevels[#textLevels]
							else
								combinedLevelString = combinedLevelString .. rightArrow .. textLevels[#textLevels]
							end
						elseif textLevels[levelToInclude] then
							if combinedLevelString:len() == 0 then
								combinedLevelString = textLevels[levelToInclude]
							else
								combinedLevelString = combinedLevelString .. rightArrow .. textLevels[levelToInclude]
							end
						end
					end
				end
				self:Fire("OnValueChanged", selected, value, combinedLevelString)
			else
				self:Fire("OnValueChanged", selected, value)
			end
		elseif not self.neverShowItemsAsSelected then
			tinsert(textLevels, 1, self:GetText())
			self:Fire("OnValueChanged", selected, value, textLevels)
		else
			self:Fire("OnValueChanged", selected, value)
		end

		if self.open and not self.multiselect then
			self.parentPullout:Close()
		end
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItem EPDropdownItemToggle
	local function HandleItemValueChanged(self, dropdownItem)
		local childValue = dropdownItem:GetValue()
		local childSelected = dropdownItem.selected
		self:SetChildValue(childValue)

		if not self.parentDropdownItemMenu and not self.neverShowItemsAsSelected then
			local combinedLevelString = self:GetText() .. rightArrow .. dropdownItem:GetText()
			self:Fire("OnValueChanged", childSelected, childValue, combinedLevelString)
		elseif not self.neverShowItemsAsSelected then
			self:Fire("OnValueChanged", childSelected, childValue, { self:GetText(), dropdownItem:GetText() })
		else
			self:Fire("OnValueChanged", childSelected, childValue)
		end
		if self.neverShowItemsAsSelected == true then
			dropdownItem:SetIsSelected(false)
		else
			dropdownItem:SetIsSelected(childSelected)
		end

		if self.open and not self.multiselect then
			self.parentPullout:Close()
		end
	end

	---@param self EPDropdownItemMenu
	---@param dropdownParent EPDropdown
	---@param itemData DropdownItemData
	local function CreateDropdownItemMenu(self, dropdownParent, itemData)
		local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
		dropdownMenuItem:SetValue(itemData.itemValue)
		dropdownMenuItem:SetText(itemData.text)
		dropdownMenuItem:SetFontSize(dropdownParent.itemTextFontSize)
		dropdownMenuItem:SetHorizontalPadding(dropdownParent.itemHorizontalPadding)
		dropdownMenuItem:SetHeight(dropdownParent.dropdownItemHeight)
		dropdownMenuItem.parentDropdown = dropdownParent
		dropdownMenuItem.parentDropdownItemMenu = self
		dropdownMenuItem:GetUserDataTable().level = self:GetUserDataTable().level + 1
		dropdownMenuItem:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
		dropdownMenuItem:SetCallback("OnValueChanged", function(_, _, selected, value, textLevels)
			HandleMenuItemValueChanged(self, selected, value, textLevels)
		end)
		self.childPullout:AddItem(dropdownMenuItem)
		dropdownMenuItem:SetMenuItems(itemData.dropdownItemMenuData, dropdownParent)
	end

	---@param self EPDropdownItemMenu
	---@param dropdownParent EPDropdown
	---@param itemData DropdownItemData
	---@param insertIndex? integer
	local function CreateDropdownItemToggle(self, dropdownParent, itemData, insertIndex)
		local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
		dropdownItemToggle:SetValue(itemData.itemValue)
		dropdownItemToggle:SetText(itemData.text)
		dropdownItemToggle:SetFontSize(dropdownParent.itemTextFontSize)
		dropdownItemToggle:SetHorizontalPadding(dropdownParent.itemHorizontalPadding)
		dropdownItemToggle:SetHeight(dropdownParent.dropdownItemHeight)
		dropdownItemToggle.parentDropdown = dropdownParent
		dropdownItemToggle.parentDropdownItemMenu = self
		dropdownItemToggle:GetUserDataTable().level = self:GetUserDataTable().level + 1
		dropdownItemToggle:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
		if itemData.customTexture and itemData.customTextureVertexColor then
			dropdownItemToggle:SetCustomTexture(
				itemData.customTexture,
				itemData.customTextureVertexColor,
				itemData.customTextureSelectable,
				self.neverShowItemsAsSelected
			)
		end
		if itemData.customTextureSelectable then
			dropdownItemToggle:SetCallback("Clicked", function(widget)
				dropdownParent:Fire("CustomTextureClicked", widget, itemData.itemValue)
			end)
		end
		dropdownItemToggle:SetCallback("OnValueChanged", function(widget)
			HandleItemValueChanged(self, widget)
		end)
		if insertIndex then
			self.childPullout:InsertItem(dropdownItemToggle, insertIndex)
		else
			self.childPullout:AddItem(dropdownItemToggle)
		end
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	local function SetMenuItems(self, dropdownItemData, dropdownParent)
		self.childPullout = CreateChildPullout(self, dropdownParent)
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData and #itemData.dropdownItemMenuData > 0 then
				CreateDropdownItemMenu(self, dropdownParent, itemData)
			else
				CreateDropdownItemToggle(self, dropdownParent, itemData)
			end
		end
		FixLevels(self.childPullout.frame, self.childPullout.frame:GetChildren())
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	---@param index integer?
	local function AddMenuItems(self, dropdownItemData, dropdownParent, index)
		if not self.childPullout then
			self.childPullout = CreateChildPullout(self, dropdownParent)
		end
		local currentIndex = index
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData and #itemData.dropdownItemMenuData > 0 then
				CreateDropdownItemMenu(self, dropdownParent, itemData)
			else
				local alreadyExists = false
				for _, item in ipairs(self.childPullout.items) do
					if item:GetValue() == itemData.itemValue then
						alreadyExists = true
						break
					end
				end
				if not alreadyExists then
					CreateDropdownItemToggle(self, dropdownParent, itemData, currentIndex)
					if currentIndex then
						currentIndex = currentIndex + 1
					end
				end
			end
		end
		FixLevels(self.childPullout.frame, self.childPullout.frame:GetChildren())
	end

	---@param self EPDropdownItemMenu
	local function CloseMenu(self)
		self.childPullout:Close()
	end

	---@param self EPDropdownItemMenu
	local function SetIsSelectedBasedOnChildValue(self)
		local childValue = self:GetChildValue()
		local neverShowItemsAsSelected = self.neverShowItemsAsSelected
		if childValue ~= nil and not neverShowItemsAsSelected then
			self.childSelectedIndicator:SetVertexColor(unpack(checkedVertexColor)) -- indicate that a child item is selected
		else
			self.childSelectedIndicator:SetVertexColor(1, 1, 1, 1)
		end
	end

	--- Updates the selected indicator color based on if the parent and child values are equal.
	---@param self EPDropdownItemMenu
	---@param _ boolean
	local function SetIsSelected(self, _)
		local childValue = self:GetChildValue()
		local parentValue
		if self.parentDropdown then
			parentValue = self.parentDropdown:GetValue()
		end
		local neverShowItemsAsSelected = self.neverShowItemsAsSelected
		if childValue ~= nil and childValue == parentValue and not neverShowItemsAsSelected then
			self.childSelectedIndicator:SetVertexColor(unpack(checkedVertexColor)) -- indicate that a child item is selected
		else
			self.childSelectedIndicator:SetVertexColor(1, 1, 1, 1)
		end
	end

	---@param self EPDropdownItemMenu
	local function GetIsSelected(self)
		local childValue = self:GetChildValue()
		local parentValue
		if self.parentDropdown then
			parentValue = self.parentDropdown:GetValue()
		end
		local neverShowItemsAsSelected = self.neverShowItemsAsSelected
		if childValue ~= nil and childValue == parentValue and not neverShowItemsAsSelected then
			return true
		else
			return false
		end
	end

	---@param self EPDropdownItemMenu
	---@param value any
	local function SetValue(self, value)
		self:GetUserDataTable().value = value
	end

	---@param self EPDropdownItemMenu
	local function GetValue(self)
		return self:GetUserDataTable().value
	end

	---@param self EPDropdownItemMenu
	---@param value any
	local function SetChildValue(self, value)
		self:GetUserDataTable().childValue = value
	end

	---@param self EPDropdownItemMenu
	local function GetChildValue(self)
		return self:GetUserDataTable().childValue
	end

	---@param self EPDropdownItemMenu
	---@param multi any
	local function SetMultiselect(self, multi)
		self.multiselect = multi
	end

	---@param self EPDropdownItemMenu
	---@return unknown
	local function GetMultiselect(self)
		return self.multiselect
	end

	---@param self EPDropdownItemMenu
	---@param value any
	local function SetNeverShowItemsAsSelected(self, value)
		self.neverShowItemsAsSelected = value
	end

	---@param self EPDropdownItemMenu
	---@param clickable boolean
	local function SetClickable(self, clickable)
		self.clickable = clickable
		if clickable then
			self.frame:SetScript("OnClick", function()
				if self.enabled then
					self:Fire("OnValueChanged", nil, nil)
				end
			end)
		else
			self.frame:SetScript("OnClick", nil)
		end
	end

	---@param self EPDropdownItemMenu
	local function OnAcquire(self)
		EPItemBase.OnAcquire(self)
		self.open = false
		self.selected = false
		self.multiselect = false
		self.neverShowItemsAsSelected = false
	end

	---@param self EPDropdownItemMenu
	local function OnRelease(self)
		if self.childPullout then
			self.childPullout:Release()
		end
		self.childPullout = nil
		self:SetValue(nil)
		self:SetChildValue(nil)
		self:SetClickable(false)
		EPItemBase.OnRelease(self)
		self.open = false
		self.selected = false
		self.neverShowItemsAsSelected = false
	end

	---@param self EPDropdownItemMenu
	local function Clear(self)
		if self.childPullout then
			self.childPullout:Release()
		end
		self.childPullout = nil
		self:SetChildValue(nil)
		self.open = false
		self.selected = false
		self.neverShowItemsAsSelected = false
	end

	local function Constructor()
		---@class EPDropdownItemMenu
		local widget = EPItemBase.Create(widgetType)
		widget.childSelectedIndicator:Show()
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.SetIsSelectedBasedOnChildValue = SetIsSelectedBasedOnChildValue
		widget.SetIsSelected = SetIsSelected
		widget.GetIsSelected = GetIsSelected
		widget.SetValue = SetValue
		widget.GetValue = GetValue
		widget.SetMultiselect = SetMultiselect
		widget.GetMultiselect = GetMultiselect
		widget.SetChildValue = SetChildValue
		widget.GetChildValue = GetChildValue
		widget.SetMenuItems = SetMenuItems
		widget.AddMenuItems = AddMenuItems
		widget.CloseMenu = CloseMenu
		widget.Clear = Clear
		widget.SetNeverShowItemsAsSelected = SetNeverShowItemsAsSelected
		widget.SetClickable = SetClickable

		widget.frame:SetScript("OnEnter", function()
			HandleFrameEnter(widget)
		end)
		widget.frame:SetScript("OnHide", function()
			HandleFrameHide(widget)
		end)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end
