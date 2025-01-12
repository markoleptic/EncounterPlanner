local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local abs = math.abs
local CreateFrame = CreateFrame
local floor = math.floor
local ipairs = ipairs
local max = math.max
local min = math.min
local pairs = pairs
local select = select
local tinsert = tinsert
local tremove = tremove
local type = type
local unpack = unpack

local textOffsetX = 4
local defaultHorizontalItemPadding = 4
local fontSize = 14
local defaultDropdownItemHeight = 24
local minimumPulloutWidth = 40
local pulloutBackdropColor = { 0.1, 0.1, 0.1, 1 }
local pulloutBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local dropdownBackdropColor = { 0.1, 0.1, 0.1, 1 }
local dropdownBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local dropdownButtonCoverColor = { 0.25, 0.25, 0.5, 0.5 }
local disabledTextColor = { 0.5, 0.5, 0.5, 1 }
local enabledTextColor = { 1, 1, 1, 1 }
local defaultDropdownWidth = 200
local defaultPulloutWidth = 200
local defaultMaxItems = 13

local pulloutBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}
local dropdownBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
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

local function FixStrata(strata, parent, ...)
	local i = 1
	local child = select(i, ...)
	parent:SetFrameStrata(strata)
	while child do
		FixStrata(strata, child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

---@class DropdownItemData
---@field itemValue string|number the internal value used to index a dropdown item
---@field text string the value shown in the dropdown
---@field dropdownItemMenuData table<integer, DropdownItemData>|nil nested dropdown item menus
---@field selectable? boolean

do
	---@class EPDropdownPullout : AceGUIWidget
	---@field frame table|BackdropTemplate|Frame
	---@field scrollFrame ScrollFrame
	---@field itemFrame table|Frame
	---@field type string
	---@field count integer
	---@field maxHeight number
	---@field items table<integer, EPDropdownItemToggle|EPDropdownItemMenu>
	---@field dropdownItemHeight number
	---@field autoWidth boolean

	local Type = "EPDropdownPullout"
	local Version = 1

	---@param self EPDropdownPullout
	local function OnAcquire(self)
		self.dropdownItemHeight = defaultDropdownItemHeight
		self.scrollIndicatorFrame:SetHeight(defaultDropdownItemHeight / 2 - 2)
		self.frame:SetParent(UIParent)
		self.autoWidth = false
	end

	---@param self EPDropdownPullout
	local function OnRelease(self)
		self:Clear()
		self.scrollIndicatorFrame:Hide()
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	---@param item EPDropdownItemToggle|EPDropdownItemMenu
	local function OnEnter(item)
		local self = item.parentPullout
		for k, v in ipairs(self.items) do
			if v.CloseMenu and v ~= item then
				v--[[@as EPDropdownItemMenu]]:CloseMenu()
			end
		end
	end

	---@param self EPDropdownPullout
	---@param item EPDropdownItemToggle|EPDropdownItemMenu
	local function AddItem(self, item)
		self.items[#self.items + 1] = item
		item:SetHeight(self.dropdownItemHeight)
		local h = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h, self.maxHeight))
		item.frame:SetPoint("LEFT", self.itemFrame, "LEFT")
		item.frame:SetPoint("RIGHT", self.itemFrame, "RIGHT")
		item:SetPullout(self)
		item:SetOnEnter(OnEnter)
	end

	---@param self EPDropdownPullout
	---@param item EPDropdownItemToggle|EPDropdownItemMenu
	---@param index integer
	local function InsertItem(self, item, index)
		tinsert(self.items, index, item)
		item:SetHeight(self.dropdownItemHeight)
		local h = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h, self.maxHeight))
		item.frame:SetPoint("LEFT", self.itemFrame, "LEFT")
		item.frame:SetPoint("RIGHT", self.itemFrame, "RIGHT")
		item:SetPullout(self)
		item:SetOnEnter(OnEnter)
	end

	---@param self EPDropdownPullout
	---@param value any
	local function RemoveItem(self, value)
		local items = self.items
		for i, item in pairs(items) do
			if item:GetUserDataTable().value == value then
				AceGUI:Release(item)
				tremove(items, i)
				break
			end
		end
		local h = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h, self.maxHeight))
	end

	---@param self EPDropdownPullout
	---@param point string
	---@param relFrame Frame|BackdropTemplate
	---@param relPoint string
	---@param x number
	---@param y number
	local function Open(self, point, relFrame, relPoint, x, y)
		local parent = self:GetUserDataTable().obj
		local maxItemWidth = minimumPulloutWidth
		if parent.type == "EPDropdown" then
			maxItemWidth = parent.frame:GetWidth()
		end
		self.frame:SetPoint(point, relFrame, relPoint, x, y)
		local height = 0
		for i, item in ipairs(self.items) do
			item:SetPoint("TOP", self.itemFrame, "TOP", 0, (i - 1) * -self.dropdownItemHeight)
			item:Show()
			height = height + self.dropdownItemHeight
			if self.autoWidth then
				local width = item.text:GetStringWidth() + item.textOffsetX * 2
				if item.childSelectedIndicator:IsShown() then
					width = width + item.childSelectedIndicator:GetWidth() + item.childSelectedIndicatorOffsetX
				elseif not item.neverShowItemsAsSelected then
					width = width + item.check:GetWidth() + item.checkOffsetX
				end
				maxItemWidth = max(maxItemWidth, width)
			end
		end

		self.itemFrame:SetHeight(height)

		if height > self.maxHeight then
			self.frame:SetHeight(self.maxHeight + self.dropdownItemHeight / 2.0)
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, self.dropdownItemHeight / 2.0)
			self.scrollIndicatorFrame:SetHeight(self.dropdownItemHeight / 2.0 - 1)
			self.scrollIndicator:SetSize(self.dropdownItemHeight / 2.0 - 1, self.dropdownItemHeight / 2.0 - 1)
			self.scrollIndicatorFrame:Show()
		else
			local h = #self.items * self.dropdownItemHeight
			self.frame:SetHeight(min(h, self.maxHeight))
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
			self.scrollIndicatorFrame:Hide()
		end

		if self.autoWidth then
			self.frame:SetWidth(maxItemWidth)
			self.itemFrame:SetWidth(maxItemWidth)
		end

		FixStrata("TOOLTIP", self.frame, self.frame:GetChildren())
		self.frame:Show()
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
	---@param height number
	local function SetMaxHeight(self, height)
		self.maxHeight = height or (defaultMaxItems * self.dropdownItemHeight)
		if self.frame:GetHeight() > height then
			self.frame:SetHeight(height)
		elseif (self.itemFrame:GetHeight()) < height then
			self.frame:SetHeight(self.itemFrame:GetHeight())
		end
	end

	---@param self EPDropdownPullout
	---@param auto boolean
	local function SetAutoWidth(self, auto)
		self.autoWidth = auto
	end

	---@param self EPDropdownPullout
	---@param height number
	local function SetItemHeight(self, height)
		if self.maxHeight == defaultMaxItems * self.dropdownItemHeight then
			self.maxHeight = defaultMaxItems * height
		end
		self.dropdownItemHeight = height
		for _, item in ipairs(self.items) do
			item:SetHeight(self.dropdownItemHeight)
		end
		local h = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h, self.maxHeight))
	end

	---@param self EPDropdownPullout
	---@param value number
	local function SetScroll(self, value)
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local itemFrameHeight = self.itemFrame:GetHeight()

		local maxVerticalScroll = itemFrameHeight - scrollFrameHeight
		local currentVerticalScroll = self.scrollFrame:GetVerticalScroll()
		local snapValue = self.dropdownItemHeight
		local currentSnapValue = floor((currentVerticalScroll / snapValue) + 0.5)

		if value > 0 then
			currentSnapValue = currentSnapValue - 1
		elseif value < 0 then
			currentSnapValue = currentSnapValue + 1
		end

		local newVerticalScroll = max(min(currentSnapValue * snapValue, maxVerticalScroll), 0)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)

		if maxVerticalScroll > 0 and abs(newVerticalScroll - maxVerticalScroll) > 0.1 then
			self.scrollIndicator:Show()
		else
			self.scrollIndicator:Hide()
		end
	end

	---@param self EPDropdownPullout
	local function FixScroll(self)
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local itemFrameHeight = self.itemFrame:GetHeight()
		local maxVerticalScroll = itemFrameHeight - scrollFrameHeight
		local currentVerticalScroll = self.scrollFrame:GetVerticalScroll()

		local newVerticalScroll = max(min(currentVerticalScroll, maxVerticalScroll), 0)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)
		self.itemFrame:SetWidth(self.scrollFrame:GetWidth())
	end

	local function Sort(self)
		sort(self.items, function(a, b)
			return a:GetUserDataTable().value < b:GetUserDataTable().value
		end)
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(pulloutBackdrop)
		frame:SetBackdropColor(unpack(pulloutBackdropColor))
		frame:SetBackdropBorderColor(unpack(pulloutBackdropBorderColor))
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(defaultPulloutWidth)
		frame:SetHeight(defaultDropdownItemHeight)

		local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetToplevel(true)
		scrollFrame:SetFrameStrata("FULLSCREEN_DIALOG")

		local itemFrame = CreateFrame("Frame", Type .. "ItemFrame" .. count, scrollFrame)
		itemFrame:SetWidth(defaultPulloutWidth)
		itemFrame:SetToplevel(true)
		itemFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		scrollFrame:SetScrollChild(itemFrame)
		itemFrame:SetPoint("TOPLEFT")

		local scrollIndicatorFrame =
			CreateFrame("Frame", Type .. "ScrollIndicatorFrame" .. count, frame, "BackdropTemplate")
		scrollIndicatorFrame:SetBackdrop(pulloutBackdrop)
		scrollIndicatorFrame:SetBackdropColor(unpack(pulloutBackdropColor))
		scrollIndicatorFrame:SetBackdropBorderColor(unpack(pulloutBackdropColor))
		local scrollIndicator = scrollIndicatorFrame:CreateTexture(nil, "OVERLAY")
		scrollIndicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
		scrollIndicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		scrollIndicator:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-sort-down-32]])
		scrollIndicator:SetPoint("CENTER")
		scrollIndicatorFrame:Hide()
		scrollFrame:Show()
		itemFrame:Show()

		---@class EPDropdownPullout
		local widget = {
			OnAcquire = OnAcquire,
			OnRelease = OnRelease,
			AddItem = AddItem,
			InsertItem = InsertItem,
			RemoveItem = RemoveItem,
			Open = Open,
			Close = Close,
			Clear = Clear,
			SetMaxHeight = SetMaxHeight,
			SetItemHeight = SetItemHeight,
			SetScroll = SetScroll,
			FixScroll = FixScroll,
			SetAutoWidth = SetAutoWidth,
			Sort = Sort,
			scrollIndicator = scrollIndicator,
			scrollIndicatorFrame = scrollIndicatorFrame,
			frame = frame,
			scrollFrame = scrollFrame,
			itemFrame = itemFrame,
			type = Type,
			count = count,
			maxHeight = defaultMaxItems * defaultDropdownItemHeight,
			items = {},
		}

		scrollFrame:SetScript("OnMouseWheel", function(_, delta)
			widget:SetScroll(delta)
		end)
		scrollFrame:SetScript("OnSizeChanged", function()
			widget:FixScroll()
		end)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
	---@class EPDropdown : AceGUIWidget
	---@field frame table|Frame
	---@field dropdown table|Frame
	---@field text FontString
	---@field slider table|BackdropTemplate|Slider
	---@field type string
	---@field count integer
	---@field buttonCover Button
	---@field button Button
	---@field enabled boolean
	---@field pullout EPDropdownPullout
	---@field lineEdit EPLineEdit|nil
	---@field value any|nil
	---@field open boolean|nil
	---@field hasClose boolean|nil
	---@field disabled boolean|nil
	---@field multiselect boolean|nil
	---@field pulloutWidth number
	---@field dropdownItemHeight number
	---@field obj any|nil
	---@field showHighlight boolean
	---@field itemTextFontSize number
	---@field itemHorizontalPadding number
	---@field textHorizontalPadding number

	local Type = "EPDropdown"
	local Version = 1

	---@param self EPDropdown
	local function HandleDropdownHide(self)
		if self.open then
			self.pullout:Close()
		end
	end

	---@param self EPDropdown
	local function HandleButtonEnter(self)
		if self.showHighlight and not self.open then
			local fadeOut = self.fadeOut
			if fadeOut:IsPlaying() then
				fadeOut:Stop()
			end
			self.fadeIn:Play()
		end
		self:Fire("OnEnter")
	end

	---@param self EPDropdown
	local function HandleButtonLeave(self)
		if self.showHighlight and not self.open then
			local fadeIn = self.fadeIn
			if fadeIn:IsPlaying() then
				fadeIn:Stop()
			end
			self.fadeOut:Play()
		end
		self:Fire("OnLeave")
	end

	---@param self EPDropdown
	local function HandleToggleDropdownPullout(self)
		if self.open then
			self.open = nil
			self.pullout:Close()
			AceGUI:ClearFocus()
		else
			self.open = true
			self.pullout:SetWidth(self.pulloutWidth or self.frame:GetWidth())
			self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, 1)
			AceGUI:SetFocus(self)
		end
	end

	---@param pullout EPDropdownPullout
	local function HandlePulloutOpen(pullout)
		local self = pullout:GetUserDataTable().obj --[[@as EPDropdown]]
		local value = self.value
		if not self.multiselect then
			for _, item in ipairs(pullout.items) do
				item:SetIsSelected(item:GetValue() == value)
			end
		end
		self.open = true
		self.button:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
		self:Fire("OnOpened")
	end

	---@param pullout EPDropdownPullout
	local function HandlePulloutClose(pullout)
		local self = pullout:GetUserDataTable().obj --[[@as EPDropdown]]
		self.open = nil
		self.button:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		if self.showHighlight then
			local fadeIn = self.fadeIn
			if fadeIn:IsPlaying() then
				fadeIn:Stop()
			end
			self.fadeOut:Play()
		end
		self:Fire("OnClosed")
	end

	---@param self EPDropdown
	---@param value any
	---@param includeNeverShowItemsAsSelectedItems boolean?
	---@return EPDropdownItemMenu|EPDropdownItemToggle|nil, string|nil
	local function FindItemAndText(self, value, includeNeverShowItemsAsSelectedItems)
		---@param items table<integer, EPDropdownItemToggle|EPDropdownItemMenu>
		local function searchItems(items)
			for _, item in ipairs(items) do
				if includeNeverShowItemsAsSelectedItems or not item.neverShowItemsAsSelected then
					if item:GetValue() == value then
						return item, item.text:GetText()
					end
					if item.childPullout and item.childPullout.items and #item.childPullout.items > 0 then
						local foundItem, foundText = searchItems(item.childPullout.items)
						if foundItem and foundText then
							return foundItem, foundText
						end
					end
				end
			end
		end
		return searchItems(self.pullout.items)
	end

	---@param dropdownItem EPDropdownItemMenu
	---@param _ string
	---@param selected boolean
	---@param value any
	local function HandleMenuItemValueChanged(dropdownItem, _, selected, value)
		local self = dropdownItem:GetUserDataTable().obj
		if self.multiselect then
			self:Fire("OnValueChanged", value, selected)
		else
			self:SetValue(value)
			self:Fire("OnValueChanged", value)
			if self.open then
				self.pullout:Close()
			end
		end
	end

	---@param dropdownItem EPDropdownItemToggle
	---@param _ string
	---@param selected boolean
	local function HandleItemValueChanged(dropdownItem, _, selected)
		local self = dropdownItem:GetUserDataTable().obj
		if self.multiselect and not dropdownItem.neverShowItemsAsSelected then
			self:Fire("OnValueChanged", dropdownItem:GetValue(), selected)
		else
			if selected then
				local newValue = dropdownItem:GetValue()
				self:SetValue(newValue)
				self:Fire("OnValueChanged", newValue)
			end
			if self.open then
				self.pullout:Close()
			end
		end
	end

	---@param self EPDropdown
	local function OnAcquire(self)
		self.showHighlight = false
		self.itemHorizontalPadding = defaultHorizontalItemPadding
		self.dropdownItemHeight = defaultDropdownItemHeight
		self.textHorizontalPadding = defaultHorizontalItemPadding
		self.pullout = AceGUI:Create("EPDropdownPullout")
		self.pullout:GetUserDataTable().obj = self
		self.pullout:SetCallback("OnClose", HandlePulloutClose)
		self.pullout:SetCallback("OnOpen", HandlePulloutOpen)
		self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		self.pullout:SetAutoWidth(true)
		FixLevels(self.pullout.frame, self.pullout.frame:GetChildren())

		self:SetTextFontSize(fontSize)
		self:SetItemTextFontSize(fontSize)
		self:SetTextCentered(false)
		self:SetHeight(self.dropdownItemHeight)
		self:SetWidth(defaultDropdownWidth)
		self:SetPulloutWidth(nil)
		self:SetButtonVisibility(true)
		self:SetEnabled(true)
		self.frame:Show()
	end

	---@param self EPDropdown
	local function OnRelease(self)
		if self.lineEdit then
			self.lineEdit:Release()
		end

		self.lineEdit = nil
		if self.open then
			self.pullout:Close()
		end

		AceGUI:Release(self.pullout)
		self.pullout = nil

		self:SetText("")
		self:SetEnabled(true)
		self:SetMultiselect(false)

		self.value = nil
		self.open = nil
		self.hasClose = nil

		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	---@param self EPDropdown
	---@param enabled boolean
	local function SetEnabled(self, enabled)
		self.enabled = enabled
		if enabled then
			self.button:Enable()
			self.buttonCover:Enable()
			self.text:SetTextColor(unpack(enabledTextColor))
		else
			self.button:Disable()
			self.buttonCover:Disable()
			self.text:SetTextColor(unpack(disabledTextColor))
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
	---@param center boolean
	local function SetTextCentered(self, center)
		if center then
			self.text:SetJustifyH("CENTER")
		else
			self.text:SetJustifyH("LEFT")
		end
	end

	---@param self EPDropdown
	---@param value any
	local function SetValue(self, value)
		local item, text = self:FindItemAndText(value)
		while item do -- Follow chain of parents up to dropdown
			local menuItemParent = item:GetUserDataTable().parentItemMenu
			if not menuItemParent then
				break
			end
			menuItemParent:SetChildValue(value)
			menuItemParent:SetIsSelectedBasedOnChildValue()
			item = menuItemParent
		end
		if not text then
			text = ""
		end
		self:SetText(text)
		self.value = value
	end

	---@param self EPDropdown
	---@return any
	local function GetValue(self)
		return self.value
	end

	-- Only works for non-nested dropdowns
	---@param self EPDropdown
	---@param currentValue any
	---@param newValue any
	---@param newText string
	local function EditItemText(self, currentValue, newValue, newText)
		for _, pulloutItem in ipairs(self.pullout.items) do
			if pulloutItem:GetValue() == currentValue then
				pulloutItem:SetValue(newValue)
				pulloutItem:SetText(newText)
				self:SetValue(newValue)
			end
		end
	end

	---@param self EPDropdown
	---@param itemValue any
	---@param enabled boolean
	local function SetItemEnabled(self, itemValue, enabled)
		for _, pulloutItem in ipairs(self.pullout.items) do
			if pulloutItem:GetValue() == itemValue then
				pulloutItem:SetEnabled(enabled)
			end
		end
	end

	---@param self EPDropdown
	---@param itemValuesToSelect table<any, boolean>
	---@param existingItemValue? any If specified, the dropdown item menu matching this value is searched for and its children are used for selection.
	local function SetSelectedItems(self, itemValuesToSelect, existingItemValue)
		if existingItemValue then
			local existingDropdownMenuItem, _ = FindItemAndText(self, existingItemValue, true)
			if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
				for _, pulloutItem in ipairs(existingDropdownMenuItem.childPullout.items) do
					pulloutItem:SetIsSelected(itemValuesToSelect[pulloutItem:GetValue()] == true)
				end
			end
		else
			for _, pulloutItem in ipairs(self.pullout.items) do
				pulloutItem:SetIsSelected(itemValuesToSelect[pulloutItem:GetValue()] == true)
			end
		end
	end

	---@param self EPDropdown
	---@param itemValue any
	---@param selected boolean
	---@param searchMenuItems? boolean If specified, all nested children are searched.
	local function SetItemIsSelected(self, itemValue, selected, searchMenuItems)
		if searchMenuItems then
			local existingPulloutItem, _ = FindItemAndText(self, itemValue, true)
			if existingPulloutItem then
				existingPulloutItem:SetIsSelected(selected)
			end
		else
			for _, pulloutItem in ipairs(self.pullout.items) do
				if pulloutItem:GetValue() == itemValue then
					pulloutItem:SetIsSelected(selected)
					break
				end
			end
		end
	end

	---@param self EPDropdown
	---@param itemValue any the internal value used to index an item
	---@param text string the value shown on the item
	---@param itemType EPDropdownItemMenuType|EPDropdownItemToggleType type of item to create
	---@param dropdownItemData table<integer, DropdownItemData>? optional table of nested dropdown item menus
	---@param neverShowItemsAsSelected boolean?
	local function AddItem(self, itemValue, text, itemType, dropdownItemData, neverShowItemsAsSelected)
		local exists = AceGUI:GetWidgetVersion(itemType)
		if not exists then
			error(("The given item type, %q, does not"):format(tostring(itemType)), 2)
			return
		end

		if itemType == "EPDropdownItemMenu" then
			local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
			dropdownMenuItem:GetUserDataTable().obj = self
			dropdownMenuItem:SetValue(itemValue)
			dropdownMenuItem:SetText(text)
			dropdownMenuItem:SetFontSize(self.itemTextFontSize)
			dropdownMenuItem:SetHorizontalPadding(self.itemHorizontalPadding)
			dropdownMenuItem:SetMultiselect(self.multiselect)
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
			dropdownItemToggle:SetValue(itemValue)
			dropdownItemToggle:SetText(text)
			dropdownItemToggle:SetFontSize(self.itemTextFontSize)
			dropdownItemToggle:SetHorizontalPadding(self.itemHorizontalPadding)
			dropdownItemToggle:SetCallback("OnValueChanged", HandleItemValueChanged)
			self.pullout:AddItem(dropdownItemToggle)
			if neverShowItemsAsSelected == true then
				dropdownItemToggle:SetNeverShowItemsAsSelected(true)
			end
		end
	end

	---@param self EPDropdown
	---@param itemValue any the internal value used to index an item
	local function RemoveItem(self, itemValue)
		local item, _ = FindItemAndText(self, itemValue, true)
		if item then
			item.parentPullout:RemoveItem(itemValue)
		end
	end

	---@param self EPDropdown
	local function Clear(self)
		self:ClearFocus()
		self.pullout:Clear()
		self.value = nil
		self:SetText("")
	end

	---@param self EPDropdown
	---@param dropdownItemData table<integer, DropdownItemData|string> table describing items to add
	---@param leafType EPDropdownItemMenuType|EPDropdownItemToggleType the type of item to create for leaf items
	---@param neverShowItemsAsSelected boolean? If true, items will not be selectable
	local function AddItems(self, dropdownItemData, leafType, neverShowItemsAsSelected)
		for index, itemData in ipairs(dropdownItemData) do
			if type(itemData) == "string" then
				self:AddItem(index, itemData, leafType)
			elseif type(itemData) == "table" then
				if type(itemData.dropdownItemMenuData) == "table" and #itemData.dropdownItemMenuData > 0 then
					self:AddItem(
						itemData.itemValue,
						itemData.text,
						"EPDropdownItemMenu",
						itemData.dropdownItemMenuData,
						neverShowItemsAsSelected or itemData.selectable == false
					)
				else
					self:AddItem(
						itemData.itemValue,
						itemData.text,
						leafType,
						nil,
						neverShowItemsAsSelected or itemData.selectable == false
					)
				end
			end
		end
	end

	-- Adds items to an existing dropdown menu item.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	---@param dropdownItemData table<integer, DropdownItemData> table of dropdown item data
	---@param index integer? item index to insert into
	local function AddItemsToExistingDropdownItemMenu(self, existingItemValue, dropdownItemData, index)
		local existingDropdownMenuItem, _ = FindItemAndText(self, existingItemValue, true)
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			existingDropdownMenuItem--[[@as EPDropdownItemMenu]]:AddMenuItems(dropdownItemData, self, index)
		end
	end

	-- Removes items from a dropdown menu item's immediate children.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	---@param dropdownItemData table<integer, DropdownItemData> table of dropdown item data
	local function RemoveItemsFromExistingDropdownItemMenu(self, existingItemValue, dropdownItemData)
		local existingDropdownMenuItem, _ = FindItemAndText(self, existingItemValue, true)
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			for _, data in ipairs(dropdownItemData) do
				existingDropdownMenuItem.childPullout:RemoveItem(data.itemValue)
			end
		end
	end

	-- Returns a list of a dropdown item menu's immediate child values.
	---@param self EPDropdown
	---@param itemValue any the internal value used to index an item
	---@return table<integer, DropdownItemData>
	local function GetItemsFromDropdownItemMenu(self, itemValue)
		local existingDropdownMenuItem, _ = FindItemAndText(self, itemValue, true)
		local dropdownItemData = {}
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			for _, item in pairs(existingDropdownMenuItem.childPullout.items) do
				tinsert(dropdownItemData, { itemValue = item:GetValue(), text = item:GetText() })
			end
		end
		return dropdownItemData
	end

	-- Clears all children from an existing dropdown item menu.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	local function ClearExistingDropdownItemMenu(self, existingItemValue)
		local existingDropdownMenuItem, _ = FindItemAndText(self, existingItemValue, true)
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			existingDropdownMenuItem--[[@as EPDropdownItemMenu]]:Clear()
		end
	end

	---@param self EPDropdown
	---@param multi any
	local function SetMultiselect(self, multi)
		self.multiselect = multi
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

	---@param self EPDropdown
	---@param height number
	local function SetDropdownItemHeight(self, height)
		self.dropdownItemHeight = height
		self:SetHeight(height)
		self.pullout:SetItemHeight(height)
	end

	---@param self EPDropdown
	---@param visible boolean
	local function SetButtonVisibility(self, visible)
		if visible then
			self.button:Show()
			self.text:SetPoint("RIGHT", self.button, "LEFT", -textOffsetX / 2, 0)
		else
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -textOffsetX, 0)
			self.button:Hide()
		end
	end

	---@param self EPDropdown
	---@param auto boolean
	local function SetAutoItemWidth(self, auto)
		self.pullout:SetAutoWidth(auto)

		local function SearchItems(items)
			for _, item in ipairs(items) do
				if item.type == "EPDropdownItemMenu" then
					item.childPullout:SetAutoWidth(auto)
					SearchItems(item.childPullout.items)
				end
			end
		end
		SearchItems(self.pullout.items)
	end

	---@param self EPDropdown
	---@param show boolean
	local function SetShowHighlight(self, show)
		self.showHighlight = show
	end

	---@param self EPDropdown
	local function Open(self)
		if not self.open then
			HandleToggleDropdownPullout(self)
		end
	end

	---@param self EPDropdown
	local function Close(self)
		if self.open then
			HandleToggleDropdownPullout(self)
		end
	end

	---@param self EPDropdown
	---@param size integer
	local function SetTextFontSize(self, size)
		local font, _, flags = self.text:GetFont()
		if font then
			self.text:SetFont(font, size, flags)
		end
	end

	---@param self EPDropdown
	---@param size integer
	local function SetItemTextFontSize(self, size)
		self.itemTextFontSize = size
	end

	---@param self EPDropdown
	---@param size integer
	local function SetTextHorizontalPadding(self, size)
		self.textHorizontalPadding = size
		self.text:SetPoint("LEFT", self.frame, "LEFT", self.textHorizontalPadding, 0)
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.textHorizontalPadding, 0)
	end

	---@param self EPDropdown
	---@param size integer
	local function SetItemHorizontalPadding(self, size)
		self.itemHorizontalPadding = size
	end

	-- Sorts the immediate children of the pullout.
	---@param self EPDropdown
	local function Sort(self)
		self.pullout:Sort()
	end

	---@param self EPDropdown
	---@param use boolean
	local function SetUseLineEditForDoubleClick(self, use)
		if not self.lineEdit and use then
			self.lineEdit = AceGUI:Create("EPLineEdit")
			local font, size, flags = self.text:GetFont()
			if font then
				self.lineEdit:SetFont(font, size, flags)
			end
			self.lineEdit:SetTextInsets(self.textHorizontalPadding, self.textHorizontalPadding, 0, 0)
			self.lineEdit.frame:SetParent(self.buttonCover)
			self.lineEdit.frame:SetPoint("TOPLEFT")
			self.lineEdit.frame:SetPoint("BOTTOMRIGHT")
			self.lineEdit:SetCallback("OnTextSubmitted", function(_, _, text)
				self:Fire("OnLineEditTextSubmitted", text)
				AceGUI:ClearFocus()
				self.lineEdit.frame:Hide()
			end)
			self.lineEdit.frame:Hide()
		elseif self.lineEdit and not use then
			self.lineEdit:Release()
			self.lineEdit = nil
		end
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(dropdownBackdrop)
		frame:SetBackdropColor(unpack(dropdownBackdropColor))
		frame:SetBackdropBorderColor(unpack(dropdownBackdropBorderColor))

		local dropdown = CreateFrame("Frame", Type .. "Dropdown" .. count, frame, "UIDropDownMenuTemplate")
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
		button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetDisabledTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:GetDisabledTexture():SetVertexColor(unpack(disabledTextColor))

		local buttonCover = CreateFrame("Button", Type .. "ButtonCover" .. count, frame)
		buttonCover:SetFrameLevel(button:GetFrameLevel() + 1)
		buttonCover:SetPoint("TOPLEFT")
		buttonCover:SetPoint("BOTTOMRIGHT")

		local background = dropdown:CreateTexture(Type .. "Background" .. count, "BORDER")
		background:SetPoint("TOPLEFT", buttonCover)
		background:SetPoint("BOTTOMRIGHT", buttonCover)
		background:SetColorTexture(unpack(dropdownButtonCoverColor))
		background:Hide()

		local fadeInGroup = background:CreateAnimationGroup()
		fadeInGroup:SetScript("OnPlay", function()
			background:Show()
		end)
		local fadeIn = fadeInGroup:CreateAnimation("Alpha")
		fadeIn:SetFromAlpha(0)
		fadeIn:SetToAlpha(1)
		fadeIn:SetDuration(0.4)
		fadeIn:SetSmoothing("OUT")

		local fadeOutGroup = background:CreateAnimationGroup()
		fadeOutGroup:SetScript("OnFinished", function()
			background:Hide()
		end)
		local fadeOut = fadeOutGroup:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(0.3)
		fadeOut:SetSmoothing("OUT")

		local text = _G[dropdown:GetName() .. "Text"]
		text:ClearAllPoints()
		text:SetPoint("LEFT", frame, "LEFT", textOffsetX, 0)
		text:SetPoint("RIGHT", frame, "RIGHT", -textOffsetX, 0)
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		if fPath then
			text:SetFont(fPath, fontSize)
		end
		text:SetWordWrap(false)

		---@class EPDropdown
		local widget = {
			OnAcquire = OnAcquire,
			OnRelease = OnRelease,
			SetEnabled = SetEnabled,
			ClearFocus = ClearFocus,
			FindItemAndText = FindItemAndText,
			SetText = SetText,
			SetTextCentered = SetTextCentered,
			SetValue = SetValue,
			GetValue = GetValue,
			SetItemEnabled = SetItemEnabled,
			AddItem = AddItem,
			RemoveItem = RemoveItem,
			AddItems = AddItems,
			EditItemText = EditItemText,
			SetDropdownItemHeight = SetDropdownItemHeight,
			AddItemsToExistingDropdownItemMenu = AddItemsToExistingDropdownItemMenu,
			GetItemsFromDropdownItemMenu = GetItemsFromDropdownItemMenu,
			RemoveItemsFromExistingDropdownItemMenu = RemoveItemsFromExistingDropdownItemMenu,
			ClearExistingDropdownItemMenu = ClearExistingDropdownItemMenu,
			SetMultiselect = SetMultiselect,
			GetMultiselect = GetMultiselect,
			SetPulloutWidth = SetPulloutWidth,
			SetSelectedItems = SetSelectedItems,
			SetItemIsSelected = SetItemIsSelected,
			SetButtonVisibility = SetButtonVisibility,
			SetAutoItemWidth = SetAutoItemWidth,
			SetShowHighlight = SetShowHighlight,
			Open = Open,
			Close = Close,
			Clear = Clear,
			Sort = Sort,
			SetTextFontSize = SetTextFontSize,
			SetItemTextFontSize = SetItemTextFontSize,
			SetTextHorizontalPadding = SetTextHorizontalPadding,
			SetItemHorizontalPadding = SetItemHorizontalPadding,
			SetUseLineEditForDoubleClick = SetUseLineEditForDoubleClick,
			frame = frame,
			type = Type,
			count = count,
			dropdown = dropdown,
			text = text,
			buttonCover = buttonCover,
			button = button,
			background = background,
			fadeIn = fadeInGroup,
			fadeOut = fadeOutGroup,
		}

		buttonCover:SetScript("OnEnter", function()
			HandleButtonEnter(widget)
		end)
		buttonCover:SetScript("OnLeave", function()
			HandleButtonLeave(widget)
		end)
		buttonCover:SetScript("OnDoubleClick", function()
			if widget.lineEdit then
				widget:Close()
				widget.lineEdit:SetText(widget.text:GetText())
				widget.lineEdit.frame:Show()
				widget.lineEdit:SetFocus()
			end
		end)
		buttonCover:SetScript("OnClick", function()
			if #widget.pullout.items == 0 then
				widget:Fire("Clicked")
			end
			HandleToggleDropdownPullout(widget)
		end)
		frame:SetScript("OnHide", function()
			HandleDropdownHide(widget)
		end)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
