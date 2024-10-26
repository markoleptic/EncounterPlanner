local AceGUI                  = LibStub("AceGUI-3.0")
local LSM                     = LibStub("LibSharedMedia-3.0")

local textOffsetX             = 4
local fontSize                = 12
local dropdownItemHeight      = 20
local dropdownItemExtraOffset = 0
local dropdownSliderOffsetX   = -8
local pulloutBackdrop         = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}
local dropdownBackdrop        = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}
local sliderBackdrop          = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

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

local function fixstrata(strata, parent, ...)
	local i = 1
	local child = select(i, ...)
	parent:SetFrameStrata(strata)
	while child do
		fixstrata(strata, child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

local sortlist = {}
local function sortTbl(x, y)
	local num1, num2 = tonumber(x), tonumber(y)
	if num1 and num2 then -- numeric comparison, either two numbers or numeric strings
		return num1 < num2
	else               -- compare everything else tostring'ed
		return tostring(x) < tostring(y)
	end
end

---@class DropdownItemData
---@field itemValue string|number the internal value used to index a dropdown item
---@field text string the value shown in the dropdown
---@field dropdownItemMenuData table<integer, DropdownItemData> nested dropdown item menus

do
	---@class EPDropdownPullout : AceGUIWidget
	---@field frame table|BackdropTemplate|Frame
	---@field scrollFrame ScrollFrame
	---@field itemFrame table|Frame
	---@field slider table|BackdropTemplate|Slider
	---@field type string
	---@field count integer
	---@field maxHeight number
	---@field scrollStatus { scrollvalue: number, offset: number}
	---@field items table<integer, EPItemBase>
	---@field hideOnLeave boolean

	local Type             = "EPDropdownPullout"
	local Version          = 1
	local defaultWidth     = 200
	local defaultMaxHeight = 600

	local function OnEnter(item)
		local self = item.pullout
		for k, v in ipairs(self.items) do
			if v.CloseMenu and v ~= item then
				v:CloseMenu()
			end
		end
	end

	local function HandleMouseWheel(frame, value)
		local self = frame.obj
		if self then
			self:MoveScroll(value)
		end
	end

	local function HandleScrollValueChanged(frame, value)
		local self = frame.obj
		if self then
			self:SetScroll(value)
		end
	end

	local function HandleSizeChanged(frame)
		local self = frame.obj
		if self then
			self:FixScroll()
		end
	end

	---@param self EPDropdownPullout
	local function OnAcquire(self)
		self.frame:SetParent(UIParent)
	end

	---@param self EPDropdownPullout
	local function OnRelease(self)
		self:Clear()
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	---@param self EPDropdownPullout
	---@param item EPDropdownItemToggle|EPDropdownItemMenu
	local function AddItem(self, item)
		self.items[#self.items + 1] = item
		local h = #self.items * dropdownItemHeight
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h + dropdownItemExtraOffset, self.maxHeight))
		item.frame:SetPoint("LEFT", self.itemFrame, "LEFT")
		item.frame:SetPoint("RIGHT", self.itemFrame, "RIGHT")
		item:SetPullout(self)
		item:SetOnEnter(OnEnter)
	end

	---@param self EPDropdownPullout
	---@param point string
	---@param relFrame string|frame
	---@param relPoint string
	---@param x number
	---@param y number
	local function Open(self, point, relFrame, relPoint, x, y)
		local items = self.items
		local frame = self.frame
		local itemFrame = self.itemFrame
		frame:SetPoint(point, relFrame, relPoint, x, y)
		local height = 0
		for i, item in pairs(items) do
			item:SetPoint("TOP", itemFrame, "TOP", 0, (i - 1) * -dropdownItemHeight)
			item:Show()
			height = height + dropdownItemHeight
		end
		itemFrame:SetHeight(height)
		fixstrata("TOOLTIP", frame, frame:GetChildren())
		frame:Show()
		self:Fire("OnOpen")
	end

	---@param self EPDropdownPullout
	local function Close(self)
		self.frame:Hide()
		self:Fire("OnClose")
	end

	---@param self EPDropdownPullout
	local function Clear(self)
		local items = self.items
		for i, item in pairs(items) do
			AceGUI:Release(item)
			items[i] = nil
		end
	end

	---@param self EPDropdownPullout
	local function IterateItems(self)
		return ipairs(self.items)
	end

	---@param self EPDropdownPullout
	---@param val boolean
	local function SetHideOnLeave(self, val)
		self.hideOnLeave = val
	end

	---@param self EPDropdownPullout
	---@param height number
	local function SetMaxHeight(self, height)
		self.maxHeight = height or defaultMaxHeight
		if self.frame:GetHeight() > height then
			self.frame:SetHeight(height)
		elseif (self.itemFrame:GetHeight() + dropdownItemExtraOffset) < height then
			self.frame:SetHeight(self.itemFrame:GetHeight() + dropdownItemExtraOffset) -- see :AddItem
		end
	end

	---@param self EPDropdownPullout
	---@param value number
	local function SetScroll(self, value)
		local status = self.scrollStatus
		local frame, child = self.scrollFrame, self.itemFrame
		local height, viewheight = frame:GetHeight(), child:GetHeight()
		local offset
		if viewheight <= (height + 0.5) then
			offset = 0
		else
			offset = floor((viewheight - height) / 1000 * value)
		end
		child:ClearAllPoints()
		child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, offset)
		child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", self.slider:IsShown() and -12 or 0, offset)
		status.offset = offset
		status.scrollvalue = value
	end

	---@param self EPDropdownPullout
	---@param value number
	local function MoveScroll(self, value)
		local status = self.scrollStatus
		local frame, child = self.scrollFrame, self.itemFrame
		local height, viewheight = frame:GetHeight(), child:GetHeight()
		if viewheight <= (height + 0.5) then
			self.slider:Hide()
		else
			self.slider:Show()
			local diff = height - viewheight
			local delta = 1
			if value < 0 then
				delta = -1
			end
			self.slider:SetValue(min(max(status.scrollvalue + delta * (1000 / (diff / 45)), 0), 1000))
		end
	end

	---@param self EPDropdownPullout
	local function FixScroll(self)
		local status = self.scrollStatus
		local frame, child = self.scrollFrame, self.itemFrame
		local height, viewheight = frame:GetHeight(), child:GetHeight()
		local offset = status.offset or 0
		if viewheight <= (height + 0.5) then
			self.slider:Hide()
			child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, offset)
			self.slider:SetValue(0)
		else
			self.slider:Show()
			local value = (offset / (viewheight - height) * 1000)
			if value > 1000 then value = 1000 end
			self.slider:SetValue(value)
			self:SetScroll(value)
			if value < 1000 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, offset)
				child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, offset)
				status.offset = offset
			end
		end
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(pulloutBackdrop)
		frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(defaultWidth)
		frame:SetHeight(20)

		local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetScript("OnMouseWheel", HandleMouseWheel)
		scrollFrame:SetScript("OnSizeChanged", HandleSizeChanged)
		scrollFrame:SetToplevel(true)
		scrollFrame:SetFrameStrata("FULLSCREEN_DIALOG")

		local itemFrame = CreateFrame("Frame", nil, scrollFrame)
		itemFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		itemFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
		itemFrame:SetToplevel(true)
		itemFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		scrollFrame:SetScrollChild(itemFrame)

		local slider = CreateFrame("Slider", Type .. count .. "ScrollBar", scrollFrame, "BackdropTemplate")
		slider:SetOrientation("VERTICAL")
		slider:SetHitRectInsets(0, 0, -10, 0)
		slider:SetBackdrop(sliderBackdrop)
		slider:SetWidth(8)
		slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
		slider:SetFrameStrata("FULLSCREEN_DIALOG")
		slider:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", dropdownSliderOffsetX, 0)
		slider:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", dropdownSliderOffsetX, 0)
		slider:SetScript("OnValueChanged", HandleScrollValueChanged)
		slider:SetMinMaxValues(0, 1000)
		slider:SetValueStep(1)
		slider:SetValue(0)

		scrollFrame:Show()
		itemFrame:Show()
		slider:Hide()

		---@class EPDropdownPullout
		local widget    = {
			OnAcquire      = OnAcquire,
			OnRelease      = OnRelease,
			AddItem        = AddItem,
			Open           = Open,
			Close          = Close,
			Clear          = Clear,
			IterateItems   = IterateItems,
			SetHideOnLeave = SetHideOnLeave,
			SetMaxHeight   = SetMaxHeight,
			SetScroll      = SetScroll,
			MoveScroll     = MoveScroll,
			FixScroll      = FixScroll,
			frame          = frame,
			scrollFrame    = scrollFrame,
			itemFrame      = itemFrame,
			slider         = slider,
			type           = Type,
			count          = count,
			maxHeight      = defaultMaxHeight,
			scrollStatus   = {
				scrollvalue = 0,
			},
			items          = {}
		}

		frame.obj       = widget
		scrollFrame.obj = widget
		itemFrame.obj   = widget
		slider.obj      = widget

		widget:FixScroll()

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
	---@class EPDropdown : AceGUIWidget
	---@field frame table|BackdropTemplate|Frame
	---@field dropdown table|Frame
	---@field text FontString
	---@field slider table|BackdropTemplate|Slider
	---@field type string
	---@field count integer
	---@field label FontString
	---@field buttonCover Button
	---@field button Button
	---@field pullout EPDropdownPullout
	---@field value any|nil
	---@field open boolean|nil
	---@field hasClose boolean|nil
	---@field disabled boolean|nil
	---@field multiselect boolean|nil
	---@field pulloutWidth number
	---@field obj any|nil

	local Type    = "EPDropdown"
	local Version = 1

	local function HandleDropdownHide(frame)
		local self = frame.obj
		if self.open then
			self.pullout:Close()
		end
	end

	local function HandleButtonEnter(frame)
		local self = frame.obj
		self.button:LockHighlight()
		self:Fire("OnEnter")
	end

	local function HandleButtonLeave(frame)
		local self = frame.obj
		self.button:UnlockHighlight()
		self:Fire("OnLeave")
	end

	local function HandleToggleDropdownPullout(frame)
		local self = frame.obj
		if self.open then
			self.open = nil
			self.pullout:Close()
			AceGUI:ClearFocus()
		else
			self.open = true
			self.pullout:SetWidth(self.pulloutWidth or self.frame:GetWidth())
			self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, self.label:IsShown() and -1 or 1)
			AceGUI:SetFocus(self)
		end
	end

	local function HandlePulloutOpen(frame)
		local self = frame:GetUserDataTable().obj
		local value = self.value
		if not self.multiselect then
			for _, item in frame:IterateItems() do
				item:SetValue(item:GetUserDataTable().value == value)
			end
		end
		self.open = true
		self.button:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
		self:Fire("OnOpened")
	end

	local function HandlePulloutClose(frame)
		local self = frame:GetUserDataTable().obj
		self.open = nil
		self.button:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		self:Fire("OnClosed")
	end

	local function ShowMultiText(self)
		local text
		for _, widget in self.pullout:IterateItems() do
			if widget.type == "Dropdown-Item-Toggle" or widget.type == "EPDropdownItemToggle" then
				if widget:GetValue() then
					if text then
						text = text .. ", " .. widget:GetText()
					else
						text = widget:GetText()
					end
				end
			end
		end
		self:SetText(text)
	end

	---@param self EPDropdown
	---@param value any
	---@return string|nil
	local function FindItemText(self, value)
		local function searchItems(items)
			for _, item in ipairs(items) do
				if not item:GetUserDataTable().neverShowItemsAsSelected then
					if item:GetUserDataTable().value == value then
						return item.text:GetText()
					end
					if item.submenu then
						local foundText = searchItems(item.submenu.items)
						if foundText then
							return foundText
						end
					end
				end
			end
		end
		return searchItems(self.pullout.items)
	end

	---@param self EPDropdown
	---@param value any
	---@return EPDropdownItemMenu|nil
	local function FindItemFromValue(self, value)
		local function searchItems(items)
			for _, item in ipairs(items) do
				if not item:GetUserDataTable().neverShowItemsAsSelected then
					if item:GetUserDataTable().value == value then
						return item
					end
					if item.submenu then
						local foundItem = searchItems(item.submenu.items)
						if foundItem then
							return foundItem
						end
					end
				end
			end
		end
		return searchItems(self.pullout.items)
	end

	---@param dropdownItem EPDropdownItemMenu
	---@param event string
	---@param checked boolean
	---@param value any
	local function HandleMenuItemValueChanged(dropdownItem, event, checked, value)
		local self = dropdownItem:GetUserDataTable().obj
		if self.multiselect then
			self:Fire("OnValueChanged", dropdownItem:GetUserDataTable().value, checked)
			ShowMultiText(self)
		else
			self:SetValue(value)
			self:Fire("OnValueChanged", value)

			if self.open then
				self.pullout:Close()
			end
		end
	end

	---@param dropdownItem EPDropdownItemToggle
	---@param event string
	---@param checked boolean
	local function HandleItemValueChanged(dropdownItem, event, checked)
		local self = dropdownItem:GetUserDataTable().obj
		if self.multiselect then
			self:Fire("OnValueChanged", dropdownItem:GetUserDataTable().value, checked)
			ShowMultiText(self)
		else
			if checked then
				local newValue = dropdownItem:GetUserDataTable().value
				self:SetValue(newValue)
				self:Fire("OnValueChanged", newValue)
			else
				dropdownItem:SetValue(true)
			end
			if self.open then
				self.pullout:Close()
			end
		end
	end

	---@param self EPDropdown
	local function OnAcquire(self)
		self.pullout = AceGUI:Create("EPDropdownPullout") --[[@as EPDropdownPullout]]
		self.pullout:GetUserDataTable().obj = self
		self.pullout:SetCallback("OnClose", HandlePulloutClose)
		self.pullout:SetCallback("OnOpen", HandlePulloutOpen)
		self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		fixlevels(self.pullout.frame, self.pullout.frame:GetChildren())

		self:SetHeight(44)
		self:SetWidth(200)
		self:SetLabel()
		self:SetPulloutWidth(nil)
	end

	---@param self EPDropdown
	local function OnRelease(self)
		if self.open then
			self.pullout:Close()
		end
		AceGUI:Release(self.pullout)
		self.pullout = nil

		self:SetText("")
		self:SetDisabled(false)
		self:SetMultiselect(false)

		self.value = nil
		self.open = nil
		self.hasClose = nil

		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	---@param self EPDropdown
	---@param disabled any
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.text:SetTextColor(0.5, 0.5, 0.5)
			self.button:Disable()
			self.buttonCover:Disable()
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.button:Enable()
			self.buttonCover:Enable()
			self.label:SetTextColor(1, .82, 0)
			self.text:SetTextColor(1, 1, 1)
		end
	end

	---@param self EPDropdown
	local function ClearFocus(self)
		if self.open then
			self.pullout:Close()
		end
	end

	---@param self EPDropdown
	---@param text string
	local function SetText(self, text)
		self.text:SetText(text or "")
	end

	---@param self EPDropdown
	---@param text string?
	local function SetLabel(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -14)
			self:SetHeight(40)
		else
			self.label:SetText("")
			self.label:Hide()
			self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -15, 0)
			self:SetHeight(26)
		end
	end

	---@param self EPDropdown
	---@param value any
	local function SetValue(self, value)
		local text = self:FindItemText(value) or ""
		self:SetText(text)
		self.value = value
	end

	---@param self EPDropdown
	---@return unknown
	local function GetValue(self)
		return self.value
	end

	---@param self EPDropdown
	---@param item any
	---@param value any
	local function SetItemValue(self, item, value)
		if not self.multiselect then return end
		for _, pulloutItem in self.pullout:IterateItems() do
			if pulloutItem:GetUserDataTable().value == item then
				pulloutItem:SetValue(value)
			end
		end
		ShowMultiText(self)
	end

	---@param self EPDropdown
	---@param itemValue any
	---@param disabled any
	local function SetItemDisabled(self, itemValue, disabled)
		for _, pulloutItem in self.pullout:IterateItems() do
			if pulloutItem:GetUserDataTable().value == itemValue then
				pulloutItem:SetDisabled(disabled)
			end
		end
	end

	---@param self EPDropdown
	---@param itemValue any the internal value used to index an item
	---@param text string the value shown on the item
	---@param itemType EPDropdownItemMenuType|EPDropdownItemToggleType type of item to create
	---@param dropdownItemData? table<integer, DropdownItemData> optional table of nested dropdown item menus
	---@param neverShowItemsAsSelected? boolean
	local function AddItem(self, itemValue, text, itemType, dropdownItemData, neverShowItemsAsSelected)
		local exists = AceGUI:GetWidgetVersion(itemType)
		if not exists then
			error(("The given item type, %q, does not"):format(tostring(itemType)), 2)
			return
		end

		if itemType == "EPDropdownItemMenu" then
			local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
			dropdownMenuItem:GetUserDataTable().obj = self
			dropdownMenuItem:GetUserDataTable().value = itemValue
			dropdownMenuItem:SetText(text)
			dropdownMenuItem:SetCallback("OnValueChanged", HandleMenuItemValueChanged)
			self.pullout:AddItem(dropdownMenuItem)
			if neverShowItemsAsSelected == true then
				dropdownMenuItem:SetNeverShowItemsAsSelected(true)
			end
			if dropdownItemData then
				dropdownMenuItem:SetMenuItems(dropdownItemData, self)
			end
		elseif itemType == "EPDropdownItemToggle" then
			local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
			dropdownItemToggle:GetUserDataTable().obj = self
			dropdownItemToggle:GetUserDataTable().value = itemValue
			dropdownItemToggle:SetText(text)
			dropdownItemToggle:SetCallback("OnValueChanged", HandleItemValueChanged)
			self.pullout:AddItem(dropdownItemToggle)
		end
	end

	---@param self EPDropdown
	---@param dropdownItemData table<integer, DropdownItemData|string> table describing items to add
	---@param leafType EPDropdownItemMenuType|EPDropdownItemToggleType the type of item to create for leaf items
	local function AddItems(self, dropdownItemData, leafType)
		for index, itemData in ipairs(dropdownItemData) do
			DevTool:AddData(itemData)
			if type(itemData) == "string" then
				self:AddItem(index, itemData, leafType)
			elseif type(itemData) == "table" and #itemData.dropdownItemMenuData > 0 then
				self:AddItem(itemData.itemValue, itemData.text, "EPDropdownItemMenu", itemData.dropdownItemMenuData)
			else
				self:AddItem(itemData.itemValue, itemData.text, leafType)
			end
		end
	end

	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	---@param dropdownItemData table<integer, DropdownItemData> table of nested dropdown item data
	local function AddItemsToExistingDropdownItemMenu(self, existingItemValue, dropdownItemData)
		local existingDropdownMenuItem = FindItemFromValue(self, existingItemValue)
		if existingDropdownMenuItem then
			existingDropdownMenuItem:AddMenuItems(dropdownItemData, self)
		end
	end

	---@param self EPDropdown
	local function AddCloseButton(self)
		-- if not self.hasClose then
		-- 	local close = AceGUI:Create("Dropdown-Item-Execute") --[[@as EPItemBase]]
		-- 	close:SetText("Close")
		-- 	self.pullout:AddItem(close)
		-- 	self.hasClose = true
		-- end
	end

	---@param self EPDropdown
	---@param multi any
	local function SetMultiselect(self, multi)
		self.multiselect = multi
		if multi then
			ShowMultiText(self)
			self:AddCloseButton()
		end
	end

	---@param self EPDropdown
	---@return unknown
	local function GetMultiselect(self)
		return self.multiselect
	end

	---@param self EPDropdown
	---@param width any
	local function SetPulloutWidth(self, width)
		self.pulloutWidth = width
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		frame:SetBackdrop(dropdownBackdrop)
		frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		frame:SetScript("OnHide", HandleDropdownHide)

		local dropdown = CreateFrame("Frame", Type .. count, frame, "UIDropDownMenuTemplate")
		dropdown:ClearAllPoints()
		dropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		dropdown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		dropdown:SetScript("OnHide", nil)

		local left = _G[dropdown:GetName() .. "Left"]
		local middle = _G[dropdown:GetName() .. "Middle"]
		local right = _G[dropdown:GetName() .. "Right"]

		left:ClearAllPoints()
		middle:ClearAllPoints()
		right:ClearAllPoints()
		left:Hide()
		middle:Hide()
		right:Hide()

		local button = _G[dropdown:GetName() .. "Button"]
		button:ClearAllPoints()
		button:SetPoint("RIGHT", frame, "RIGHT")
		button:SetScript("OnEnter", HandleButtonEnter)
		button:SetScript("OnLeave", HandleButtonLeave)
		button:SetScript("OnClick", HandleToggleDropdownPullout)
		button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])

		local buttonCover = CreateFrame("Button", nil, frame)
		buttonCover:SetPoint("LEFT", frame, "LEFT")
		buttonCover:SetPoint("RIGHT", frame, "RIGHT")
		buttonCover:SetScript("OnEnter", HandleButtonEnter)
		buttonCover:SetScript("OnLeave", HandleButtonLeave)
		buttonCover:SetScript("OnClick", HandleToggleDropdownPullout)

		local text = _G[dropdown:GetName() .. "Text"]
		text:ClearAllPoints()

		text:SetPoint("LEFT", frame, "LEFT", textOffsetX, 0)
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		if fPath then text:SetFont(fPath, fontSize) end

		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		if fPath then label:SetFont(fPath, fontSize) end
		label:SetPoint("LEFT", frame, "LEFT", 0, 0)
		label:SetHeight(18)
		label:Hide()

		---@class EPDropdown
		local widget    = {
			OnAcquire                          = OnAcquire,
			OnRelease                          = OnRelease,
			SetDisabled                        = SetDisabled,
			ClearFocus                         = ClearFocus,
			FindItemText                       = FindItemText,
			SetText                            = SetText,
			SetLabel                           = SetLabel,
			SetValue                           = SetValue,
			GetValue                           = GetValue,
			SetItemValue                       = SetItemValue,
			SetItemDisabled                    = SetItemDisabled,
			AddItem                            = AddItem,
			AddItems                           = AddItems,
			AddItemsToExistingDropdownItemMenu = AddItemsToExistingDropdownItemMenu,
			AddCloseButton                     = AddCloseButton,
			SetMultiselect                     = SetMultiselect,
			GetMultiselect                     = GetMultiselect,
			SetPulloutWidth                    = SetPulloutWidth,
			frame                              = frame,
			type                               = Type,
			count                              = count,
			dropdown                           = dropdown,
			text                               = text,
			label                              = label,
			buttonCover                        = buttonCover,
			button                             = button,
		}

		frame.obj       = widget
		dropdown.obj    = widget
		text.obj        = widget
		buttonCover.obj = widget
		button.obj      = widget

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
