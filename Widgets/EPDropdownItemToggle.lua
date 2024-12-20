local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local ipairs = ipairs
local pairs = pairs
local select = select
local pi = math.pi

local textOffsetX = 4
local checkOffsetLeftX = -2
local checkOffsetRightX = -8
local checkSize = 16
local fontSize = 14
local dropdownItemHeight = 24
local subHeight = 18
local checkedVertexColor = { 226.0 / 255, 180.0 / 255, 36.0 / 255.0, 1.0 }

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
---@field disabled boolean
---@field parent table|Frame
---@field specialOnEnter function

local EPItemBase = {
	version = 1000,
	counter = 0,
}

local function HandleItemBaseFrameEnter(frame)
	local self = frame.obj
	if self.useHighlight then
		self.highlight:Show()
	end
	self:Fire("OnEnter")
	if self.specialOnEnter then
		self.specialOnEnter(self)
	end
end

local function HandleItemBaseFrameLeave(frame)
	local self = frame.obj
	self.highlight:Hide()
	self:Fire("OnLeave")
	if self.specialOnLeave then
		self.specialOnLeave(self)
	end
end

---@param self EPItemBase
---@param disabled boolean
function EPItemBase.SetDisabled(self, disabled)
	self.disabled = disabled
	if disabled then
		self.useHighlight = false
		self.text:SetTextColor(0.5, 0.5, 0.5)
	else
		self.useHighlight = true
		self.text:SetTextColor(1, 1, 1)
	end
end

---@param self EPItemBase
function EPItemBase.OnAcquire(self)
	self.frame:SetToplevel(true)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
end

---@param self EPItemBase
function EPItemBase.OnRelease(self)
	self:SetDisabled(false)
	self.parentPullout = nil
	self.frame:SetParent(nil)
	self.frame:ClearAllPoints()
	self.frame:Hide()
end

---@param self EPItemBase
---@param pullout EPDropdownPullout
function EPItemBase.SetPullout(self, pullout)
	self.parentPullout = pullout
	self.frame:SetParent(nil)
	self.frame:SetParent(pullout.itemFrame)
	self.parent = pullout.itemFrame
	FixLevels(pullout.itemFrame, pullout.itemFrame:GetChildren())
end

---@param self EPItemBase
---@param text string
function EPItemBase.SetText(self, text)
	self.text:SetText(text or "")
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

-- This is called by a Dropdown-Pullout. Do not call this method directly
function EPItemBase.SetOnLeave(self, func)
	self.specialOnLeave = func
end

-- This is called by a Dropdown-Pullout. Do not call this method directly
function EPItemBase.SetOnEnter(self, func)
	self.specialOnEnter = func
end

function EPItemBase.Create(type)
	local count = AceGUI:GetNextWidgetNum(type)

	local frame = CreateFrame("Button", type .. count)
	frame:SetHeight(dropdownItemHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetScript("OnEnter", HandleItemBaseFrameEnter)
	frame:SetScript("OnLeave", HandleItemBaseFrameLeave)

	local text = frame:CreateFontString(type .. "Text" .. count, "OVERLAY", "GameFontNormalSmall")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetPoint("LEFT", frame, "LEFT", textOffsetX, 0)
	text:SetPoint("RIGHT", frame, "RIGHT", checkOffsetRightX, 0)
	text:SetWordWrap(false)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, fontSize)
	end

	local highlight = frame:CreateTexture(type .. "Highlight" .. count, "OVERLAY")
	highlight:SetColorTexture(0.25, 0.25, 0.5, 0.5)
	highlight:SetTexelSnappingBias(0.0)
	highlight:SetSnapToPixelGrid(false)
	highlight:SetPoint("TOPLEFT", 0, 0)
	highlight:SetPoint("BOTTOMRIGHT", 0, 0)
	highlight:SetBlendMode("ADD")
	highlight:Hide()

	local check = frame:CreateTexture(type .. "Check" .. count, "OVERLAY")
	check:SetWidth(checkSize)
	check:SetHeight(checkSize)
	check:SetPoint("RIGHT", frame, "RIGHT", checkOffsetLeftX, 0)
	check:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	check:Hide()

	local childSelectedIndicator = frame:CreateTexture(type .. "ChildSelectedIndicator" .. count, "OVERLAY")
	childSelectedIndicator:SetWidth(subHeight)
	childSelectedIndicator:SetHeight(subHeight)
	childSelectedIndicator:SetPoint("RIGHT", frame, "RIGHT", -3, -1)
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
		OnAcquire = EPItemBase.OnAcquire,
		OnRelease = EPItemBase.OnRelease,
		SetPullout = EPItemBase.SetPullout,
		GetText = EPItemBase.GetText,
		SetText = EPItemBase.SetText,
		SetDisabled = EPItemBase.SetDisabled,
		SetPoint = EPItemBase.SetPoint,
		Show = EPItemBase.Show,
		Hide = EPItemBase.Hide,
		SetOnLeave = EPItemBase.SetOnLeave,
		SetOnEnter = EPItemBase.SetOnEnter,
	}

	frame.obj = widget

	return widget
