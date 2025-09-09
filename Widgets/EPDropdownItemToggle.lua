local _, Namespace = ...

---@class Private
local Private = Namespace

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local ipairs = ipairs
local pairs = pairs
local select = select
local unpack = unpack

local k = {
	CheckedVertexColor = { 226.0 / 255, 180.0 / 255, 36.0 / 255.0, 1.0 },
	CheckOffsetX = 2,
	CheckSize = 16,
	CheckTexture = Private.constants.textures.kCheck,
	DisabledTextColor = { 0.5, 0.5, 0.5, 1 },
	DisabledVertexColor = { 0.5, 0.5, 0.5, 1 },
	DropdownItemHeight = 24,
	DropdownTexture = Private.constants.textures.kDropdown,
	EnabledTextColor = { 1, 1, 1, 1 },
	FontSize = 14,
	MenuIndicatorOffsetX = 3,
	MenuIndicatorOffsetY = 1,
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	Pi = math.pi,
	SubHeight = 18,
	TextOffsetX = 4,
	UncheckedVertexColor = { 1, 1, 1, 1 },
}

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
---@field count integer
---@field enabled boolean
---@field frame Frame
---@field customTexture Texture Optional custom texture owned by customTextureFrame
---@field customTextureFrame Button Allows for the custom texture to be clicked, causing the OnClick signal to be fired.
---@field specialOnEnter function Executed when frame is entered.
---@field parentPullout EPDropdownPullout Reference to the owning dropdown pullout of this item.
---@field highlight Texture Texture that is shown when the mouse is hovering over an item.
---@field useHighlight boolean Whether to show the highlight when the mouse is hovering over an item.
---@field text FontString Main text of the item.
---@field check Texture Shown if an item is selected and neverShowItemsAsSelected is false/nil.
---@field changedFont? boolean If true, the font was changed and needs to be changed back to default on release.
---@field parentDropdownItemMenu? EPDropdownItemMenu Reference to the owning item menu of the parentPullout.
---@field parentDropdown? EPDropdown Reference to the top-level dropdown parent.
-- If true, the child selected indicator will never be visible and child pullout items will never be set to selected
-- (never show check mark).
---@field neverShowItemsAsSelected boolean

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
		self.text:SetTextColor(unpack(k.EnabledTextColor))
	else
		self.useHighlight = false
		self.text:SetTextColor(unpack(k.DisabledTextColor))
	end
end

---@param self EPItemBase
function EPItemBase.OnAcquire(self)
	self.checkOffsetX = k.TextOffsetX
	self.textOffsetX = k.TextOffsetX
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
	self.customTextureFrame:RegisterForClicks()
	self.customTexture:SetTexture(nil)
	if self.changedFont then
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		local _, size, _ = self.text:GetFont()
		if fPath and size then
			self.text:SetFont(fPath, k.FontSize)
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
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - k.CheckSize, 0)
	else
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - k.CheckSize * 2, 0)
	end
	self.check:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - k.CheckSize, 0)
	self.customTexture:SetTexture(texture)
	self.customTexture:SetVertexColor(unpack(vertexColor))
	if customTextureClickable then
		self.customTextureFrame:RegisterForClicks("LeftButtonUp")
	else
		self.customTextureFrame:RegisterForClicks()
	end
	self.customTextureFrame:Show()
end

-- This is called by an EPDropdownPullout.
function EPItemBase.SetOnEnter(self, func)
	self.specialOnEnter = func
end

