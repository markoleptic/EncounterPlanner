local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local textOffsetX = 4
local checkOffsetLeftX = -2
local checkOffsetRightX = -8
local checkSize = 16
local fontSize = 14
local dropdownItemHeight = 24
local subHeight = 18
local checkedVertexColor = { 226.0 / 255, 180.0 / 255, 36.0 / 255.0, 1.0 }

local function fixlevels(parent, ...)
	local i = 1
	local child = select(i, ...)
	while child do
		child:SetFrameLevel(parent:GetFrameLevel() + 1)
		fixlevels(child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

---@class EPItemBase : AceGUIWidget
---@field type string
---@field version integer
---@field counter integer
---@field frame Frame
---@field pullout EPDropdownPullout
---@field highlight Texture
---@field useHighlight boolean
---@field text FontString
---@field check Texture
---@field disabled boolean
---@field parent table|Frame

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
	self.pullout = nil
	self.frame:SetParent(nil)
	self.frame:ClearAllPoints()
	self.frame:Hide()
end

---@param self EPItemBase
---@param pullout EPDropdownPullout
function EPItemBase.SetPullout(self, pullout)
	self.pullout = pullout
	self.frame:SetParent(nil)
	self.frame:SetParent(pullout.itemFrame)
	self.parent = pullout.itemFrame
	fixlevels(pullout.itemFrame, pullout.itemFrame:GetChildren())
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

---@param self EPItemBase
---@param val boolean
function EPItemBase.SetValue(self, val) end

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

	local frame = CreateFrame("Button", "EPDropdownItemBase" .. count)
	frame:SetHeight(dropdownItemHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetScript("OnEnter", HandleItemBaseFrameEnter)
	frame:SetScript("OnLeave", HandleItemBaseFrameLeave)

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetPoint("LEFT", frame, "LEFT", textOffsetX, 0)
	text:SetPoint("RIGHT", frame, "RIGHT", checkOffsetRightX, 0)
	text:SetWordWrap(false)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, fontSize)
	end

	local highlight = frame:CreateTexture("EPDropdownItemBase" .. count .. "Highlight", "OVERLAY")
	highlight:SetColorTexture(0.25, 0.25, 0.5, 0.5)
	highlight:SetTexelSnappingBias(0.0)
	highlight:SetSnapToPixelGrid(false)
	highlight:SetPoint("TOPLEFT", 0, 0)
	highlight:SetPoint("BOTTOMRIGHT", 0, 0)
	highlight:SetBlendMode("ADD")
	highlight:Hide()

	local check = frame:CreateTexture("EPDropdownItemBase" .. count .. "Check", "OVERLAY")
	check:SetWidth(checkSize)
	check:SetHeight(checkSize)
	check:SetPoint("RIGHT", frame, "RIGHT", checkOffsetLeftX, 0)
	check:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	check:Hide()

	local sub = frame:CreateTexture(nil, "OVERLAY")
	sub:SetWidth(subHeight)
	sub:SetHeight(subHeight)
	sub:SetPoint("RIGHT", frame, "RIGHT", -3, -1)
	sub:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	sub:SetRotation(math.pi / 2)
	sub:Hide()

	---@class EPItemBase
	local widget = {
		frame = frame,
		type = type,
		useHighlight = true,
		check = check,
		sub = sub,
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
		SetValue = EPItemBase.SetValue,
	}

	frame.obj = widget

	return widget
end

---@class EPDropdownItemToggle : EPItemBase
---@field value any
---@field neverShowItemsAsSelected boolean
do
	local widgetType = "EPDropdownItemToggle"
	local widgetVersion = 1

	---@param dropdownItemToggle EPDropdownItemToggle
	local function UpdateToggle(dropdownItemToggle)
		if dropdownItemToggle.value and not dropdownItemToggle.neverShowItemsAsSelected then
			dropdownItemToggle.check:Show()
		else
			dropdownItemToggle.check:Hide()
		end
	end

	local function HandleFrameClick(frame, _)
		local self = frame.obj
		if self.disabled then
			return
		end
		self.value = not self.value
		UpdateToggle(self)
		self:Fire("OnValueChanged", self.value)
	end

	---@param self EPDropdownItemToggle
	---@param value any
	local function SetValue(self, value)
		self.value = value
		UpdateToggle(self)
	end

	---@param self EPDropdownItemToggle
	---@param value any
	local function SetNeverShowItemsAsSelected(self, value)
		self.neverShowItemsAsSelected = value
	end

	---@param self EPDropdownItemToggle
	local function OnAcquire(self)
		EPItemBase.OnAcquire(self)
		self.neverShowItemsAsSelected = false
		self:SetValue(nil)
	end

	---@param self EPDropdownItemToggle
	local function OnRelease(self)
		EPItemBase.OnRelease(self)
		self.neverShowItemsAsSelected = nil
		self:SetValue(nil)
	end

	---@param self EPDropdownItemToggle
	local function GetValue(self)
		return self.value
	end

	local function Constructor()
		---@class EPDropdownItemToggle
		local widget = EPItemBase.Create(widgetType)
		widget.frame:SetScript("OnClick", HandleFrameClick)
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.GetValue = GetValue
		widget.SetValue = SetValue
		widget.SetNeverShowItemsAsSelected = SetNeverShowItemsAsSelected
		AceGUI:RegisterAsWidget(widget)
		return widget
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end

---@class EPDropdownItemMenu : EPItemBase
---@field submenu EPDropdownPullout
---@field value any
---@field neverShowItemsAsSelected boolean
do
	local widgetType = "EPDropdownItemMenu"
	local widgetVersion = 1

	local function HandleFrameEnter(frame)
		local self = frame.obj
		self:Fire("OnEnter")
		if self.specialOnEnter then
			self.specialOnEnter(self)
		end
		if self.useHighlight then
			self.highlight:Show()
		else
			self.highlight:Hide()
		end
		if not self.disabled and self.submenu then
			self.submenu:Open("TOPLEFT", self.frame, "TOPRIGHT", -1, 0, self.frame:GetFrameLevel() + 100)
		end
	end

	local function HandleFrameHide(frame)
		local self = frame.obj
		if self.submenu then
			self.submenu:Close()
		end
	end

	---@param submenu EPDropdownPullout
	local function HandleSubmenuOpen(submenu)
		local self = submenu:GetUserDataTable().obj
		local value = self:GetUserDataTable().obj.value -- EPDropdown's value
		for _, dropdownItem in submenu:IterateItems() do
			dropdownItem:SetValue(dropdownItem:GetUserDataTable().value == value)
		end
		self.open = true
		self:Fire("OnOpened")
	end

	---@param submenu EPDropdownPullout
	local function HandleSubmenuClose(submenu)
		local self = submenu:GetUserDataTable().obj
		self.open = nil
		self:Fire("OnClosed")
	end

	---@param self EPDropdownItemMenu
	local function CreateSubmenu(self)
		local submenu = AceGUI:Create("EPDropdownPullout")
		submenu.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		submenu:GetUserDataTable().obj = self
		submenu:SetCallback("OnOpen", HandleSubmenuOpen)
		submenu:SetCallback("OnClose", HandleSubmenuClose)
		return submenu
	end

	---@param dropdownItem EPDropdownItemMenu
	---@param event string
	---@param checked boolean
	---@param value any
	local function HandleMenuItemValueChanged(dropdownItem, event, checked, value)
		local self = dropdownItem:GetUserDataTable().menuItemObj
		self:GetUserDataTable().childValue = value
		self:Fire("OnValueChanged", dropdownItem.value, value)
		if self.open then
			self.pullout:Close()
		end
	end

	---@param dropdownItem EPDropdownItemToggle
	---@param event string
	---@param checked boolean
	local function HandleItemValueChanged(dropdownItem, event, checked)
		local self = dropdownItem:GetUserDataTable().menuItemObj
		self:GetUserDataTable().childValue = dropdownItem:GetUserDataTable().value
		if checked then
			self:Fire("OnValueChanged", dropdownItem.value, dropdownItem:GetUserDataTable().value)
			if self.neverShowItemsAsSelected == true then
				dropdownItem:SetValue(false)
			end
		else
			dropdownItem:SetValue(true)
		end
		if self.open then
			self.pullout:Close()
		end
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	local function SetMenuItems(self, dropdownItemData, dropdownParent)
		self.submenu = CreateSubmenu(self)
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData and #itemData.dropdownItemMenuData > 0 then
				local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
				dropdownMenuItem:SetText(itemData.text)
				dropdownMenuItem:GetUserDataTable().obj = dropdownParent
				dropdownMenuItem:GetUserDataTable().menuItemObj = self
				dropdownMenuItem:GetUserDataTable().value = itemData.itemValue
				dropdownMenuItem:SetCallback("OnValueChanged", HandleMenuItemValueChanged)
				self.submenu:AddItem(dropdownMenuItem)
				dropdownMenuItem:SetMenuItems(itemData.dropdownItemMenuData, dropdownParent)
			else
				local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
				dropdownItemToggle:SetText(itemData.text)
				dropdownItemToggle:GetUserDataTable().obj = dropdownParent
				dropdownItemToggle:GetUserDataTable().menuItemObj = self
				dropdownItemToggle:GetUserDataTable().value = itemData.itemValue
				dropdownItemToggle:SetCallback("OnValueChanged", HandleItemValueChanged)
				self.submenu:AddItem(dropdownItemToggle)
			end
		end
		fixlevels(self.submenu.frame, self.submenu.frame:GetChildren())
	end

	---@param self EPDropdownItemMenu
	---@param dropdownItemData table<integer, DropdownItemData>
	---@param dropdownParent EPDropdown
	local function AddMenuItems(self, dropdownItemData, dropdownParent)
		if not self.submenu then
			self.submenu = CreateSubmenu(self)
		end
		for _, itemData in pairs(dropdownItemData) do
			if itemData.dropdownItemMenuData and #itemData.dropdownItemMenuData > 0 then
				local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
				dropdownMenuItem:SetText(itemData.text)
				dropdownMenuItem:GetUserDataTable().obj = dropdownParent
				dropdownMenuItem:GetUserDataTable().menuItemObj = self
				dropdownMenuItem:GetUserDataTable().value = itemData.itemValue
				dropdownMenuItem:SetCallback("OnValueChanged", HandleMenuItemValueChanged)
				self.submenu:AddItem(dropdownMenuItem)
				if self.neverShowItemsAsSelected == true then
					dropdownMenuItem:SetNeverShowItemsAsSelected(true)
				end
				dropdownMenuItem:SetMenuItems(itemData.dropdownItemMenuData, dropdownParent)
			else
				local alreadyExists = false
				for _, item in ipairs(self.submenu.items) do
					if item:GetUserDataTable().value == itemData.itemValue then
						alreadyExists = true
						break
					end
				end
				if not alreadyExists then
					local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
					dropdownItemToggle:SetText(itemData.text)
					dropdownItemToggle:GetUserDataTable().obj = dropdownParent
					dropdownItemToggle:GetUserDataTable().menuItemObj = self
					dropdownItemToggle:GetUserDataTable().value = itemData.itemValue
					dropdownItemToggle:SetCallback("OnValueChanged", HandleItemValueChanged)
					if self.neverShowItemsAsSelected == true then
						dropdownItemToggle:SetNeverShowItemsAsSelected(true)
					end
					self.submenu:AddItem(dropdownItemToggle)
				end
			end
		end
		fixlevels(self.submenu.frame, self.submenu.frame:GetChildren())
	end

	---@param self EPDropdownItemMenu
	local function CloseMenu(self)
		self.submenu:Close()
	end

	---@param self EPDropdownItemMenu
	local function SetValueWithoutParentCompare(self)
		local childValue = self:GetUserDataTable().childValue
		local neverShowItemsAsSelected = self.neverShowItemsAsSelected
		if childValue ~= nil and not neverShowItemsAsSelected then
			self.sub:SetVertexColor(unpack(checkedVertexColor)) -- indicate that a child item is selected
		else
			self.sub:SetVertexColor(1, 1, 1, 1)
		end
	end

	---@param self EPDropdownItemMenu
	---@param value any
	local function SetValue(self, value)
		local childValue = self:GetUserDataTable().childValue
		local parentValue = self:GetUserDataTable().obj.value
		local neverShowItemsAsSelected = self.neverShowItemsAsSelected
		if childValue ~= nil and childValue == parentValue and not neverShowItemsAsSelected then
			self.sub:SetVertexColor(unpack(checkedVertexColor)) -- indicate that a child item is selected
		else
			self.sub:SetVertexColor(1, 1, 1, 1)
		end
	end

	---@param self EPDropdownItemMenu
	---@param value any
	local function SetNeverShowItemsAsSelected(self, value)
		self.neverShowItemsAsSelected = value
	end

	---@param self EPDropdownItemMenu
	local function OnAcquire(self)
		EPItemBase.OnAcquire(self)
		self:GetUserDataTable().childValue = nil
		self.neverShowItemsAsSelected = false
	end

	---@param self EPDropdownItemMenu
	local function OnRelease(self)
		if self.submenu then
			self.submenu:Release()
		end
		EPItemBase.OnRelease(self)
		self:GetUserDataTable().childValue = nil
		self.neverShowItemsAsSelected = nil
	end

	local function Constructor()
		---@class EPDropdownItemMenu
		local widget = EPItemBase.Create(widgetType)
		widget.sub:Show()
		widget.frame:SetScript("OnEnter", HandleFrameEnter)
		widget.frame:SetScript("OnHide", HandleFrameHide)
		widget.OnAcquire = OnAcquire
		widget.OnRelease = OnRelease
		widget.SetValueWithoutParentCompare = SetValueWithoutParentCompare
		widget.SetValue = SetValue
		widget.SetMenuItems = SetMenuItems
		widget.AddMenuItems = AddMenuItems
		widget.CloseMenu = CloseMenu
		widget.SetNeverShowItemsAsSelected = SetNeverShowItemsAsSelected
		AceGUI:RegisterAsWidget(widget)
		return widget
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end