end

---@class EPDropdownItemToggle : EPItemBase
---@field selected boolean
---@field neverShowItemsAsSelected boolean
do
	local widgetType = "EPDropdownItemToggle"
	local widgetVersion = 1

	-- Updates the visibility of the check texture based on selected and neverShowItemsAsSelected
	---@param dropdownItemToggle EPDropdownItemToggle
	local function UpdateCheckVisibility(dropdownItemToggle)
		if dropdownItemToggle.selected and not dropdownItemToggle.neverShowItemsAsSelected then
			dropdownItemToggle.check:Show()
		else
			dropdownItemToggle.check:Hide()
		end
	end

	local function HandleFrameClick(frame, _)
		local self = frame.obj --[[@as EPDropdownItemToggle]]
		if self.disabled then
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
		widget.frame:SetScript("OnClick", HandleFrameClick)
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.GetIsSelected = GetIsSelected
		widget.SetIsSelected = SetIsSelected
		widget.SetValue = SetValue
		widget.GetValue = GetValue
		widget.SetNeverShowItemsAsSelected = SetNeverShowItemsAsSelected
		AceGUI:RegisterAsWidget(widget)
		return widget
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end

---@class EPDropdownItemMenu : EPItemBase
---@field childPullout EPDropdownPullout
---@field selected boolean
---@field neverShowItemsAsSelected boolean
---@field open boolean
do
	local widgetType = "EPDropdownItemMenu"
	local widgetVersion = 1

	local function HandleFrameEnter(frame)
		local self = frame.obj --[[@as EPDropdownItemMenu]]
		self:Fire("OnEnter")
		if self.specialOnEnter then
			self.specialOnEnter(self)
		end
		if self.useHighlight then
			self.highlight:Show()
		else
			self.highlight:Hide()
		end
		if not self.disabled and self.childPullout then
			-- self.frame:GetFrameLevel() + 100
			self.childPullout:Open("TOPLEFT", self.frame, "TOPRIGHT", -1, 0)
		end
	end

	local function HandleFrameHide(frame)
		local self = frame.obj --[[@as EPDropdownItemMenu]]
		if self.childPullout then
			self.childPullout:Close()
		end
	end

	---@param childPullout EPDropdownPullout
	local function HandleChildPulloutOpen(childPullout)
		local self = childPullout:GetUserDataTable().obj --[[@as EPDropdownItemMenu]]
		local value = self:GetUserDataTable().obj.value -- EPDropdown's value
		for _, dropdownItem in childPullout:IterateItems() do
			dropdownItem:SetIsSelected(dropdownItem:GetValue() == value)
		end
		self.open = true
		self:Fire("OnOpened")
	end

	---@param childPullout EPDropdownPullout
	local function HandleChildPulloutClose(childPullout)
		local self = childPullout:GetUserDataTable().obj --[[@as EPDropdownItemMenu]]
		self.open = false
		self:Fire("OnClosed")
	end

	---@param self EPDropdownItemMenu
	local function CreateChildPullout(self)
		local childPullout = AceGUI:Create("EPDropdownPullout")
		childPullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		childPullout:GetUserDataTable().obj = self
		childPullout:SetCallback("OnOpen", HandleChildPulloutOpen)
		childPullout:SetCallback("OnClose", HandleChildPulloutClose)
		return childPullout
	end

	---@param dropdownItem EPDropdownItemMenu
	---@param event string
	---@param selected boolean
	---@param value any
	local function HandleMenuItemValueChanged(dropdownItem, event, selected, value)
		local self = dropdownItem:GetUserDataTable().parentItemMenu --[[@as EPDropdownItemMenu]]
		self:SetChildValue(value)
		self:Fire("OnValueChanged", selected, value)
		if self.open then
			self.parentPullout:Close()
		end
	end

	---@param dropdownItem EPDropdownItemToggle
	---@param event string
	---@param selected boolean
	local function HandleItemValueChanged(dropdownItem, event, selected)
		local self = dropdownItem:GetUserDataTable().parentItemMenu --[[@as EPDropdownItemMenu]]
		self:SetChildValue(dropdownItem:GetValue())
		if selected then
			self:Fire("OnValueChanged", dropdownItem.selected, dropdownItem:GetValue())
			if self.neverShowItemsAsSelected == true then
				dropdownItem:SetIsSelected(false)
			end
		else
			if self.neverShowItemsAsSelected == true then
				self:Fire("OnValueChanged", dropdownItem.selected, dropdownItem:GetValue())
			end
			dropdownItem:SetIsSelected(true)
		end
		if self.open then
			self.parentPullout:Close()
		end
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	local function SetMenuItems(self, dropdownItemData, dropdownParent)
		self.childPullout = CreateChildPullout(self)
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData and #itemData.dropdownItemMenuData > 0 then
				local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
				dropdownMenuItem:SetValue(itemData.itemValue)
				dropdownMenuItem:SetText(itemData.text)
				dropdownMenuItem:GetUserDataTable().obj = dropdownParent
				dropdownMenuItem:GetUserDataTable().parentItemMenu = self
				dropdownMenuItem:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
				dropdownMenuItem:SetCallback("OnValueChanged", HandleMenuItemValueChanged)
				self.childPullout:AddItem(dropdownMenuItem)
				dropdownMenuItem:SetMenuItems(itemData.dropdownItemMenuData, dropdownParent)
			else
				local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
				dropdownItemToggle:SetValue(itemData.itemValue)
				dropdownItemToggle:SetText(itemData.text)
				dropdownItemToggle:GetUserDataTable().obj = dropdownParent
				dropdownItemToggle:GetUserDataTable().parentItemMenu = self
				dropdownItemToggle:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
				dropdownItemToggle:SetCallback("OnValueChanged", HandleItemValueChanged)
				self.childPullout:AddItem(dropdownItemToggle)
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
			self.childPullout = CreateChildPullout(self)
		end
		local currentIndex = index
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData and #itemData.dropdownItemMenuData > 0 then
				local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
				dropdownMenuItem:SetValue(itemData.itemValue)
				dropdownMenuItem:SetText(itemData.text)
				dropdownMenuItem:GetUserDataTable().obj = dropdownParent
				dropdownMenuItem:GetUserDataTable().parentItemMenu = self
				dropdownMenuItem:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
				dropdownMenuItem:SetCallback("OnValueChanged", HandleMenuItemValueChanged)
				self.childPullout:AddItem(dropdownMenuItem)
				dropdownMenuItem:SetMenuItems(itemData.dropdownItemMenuData, dropdownParent)
			else
				local alreadyExists = false
				for _, item in ipairs(self.childPullout.items) do
					if item:GetValue() == itemData.itemValue then
						alreadyExists = true
						break
					end
				end
				if not alreadyExists then
					local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
					dropdownItemToggle:SetValue(itemData.itemValue)
					dropdownItemToggle:SetText(itemData.text)
					dropdownItemToggle:GetUserDataTable().obj = dropdownParent
					dropdownItemToggle:GetUserDataTable().parentItemMenu = self
					dropdownItemToggle:SetNeverShowItemsAsSelected(self.neverShowItemsAsSelected)
					dropdownItemToggle:SetCallback("OnValueChanged", HandleItemValueChanged)
					if currentIndex then
						self.childPullout:InsertItem(dropdownItemToggle, currentIndex)
						currentIndex = currentIndex + 1
					else
						self.childPullout:AddItem(dropdownItemToggle)
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

	---@param self EPDropdownItemMenu
	---@param selected boolean
	local function SetIsSelected(self, selected)
		local childValue = self:GetChildValue()
		local parentValue = self:GetUserDataTable().obj.value
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
		local parentValue = self:GetUserDataTable().obj.value
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
	---@param value any
	local function SetNeverShowItemsAsSelected(self, value)
		self.neverShowItemsAsSelected = value
	end

	---@param self EPDropdownItemMenu
	local function OnAcquire(self)
		EPItemBase.OnAcquire(self)
		self.open = false
		self.selected = false
		self.neverShowItemsAsSelected = false
		self:SetValue(nil)
		self:SetChildValue(nil)
	end

	---@param self EPDropdownItemMenu
	local function OnRelease(self)
		if self.childPullout then
			self.childPullout:Release()
		end
		self.childPullout = nil
		self:SetValue(nil)
		self:SetChildValue(nil)
		EPItemBase.OnRelease(self)
		self.open = false
		self.selected = false
		self.neverShowItemsAsSelected = false
	end

	local function Constructor()
		---@class EPDropdownItemMenu
		local widget = EPItemBase.Create(widgetType)
		widget.childSelectedIndicator:Show()
		widget.frame:SetScript("OnEnter", HandleFrameEnter)
		widget.frame:SetScript("OnHide", HandleFrameHide)
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.SetIsSelectedBasedOnChildValue = SetIsSelectedBasedOnChildValue
		widget.SetIsSelected = SetIsSelected
		widget.GetIsSelected = GetIsSelected
		widget.SetValue = SetValue
		widget.GetValue = GetValue
		widget.SetChildValue = SetChildValue
		widget.GetChildValue = GetChildValue
		widget.SetMenuItems = SetMenuItems
		widget.AddMenuItems = AddMenuItems
		widget.CloseMenu = CloseMenu
		widget.SetNeverShowItemsAsSelected = SetNeverShowItemsAsSelected
		AceGUI:RegisterAsWidget(widget)
		return widget
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end