function EPItemBase.Create(type)
	local count = AceGUI:GetNextWidgetNum(type)

	local frame = CreateFrame("Button", type .. count)
	frame:SetHeight(k.DropdownItemHeight)
	frame:SetFrameStrata("DIALOG")

	local text = frame:CreateFontString(type .. "Text" .. count, "OVERLAY", "GameFontNormalSmall")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("MIDDLE")
	text:SetPoint("LEFT", frame, "LEFT", k.TextOffsetX, 0)
	text:SetWordWrap(false)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, k.FontSize)
	end

	local highlight = frame:CreateTexture(type .. "Highlight" .. count, "OVERLAY")
	highlight:SetColorTexture(unpack(k.NeutralButtonColor))
	highlight:SetPoint("TOPLEFT", 1, 0)
	highlight:SetPoint("BOTTOMRIGHT", -1, 0)
	highlight:SetBlendMode("ADD")
	highlight:Hide()

	local check = frame:CreateTexture(type .. "Check" .. count, "OVERLAY")
	check:SetWidth(k.CheckSize)
	check:SetHeight(k.CheckSize)
	check:SetPoint("RIGHT", frame, "RIGHT", -k.CheckOffsetX, 0)
	check:SetTexture(k.CheckTexture)
	check:Hide()

	local customTextureFrame = CreateFrame("Button", type .. "CustomTextureFrame" .. count, frame)
	customTextureFrame:SetWidth(k.CheckSize)
	customTextureFrame:SetHeight(k.CheckSize)
	customTextureFrame:SetPoint("RIGHT", frame, "RIGHT", -k.CheckOffsetX, 0)
	customTextureFrame:Hide()

	local customTexture = customTextureFrame:CreateTexture(type .. "CustomTexture" .. count, "OVERLAY")
	customTexture:SetAllPoints(customTextureFrame)

	---@class EPItemBase
	local widget = {
		frame = frame,
		type = type,
		useHighlight = true,
		check = check,
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
		textOffsetX = k.TextOffsetX,
		checkOffsetX = k.CheckOffsetX,
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
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.checkOffsetX - k.CheckSize, 0)
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
---@field childPullout EPDropdownPullout Child dropdown pullout.
---@field multiselect boolean|nil Whether multiple child pullout items can be selected at once.
---@field open boolean True if the child pullout is open.
---@field clickable boolean|nil If true, clicking on the frame will fire the OnValueChanged signal with no arguments.
-- Indicates the dropdown menu has children. Vertex color updated if selected. Attached to base frame.
---@field menuIndicator Texture
---@field menuIndicatorOffsetX integer Horizontal offset of the menuIndicator.
do
	local widgetType = "EPDropdownItemMenu"
	local widgetVersion = 1

	---@param self EPDropdownItemMenu
	---@param override? [number]
	local function UpdateMenuIndicator(self, override)
		if override then
			self.menuIndicator:SetVertexColor(unpack(override))
		else
			if self.enabled and #self.childPullout.items > 0 then
				if self:GetIsSelected() then
					self.menuIndicator:SetVertexColor(unpack(k.CheckedVertexColor))
				else
					self.menuIndicator:SetVertexColor(unpack(k.UncheckedVertexColor))
				end
			else
				self.menuIndicator:SetVertexColor(unpack(k.DisabledVertexColor))
			end
		end
	end

	---@param self EPDropdownItemMenu
	local function HandleFrameEnter(self)
		if self.specialOnEnter then
			self.specialOnEnter(self)
		end
		if self.enabled and self.useHighlight then
			self.highlight:Show()
		else
			self.highlight:Hide()
		end
		if self.enabled and #self.childPullout.items > 0 then
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
	local function InitializeChildPullout(self, dropdownParent)
		local autoWidth, height = dropdownParent.pullout.autoWidth, dropdownParent.dropdownItemHeight
		self.childPullout:SetItemHeight(height)
		self.childPullout:SetAutoWidth(autoWidth)
		self.childPullout:SetMaxVisibleItems(dropdownParent.maxItems)
	end

	---@param self EPDropdownItemMenu
	---@param selected boolean
	---@param value any
	---@param dropdownItemMenu EPDropdownItemMenu
	local function HandleMenuItemValueChanged(self, selected, value, dropdownItemMenu)
		self:SetChildValue(value)
		self:Fire("OnValueChanged", selected, value, dropdownItemMenu)
		if self.open and not self.multiselect then
			self.parentPullout:Close()
		end
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItem EPDropdownItemToggle
	local function HandleItemValueChanged(self, dropdownItem)
		local childValue = dropdownItem:GetValue()
		local childSelected = dropdownItem.selected
		if self.neverShowItemsAsSelected == true then
			dropdownItem:SetIsSelected(false)
		else
			dropdownItem:SetIsSelected(childSelected)
		end
		self:SetChildValue(childValue)
		self:Fire("OnValueChanged", childSelected, childValue)

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
		dropdownMenuItem:GetUserDataTable().initialValue = itemData.itemValue
		dropdownMenuItem:SetText(itemData.text)
		dropdownMenuItem:SetFontSize(dropdownParent.itemTextFontSize)
		if itemData.indent then
			dropdownMenuItem:SetHorizontalPadding(dropdownParent.itemHorizontalPadding + itemData.indent)
		else
			dropdownMenuItem:SetHorizontalPadding(dropdownParent.itemHorizontalPadding)
		end
		dropdownMenuItem:SetHeight(dropdownParent.dropdownItemHeight)
		dropdownMenuItem.parentDropdown = dropdownParent
		dropdownMenuItem.parentDropdownItemMenu = self
		dropdownMenuItem:GetUserDataTable().level = self:GetUserDataTable().level + 1
		dropdownMenuItem:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
		dropdownMenuItem:SetCallback("OnValueChanged", function(_, _, selected, value, childDropdownMenuItem)
			if childDropdownMenuItem then
				HandleMenuItemValueChanged(self, selected, value, childDropdownMenuItem)
			else
				HandleMenuItemValueChanged(self, selected, value, dropdownMenuItem)
			end
		end)
		self.childPullout:InsertItem(dropdownMenuItem)
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
		if itemData.indent then
			dropdownItemToggle:SetHorizontalPadding(dropdownParent.itemHorizontalPadding + itemData.indent)
		else
			dropdownItemToggle:SetHorizontalPadding(dropdownParent.itemHorizontalPadding)
		end
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
		self.childPullout:InsertItem(dropdownItemToggle, insertIndex)
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	local function SetMenuItems(self, dropdownItemData, dropdownParent)
		InitializeChildPullout(self, dropdownParent)
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData then
				CreateDropdownItemMenu(self, dropdownParent, itemData)
			else
				CreateDropdownItemToggle(self, dropdownParent, itemData)
			end
		end
		FixLevels(self.childPullout.frame, self.childPullout.frame:GetChildren())
		UpdateMenuIndicator(self)
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	---@param index integer?
	local function AddMenuItems(self, dropdownItemData, dropdownParent, index)
		InitializeChildPullout(self, dropdownParent)
		local currentIndex = index
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData then
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
		UpdateMenuIndicator(self)
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	local function RemoveMenuItems(self, dropdownItemData)
		for _, itemData in ipairs(dropdownItemData) do
			self.childPullout:RemoveItem(itemData.itemValue)
		end
		UpdateMenuIndicator(self)
	end

	---@param self EPDropdownItemMenu
	local function CloseMenu(self)
		self.childPullout:Close()
	end

	--- Updates the selected indicator color based on if the parent and child values are equal.
	---@param self EPDropdownItemMenu
	---@param _ boolean
	local function SetIsSelected(self, _)
		UpdateMenuIndicator(self)
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
		self.multiselect = false
		self.neverShowItemsAsSelected = false
		local childPullout = AceGUI:Create("EPDropdownPullout")
		childPullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		childPullout:SetCallback("OnOpen", function(widget)
			HandleChildPulloutOpen(self, widget)
		end)
		childPullout:SetCallback("OnClose", function()
			HandleChildPulloutClose(self)
		end)
		self.childPullout = childPullout
		UpdateMenuIndicator(self)
	end

	---@param self EPDropdownItemMenu
	local function OnRelease(self)
		EPItemBase.OnRelease(self)
		if self.childPullout then
			self.childPullout:Release()
		end
		self.childPullout = nil
		self:SetValue(nil)
		self:SetChildValue(nil)
		self:SetClickable(false)
		self.open = false
		self.neverShowItemsAsSelected = false
	end

	---@param self EPDropdownItemMenu
	local function Clear(self)
		self.childPullout:Clear()
		self:SetChildValue(nil)
		self.open = false
		self.neverShowItemsAsSelected = false
		UpdateMenuIndicator(self)
	end

	---@param self EPDropdownItemMenu
	---@param enabled boolean
	local function SetEnabled(self, enabled)
		EPItemBase.SetEnabled(self, enabled)
		UpdateMenuIndicator(self)
	end

	local function Constructor()
		---@class EPDropdownItemMenu
		local widget = EPItemBase.Create(widgetType)
		local count = AceGUI:GetNextWidgetNum(widgetType)

		local menuIndicator = widget.frame:CreateTexture(widget.type .. "MenuIndicator" .. count, "OVERLAY")
		menuIndicator:SetWidth(k.SubHeight)
		menuIndicator:SetHeight(k.SubHeight)
		menuIndicator:SetPoint("RIGHT", widget.frame, "RIGHT", -k.MenuIndicatorOffsetX, -k.MenuIndicatorOffsetY)
		menuIndicator:SetTexture(k.DropdownTexture)
		menuIndicator:SetRotation(k.Pi / 2)

		widget.menuIndicatorOffsetX = k.MenuIndicatorOffsetX
		widget.menuIndicator = menuIndicator
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.SetEnabled = SetEnabled
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
		widget.RemoveMenuItems = RemoveMenuItems
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
