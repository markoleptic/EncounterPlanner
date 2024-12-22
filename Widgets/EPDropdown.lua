local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
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

local textOffsetX = 4
local fontSize = 14
local defaultDropdownItemHeight = 24
local minimumPulloutWidth = 40
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
	local defaultWidth = 200
	local defaultMaxItems = 13

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

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(pulloutBackdrop)
		frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(defaultWidth)
		frame:SetHeight(defaultDropdownItemHeight)

		local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetToplevel(true)
		scrollFrame:SetFrameStrata("FULLSCREEN_DIALOG")

		local itemFrame = CreateFrame("Frame", Type .. "ItemFrame" .. count, scrollFrame)
		itemFrame:SetWidth(defaultWidth)
		itemFrame:SetToplevel(true)
		itemFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		scrollFrame:SetScrollChild(itemFrame)
		itemFrame:SetPoint("TOPLEFT")

		local scrollIndicatorFrame =
			CreateFrame("Frame", Type .. "ScrollIndicatorFrame" .. count, frame, "BackdropTemplate")
		scrollIndicatorFrame:SetBackdrop(pulloutBackdrop)
		scrollIndicatorFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
		scrollIndicatorFrame:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
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
	---@field pullout EPDropdownPullout
	---@field value any|nil
	---@field open boolean|nil
	---@field hasClose boolean|nil
	---@field disabled boolean|nil
	---@field multiselect boolean|nil
	---@field pulloutWidth number
	---@field dropdownItemHeight number
	---@field obj any|nil

	local Type = "EPDropdown"
	local Version = 1

	local function HandleDropdownHide(frame)
		local self = frame.obj --[[@as EPDropdown]]
		if self.open then
			self.pullout:Close()
		end
	end

	local function HandleButtonEnter(frame)
		local self = frame.obj --[[@as EPDropdown]]
		self.button:LockHighlight()
		self:Fire("OnEnter")
	end

	local function HandleButtonLeave(frame)
		local self = frame.obj --[[@as EPDropdown]]
		self.button:UnlockHighlight()
		self:Fire("OnLeave")
	end

	---@param frame EPDropdownPullout
	local function HandleToggleDropdownPullout(frame)
		local self = frame.obj --[[@as EPDropdown]]
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
			self:Fire("OnValueChanged", dropdownItem:GetValue(), selected)
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
		if self.multiselect then
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
		self.dropdownItemHeight = defaultDropdownItemHeight
		self.pullout = AceGUI:Create("EPDropdownPullout")
		self.pullout:GetUserDataTable().obj = self
		self.pullout:SetCallback("OnClose", HandlePulloutClose)
		self.pullout:SetCallback("OnOpen", HandlePulloutOpen)
		self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		self.pullout:SetAutoWidth(true)
		FixLevels(self.pullout.frame, self.pullout.frame:GetChildren())

		self:SetTextCentered(false)
		self:SetHeight(self.dropdownItemHeight)
		self:SetWidth(200)
		self:SetPulloutWidth(nil)
		self:SetButtonVisibility(true)
		self.frame:Show()
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
		else
			self.button:Enable()
			self.buttonCover:Enable()
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
	---@param disabled any
	local function SetItemDisabled(self, itemValue, disabled)
		for _, pulloutItem in ipairs(self.pullout.items) do
			if pulloutItem:GetValue() == itemValue then
				pulloutItem:SetDisabled(disabled)
			end
		end
	end

	---@param self EPDropdown
	---@param itemValuesToSelect table<any, boolean>
	local function SetSelectedItems(self, itemValuesToSelect)
		for _, pulloutItem in ipairs(self.pullout.items) do
			pulloutItem:SetIsSelected(itemValuesToSelect[pulloutItem:GetValue()] == true)
		end
	end

	---@param self EPDropdown
	---@param itemValue any
	---@param selected boolean
	local function SetItemIsSelected(self, itemValue, selected)
		for _, pulloutItem in ipairs(self.pullout.items) do
			if pulloutItem:GetValue() == itemValue then
				pulloutItem:SetIsSelected(selected)
				break
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
						neverShowItemsAsSelected
					)
				else
					self:AddItem(itemData.itemValue, itemData.text, leafType, nil, neverShowItemsAsSelected)
				end
			end
		end
	end

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
		else
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

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(dropdownBackdrop)
		frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
		frame:SetScript("OnHide", HandleDropdownHide)

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

		local buttonCover = CreateFrame("Button", Type .. "ButtonCover" .. count, frame)
		buttonCover:SetFrameLevel(button:GetFrameLevel() + 1)
		buttonCover:SetPoint("TOPLEFT", frame, "TOPLEFT")
		buttonCover:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		buttonCover:SetScript("OnEnter", HandleButtonEnter)
		buttonCover:SetScript("OnLeave", HandleButtonLeave)
		buttonCover:SetScript("OnClick", HandleToggleDropdownPullout)

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
			SetDisabled = SetDisabled,
			ClearFocus = ClearFocus,
			FindItemAndText = FindItemAndText,
			SetText = SetText,
			SetTextCentered = SetTextCentered,
			SetValue = SetValue,
			GetValue = GetValue,
			SetItemDisabled = SetItemDisabled,
			AddItem = AddItem,
			RemoveItem = RemoveItem,
			AddItems = AddItems,
			EditItemText = EditItemText,
			SetDropdownItemHeight = SetDropdownItemHeight,
			AddItemsToExistingDropdownItemMenu = AddItemsToExistingDropdownItemMenu,
			GetItemsFromDropdownItemMenu = GetItemsFromDropdownItemMenu,
			RemoveItemsFromExistingDropdownItemMenu = RemoveItemsFromExistingDropdownItemMenu,
			SetMultiselect = SetMultiselect,
			GetMultiselect = GetMultiselect,
			SetPulloutWidth = SetPulloutWidth,
			SetSelectedItems = SetSelectedItems,
			SetItemIsSelected = SetItemIsSelected,
			SetButtonVisibility = SetButtonVisibility,
			SetAutoItemWidth = SetAutoItemWidth,
			Clear = Clear,
			frame = frame,
			type = Type,
			count = count,
			dropdown = dropdown,
			text = text,
			buttonCover = buttonCover,
			button = button,
		}

		frame.obj = widget
		dropdown.obj = widget
		text.obj = widget
		buttonCover.obj = widget
		button.obj = widget

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
