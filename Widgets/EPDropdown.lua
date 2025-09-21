local _, Namespace = ...

---@class Private
local Private = Namespace

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
local sort = table.sort
local tinsert = table.insert
local tremove = table.remove
local type = type
local unpack = unpack

local k = {
	DefaultDropdownItemHeight = 24,
	DefaultDropdownWidth = 200,
	DefaultHorizontalItemPadding = 4,
	DefaultMaxItems = 13,
	DefaultPulloutWidth = 200,
	DisabledTextColor = Private.constants.colors.kDisabledTextColor,
	DropdownBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 1,
	},
	DropdownBackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	DropdownBackdropColor = { 0.1, 0.1, 0.1, 1 },
	DropdownTexture = Private.constants.textures.kDropdown,
	EnabledTextColor = Private.constants.colors.kEnabledTextColor,
	FontSize = 14,
	MinimumPulloutWidth = 100,
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	PulloutBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 1,
	},
	PulloutBackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	PulloutBackdropColor = { 0.1, 0.1, 0.1, 1 },
	RegexIconText = Private.constants.kRegexIconText,
	RightArrow = " |T" .. Private.constants.textures.kRightArrow .. ":16|t ",
	SortDownTexture = Private.constants.textures.kSortDown,
}
k.EdgeSize = k.DropdownBackdrop.edgeSize

---@param parent Frame
---@param ... [Frame]
local function FixLevels(parent, ...)
	local i = 1
	local child = select(i, ...)
	---@cast child Frame
	while child do
		child:SetFrameLevel(parent:GetFrameLevel() + 1)
		FixLevels(child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

---@param strata FrameStrata
---@param parent Frame
---@param ... [Frame]
local function FixStrata(strata, parent, ...)
	local i = 1

	local child = select(i, ...)
	---@cast child Frame
	parent:SetFrameStrata(strata)
	while child do
		FixStrata(strata, child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

---@param levelsToInclude table<integer|string>
---@param textLevels table<string>
---@return string
local function CreateCombinedLevelString(levelsToInclude, textLevels)
	local combinedLevelString = ""
	if #levelsToInclude == 0 then
		for _, textLevel in ipairs(textLevels) do
			if combinedLevelString:len() == 0 then
				combinedLevelString = textLevel
			else
				combinedLevelString = combinedLevelString .. k.RightArrow .. textLevel
			end
		end
	else
		for _, levelToInclude in ipairs(levelsToInclude) do
			if levelToInclude == "n" then
				if combinedLevelString:len() == 0 then
					combinedLevelString = textLevels[#textLevels]
				else
					combinedLevelString = combinedLevelString .. k.RightArrow .. textLevels[#textLevels]
				end
			elseif textLevels[levelToInclude] then
				if combinedLevelString:len() == 0 then
					combinedLevelString = textLevels[levelToInclude]
				else
					combinedLevelString = combinedLevelString .. k.RightArrow .. textLevels[levelToInclude]
				end
			end
		end
	end
	return combinedLevelString
end

do
	local Type = "EPDropdownPullout"
	local Version = 1

	---@param self EPDropdownPullout
	local function OnAcquire(self)
		self.dropdownItemHeight = k.DefaultDropdownItemHeight
		self.scrollIndicatorFrame:SetHeight(k.DefaultDropdownItemHeight / 2)
		self.frame:SetParent(UIParent)
		self.autoWidth = false
	end

	---@param self EPDropdownPullout
	local function OnRelease(self)
		self:Clear()
		self.scrollIndicatorFrame:Hide()
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.maxHeight = k.DefaultMaxItems * k.DefaultDropdownItemHeight
		self.maxItems = k.DefaultMaxItems
	end

	---@param enteredItem EPDropdownItemToggle|EPDropdownItemMenu
	local function OnEnter(enteredItem)
		local self = enteredItem.parentPullout
		for _, siblingItem in ipairs(self.items) do
			if siblingItem.CloseMenu and siblingItem ~= enteredItem then
				---@cast siblingItem EPDropdownItemMenu
				siblingItem:CloseMenu()
			end
		end
	end

	---@param self EPDropdownPullout
	---@param item EPDropdownItemToggle|EPDropdownItemMenu
	---@param index? integer
	local function InsertItem(self, item, index)
		if not index then
			index = #self.items + 1
		end
		tinsert(self.items, index, item)
		item:SetHeight(self.dropdownItemHeight)
		local h = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h + k.EdgeSize * 2, self.maxHeight))
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
		local previousFrame = nil
		for _, item in ipairs(self.items) do
			if previousFrame then
				item:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT")
				item:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
			else
				item:SetPoint("TOPLEFT", self.itemFrame, "TOPLEFT")
				item:SetPoint("TOPRIGHT", self.itemFrame, "TOPRIGHT")
			end
			previousFrame = item.frame
		end

		local height = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(height)

		if height + k.EdgeSize * 2 > self.maxHeight then
			local halfHeight = self.dropdownItemHeight / 2.0
			self.frame:SetHeight(self.maxHeight + halfHeight)
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, halfHeight + k.EdgeSize)
			self.scrollIndicatorFrame:SetHeight(halfHeight)
			self.scrollIndicator:SetSize(halfHeight, halfHeight)
			self.scrollIndicatorFrame:Show()
			self:SetScroll(self.scrollFrame:GetVerticalScroll())
		else
			self.frame:SetHeight(min(height + k.EdgeSize * 2, self.maxHeight))
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, k.EdgeSize)
			self.scrollIndicatorFrame:Hide()
			self.itemFrame:SetWidth(self.scrollFrame:GetWidth())
		end

		for _, item in ipairs(self.items) do
			if item.frame:IsMouseOver() then
				item.highlight:Show()
			else
				item.highlight:Hide()
			end
		end
	end

	---@param self EPDropdownPullout
	---@param point string
	---@param relFrame Frame|BackdropTemplate
	---@param relPoint string
	---@param x number
	---@param y number
	---@param maxItemWidth? number
	local function Open(self, point, relFrame, relPoint, x, y, maxItemWidth)
		if not maxItemWidth then
			maxItemWidth = k.MinimumPulloutWidth
		end

		self.frame:SetPoint(point, relFrame, relPoint, x, y)
		local previousFrame = nil
		for _, item in ipairs(self.items) do
			if previousFrame then
				item:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT")
				item:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
			else
				item:SetPoint("TOPLEFT", self.itemFrame, "TOPLEFT")
				item:SetPoint("TOPRIGHT", self.itemFrame, "TOPRIGHT")
			end
			item:Show()
			if self.autoWidth then
				local width = item.text:GetStringWidth() + item.textOffsetX * 2
				if item.menuIndicator then
					---@cast item EPDropdownItemMenu
					width = width + item.menuIndicator:GetWidth() + item.menuIndicatorOffsetX
				elseif not item.neverShowItemsAsSelected then
					width = width + item.check:GetWidth() + item.checkOffsetX
				end
				if item.customTextureFrame:IsShown() then
					width = width + item.customTextureFrame:GetWidth() + item.checkOffsetX
				end
				maxItemWidth = max(maxItemWidth, width)
			end
			previousFrame = item.frame
		end

		local height = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(height)

		if height + k.EdgeSize * 2 > self.maxHeight then
			local halfHeight = self.dropdownItemHeight / 2.0
			self.frame:SetHeight(self.maxHeight + halfHeight)
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, halfHeight + k.EdgeSize)
			self.scrollIndicatorFrame:SetHeight(halfHeight)
			self.scrollIndicator:SetSize(halfHeight, halfHeight)
			self.scrollIndicatorFrame:Show()
			self:SetScroll(self.scrollFrame:GetVerticalScroll())
		else
			self.frame:SetHeight(min(height + k.EdgeSize * 2, self.maxHeight))
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, k.EdgeSize)
			self.scrollIndicatorFrame:Hide()
			self.itemFrame:SetWidth(self.scrollFrame:GetWidth())
		end

		if self.autoWidth then
			self.frame:SetWidth(maxItemWidth)
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
	---@param maxVisibleItems integer
	local function SetMaxVisibleItems(self, maxVisibleItems)
		self.maxItems = maxVisibleItems
		self.maxHeight = maxVisibleItems * self.dropdownItemHeight + k.EdgeSize * 2
		if self.frame:GetHeight() > self.maxHeight then
			self.frame:SetHeight(self.maxHeight)
		elseif (self.itemFrame:GetHeight()) < self.maxHeight - k.EdgeSize * 2 then
			self.frame:SetHeight(self.itemFrame:GetHeight() + k.EdgeSize * 2)
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
		self.dropdownItemHeight = height
		self.maxHeight = self.maxItems * height + k.EdgeSize * 2
		for _, item in ipairs(self.items) do
			item:SetHeight(height)
		end
		local h = #self.items * height
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h + k.EdgeSize * 2, self.maxHeight))
	end

	---@param self EPDropdownPullout
	---@param value number
	local function SetScroll(self, value)
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local itemFrameHeight = self.itemFrame:GetHeight()
		local maxVerticalScroll = itemFrameHeight - scrollFrameHeight
		local newVerticalScroll = max(min(value, maxVerticalScroll), 0)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)

		if maxVerticalScroll > 0 and abs(newVerticalScroll - maxVerticalScroll) > 0.1 then
			self.scrollIndicator:Show()
		else
			self.scrollIndicator:Hide()
		end
		if self.itemFrame:GetWidth() ~= self.scrollFrame:GetWidth() then
			self.itemFrame:SetWidth(self.scrollFrame:GetWidth())
		end
	end

	---@param self EPDropdownPullout
	---@param byText boolean|nil
	---@param sortFunction? fun(a: EPItemBase, b: EPItemBase):boolean
	local function Sort(self, byText, sortFunction)
		if sortFunction then
			sort(self.items, sortFunction)
		elseif byText then
			sort(self.items, function(a, b)
				return a:GetText():match(k.RegexIconText) < b:GetText():match(k.RegexIconText)
			end)
		else
			sort(self.items, function(a, b)
				return a:GetUserDataTable().value < b:GetUserDataTable().value
			end)
		end
	end

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(k.PulloutBackdrop)
		frame:SetBackdropColor(unpack(k.PulloutBackdropColor))
		frame:SetBackdropBorderColor(unpack(k.PulloutBackdropBorderColor))
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(k.DefaultPulloutWidth)
		frame:SetHeight(k.DefaultDropdownItemHeight)

		local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -k.EdgeSize)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, k.EdgeSize)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetFrameStrata("DIALOG")

		local itemFrame = CreateFrame("Frame", Type .. "ItemFrame" .. count, scrollFrame)
		itemFrame:SetWidth(k.DefaultPulloutWidth)
		itemFrame:SetFrameStrata("DIALOG")
		scrollFrame:SetScrollChild(itemFrame)
		itemFrame:SetPoint("TOPLEFT")
		itemFrame:SetPoint("RIGHT")

		local scrollIndicatorFrame =
			CreateFrame("Frame", Type .. "ScrollIndicatorFrame" .. count, frame, "BackdropTemplate")
		scrollIndicatorFrame:SetBackdrop(k.PulloutBackdrop)
		scrollIndicatorFrame:SetBackdropColor(unpack(k.PulloutBackdropColor))
		scrollIndicatorFrame:SetBackdropBorderColor(unpack(k.PulloutBackdropColor))
		local scrollIndicator = scrollIndicatorFrame:CreateTexture(nil, "OVERLAY")
		scrollIndicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", k.EdgeSize, k.EdgeSize)
		scrollIndicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -k.EdgeSize, k.EdgeSize)
		scrollIndicator:SetTexture(k.SortDownTexture)
		scrollIndicator:SetPoint("CENTER")
		scrollIndicatorFrame:Hide()
		scrollFrame:Show()
		itemFrame:Show()

		---@class EPDropdownPullout : AceGUIWidget
		---@field maxHeight number
		---@field maxItems integer
		---@field items table<integer, EPDropdownItemToggle|EPDropdownItemMenu>
		---@field dropdownItemHeight number
		---@field autoWidth boolean
		local widget = {
			OnAcquire = OnAcquire,
			OnRelease = OnRelease,
			InsertItem = InsertItem,
			RemoveItem = RemoveItem,
			Open = Open,
			Close = Close,
			Clear = Clear,
			SetMaxVisibleItems = SetMaxVisibleItems,
			SetItemHeight = SetItemHeight,
			SetScroll = SetScroll,
			SetAutoWidth = SetAutoWidth,
			Sort = Sort,
			scrollIndicator = scrollIndicator,
			scrollIndicatorFrame = scrollIndicatorFrame,
			frame = frame,
			scrollFrame = scrollFrame,
			itemFrame = itemFrame,
			type = Type,
			count = count,
			maxHeight = k.DefaultMaxItems * k.DefaultDropdownItemHeight,
			items = {},
			maxItems = k.DefaultMaxItems,
		}

		scrollFrame:SetScript("OnMouseWheel", function(_, delta)
			local snapValue = widget.dropdownItemHeight
			local currentVerticalScroll = widget.scrollFrame:GetVerticalScroll()
			local currentSnapValue
			if delta > 0 then
				currentSnapValue = floor(currentVerticalScroll / snapValue) - 1
			elseif delta < 0 then
				currentSnapValue = ceil(currentVerticalScroll / snapValue) + 1
			else
				currentSnapValue = floor((currentVerticalScroll / snapValue) + 0.5)
			end
			widget:SetScroll(currentSnapValue * snapValue)
		end)
		scrollFrame:SetScript("OnSizeChanged", function()
			widget:SetScroll(widget.scrollFrame:GetVerticalScroll())
		end)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
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
			self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, 1, self.frame:GetWidth())
			AceGUI:SetFocus(self)
		end
	end

	---@param self EPDropdown
	local function HandlePulloutOpen(self)
		local value = self.value
		if not self.multiselect then
			for _, item in ipairs(self.pullout.items) do
				item:SetIsSelected(item:GetValue() == value)
			end
		end
		self.open = true
		self.button:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
		self:Fire("OnOpened")
	end

	---@param self EPDropdown
	local function HandlePulloutClose(self)
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
	---@return table<integer, { item: EPDropdownItemToggle|EPDropdownItemMenu, text: string }>
	local function FindItems(self, value, includeNeverShowItemsAsSelectedItems)
		local results = {}

		---@param items table<integer, EPDropdownItemToggle|EPDropdownItemMenu>
		local function searchItems(items)
			for _, item in ipairs(items) do
				if includeNeverShowItemsAsSelectedItems or not item.neverShowItemsAsSelected then
					local itemValue = item:GetValue()
					local isMatch = false

					if type(value) == "table" and type(itemValue) == "table" then
						isMatch = true
						for key, currentValue in pairs(itemValue) do
							if currentValue ~= value[key] then
								isMatch = false
								break
							end
						end
					else
						isMatch = (itemValue == value)
					end

					if isMatch then
						tinsert(results, { item = item, text = item.text:GetText() })
					end

					if item.childPullout and item.childPullout.items then
						searchItems(item.childPullout.items)
					end
				end
			end
		end

		if self.pullout and self.pullout.items then
			searchItems(self.pullout.items)
		end

		return results
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
					local itemValue = item:GetValue()
					if type(value) == "table" and type(itemValue) == "table" then
						local allEqual = true
						for key, currentValue in pairs(itemValue) do
							if currentValue ~= value[key] then
								allEqual = false
								break
							end
						end
						if allEqual then
							return item, item.text:GetText()
						end
					else
						if item:GetValue() == value then
							return item, item.text:GetText()
						end
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

	---@param self EPDropdown
	---@param dropdownItem EPDropdownItemMenu
	---@param selected boolean
	---@param value any
	---@param valueOwningDropdownItemMenu? EPDropdownItemMenu The parent dropdown item menu owning the item with value
	local function HandleMenuItemValueChanged(self, dropdownItem, selected, value, valueOwningDropdownItemMenu)
		if self.multiselect then
			self:Fire("OnValueChanged", value, selected, dropdownItem:GetValue(), valueOwningDropdownItemMenu)
		else
			if dropdownItem.clickable and value == nil then
				self:Fire("OnValueChanged", dropdownItem:GetUserDataTable().initialValue)
			else
				self:SetValue(value)
				self:Fire("OnValueChanged", value, nil, dropdownItem:GetValue(), valueOwningDropdownItemMenu)
			end

			if self.open then
				self.pullout:Close()
			end
		end
	end

	---@param self EPDropdown
	---@param dropdownItem EPDropdownItemToggle
	---@param selected boolean
	local function HandleItemValueChanged(self, dropdownItem, selected)
		if self.multiselect then
			if dropdownItem.neverShowItemsAsSelected then
				self:Fire("OnValueChanged", dropdownItem:GetValue())
				if self.open then
					self.pullout:Close()
				end
			else
				self:Fire("OnValueChanged", dropdownItem:GetValue(), selected)
			end
		else
			if dropdownItem.neverShowItemsAsSelected or selected then
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
		self.frame:SetBackdrop(k.DropdownBackdrop)
		self.frame:SetBackdropColor(unpack(k.DropdownBackdropColor))
		self.frame:SetBackdropBorderColor(unpack(k.DropdownBackdropBorderColor))
		self.frame:Show()
		self.text:Show()
		self.buttonCover:Show()
		self.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
		self.button:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT")
		self.button:SetWidth(k.DefaultDropdownItemHeight)
		self.button:Show()
		self.itemHorizontalPadding = k.DefaultHorizontalItemPadding
		self.dropdownItemHeight = k.DefaultDropdownItemHeight
		self.textHorizontalPadding = k.DefaultHorizontalItemPadding
		self.pullout = AceGUI:Create("EPDropdownPullout")
		self.pullout:SetCallback("OnClose", function()
			HandlePulloutClose(self)
		end)
		self.pullout:SetCallback("OnOpen", function()
			HandlePulloutOpen(self)
		end)
		self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		self.pullout:SetAutoWidth(true)
		FixLevels(self.pullout.frame, self.pullout.frame:GetChildren())

		self:SetTextFontSize(k.FontSize)
		self:SetItemTextFontSize(k.FontSize)
		self:SetTextCentered(false)
		self:SetHeight(self.dropdownItemHeight)
		self:SetWidth(k.DefaultDropdownWidth)
		self:SetPulloutWidth(nil)
		self:SetButtonVisibility(true)
		self:SetEnabled(true)
		self:SetMaxVisibleItems(k.DefaultMaxItems)
		self:SetShowPathText(false)
		self:SetShowHighlight(false)
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
		self.isFake = nil

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
			self.text:SetTextColor(unpack(k.EnabledTextColor))
		else
			self.button:Disable()
			self.buttonCover:Disable()
			self.text:SetTextColor(unpack(k.DisabledTextColor))
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

	-- Only searches for the first match of the current value. Does not include items which are set to
	-- neverShowItemsAsSelected.
	---@param self EPDropdown
	local function SetTextFromValue(self)
		local textLevels = {}
		local item, itemText = self:FindItemAndText(self.value)
		while item do
			tinsert(textLevels, 1, itemText)
			item = item.parentDropdownItemMenu
			if item then
				itemText = item:GetText()
			end
		end
		self:SetText(CreateCombinedLevelString(self.levelsToInclude, textLevels))
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
		self.value = value
		local text = ""
		local textLevels = nil

		local itemDataTable = FindItems(self, value, false)

		if #itemDataTable > 0 then
			text = itemDataTable[1].text
		end

		for _, itemData in ipairs(itemDataTable) do
			local currentItem = itemData.item
			local textStack = {}

			while currentItem do
				-- Build textLevels once using first matching path
				if self.showPathText and not textLevels then
					tinsert(textStack, 1, currentItem:GetText())
				end

				---@type EPDropdownItemMenu
				local menuItemParent = currentItem.parentDropdownItemMenu
				if menuItemParent then
					menuItemParent:SetChildValue(value)
					menuItemParent:SetIsSelected(true)
					currentItem = menuItemParent
				else
					break
				end
			end

			-- Save the first matching path's text
			if self.showPathText and not textLevels then
				textLevels = textStack
			end
		end

		if self.showPathText and textLevels then
			text = CreateCombinedLevelString(self.levelsToInclude, textLevels)
		end

		self:SetText(text)
	end

	---@param self EPDropdown
	---@return any
	local function GetValue(self)
		return self.value
	end

	---@param self EPDropdown
	---@param currentValue any
	---@param newValue any
	---@param newText string
	local function EditItemValueAndText(self, currentValue, newValue, newText)
		local itemDataTable = FindItems(self, currentValue)
		for _, itemData in ipairs(itemDataTable) do
			if itemData.item then
				itemData.item:SetValue(newValue)
				itemData.item:SetText(newText)
			end
		end
		if self.value == currentValue then
			self:SetValue(newValue)
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
			local itemDataTable = FindItems(self, existingItemValue, true)
			for _, itemData in ipairs(itemDataTable) do
				local item = itemData.item
				if item and item.type == "EPDropdownItemMenu" then
					---@cast item EPDropdownItemMenu
					for _, pulloutItem in ipairs(item.childPullout.items) do
						pulloutItem:SetIsSelected(itemValuesToSelect[pulloutItem:GetValue()] == true)
					end
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
			local itemDataTable = FindItems(self, itemValue, true)
			for _, itemData in ipairs(itemDataTable) do
				if itemData.item then
					itemData.item:SetIsSelected(selected)
				end
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
	---@param itemData DropdownItemData
	---@param itemType "EPDropdownItemMenu"|"EPDropdownItemToggle" type of item to create
	---@param index? integer
	---@param notSelectable boolean? If true, items will not be selectable. If unspecified, uses value provided for each item.
	local function AddItem(self, itemData, itemType, index, notSelectable)
		local exists = AceGUI:GetWidgetVersion(itemType)
		if not exists then
			error(("The given item type, %q, does not"):format(tostring(itemType)), 2)
			return
		end

		if itemType == "EPDropdownItemMenu" then
			local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
			dropdownMenuItem.parentDropdown = self
			dropdownMenuItem.parentDropdownItemMenu = nil
			dropdownMenuItem:GetUserDataTable().level = 1
			dropdownMenuItem:GetUserDataTable().initialValue = itemData.itemValue
			dropdownMenuItem:SetValue(itemData.itemValue)
			dropdownMenuItem:SetText(itemData.text)
			dropdownMenuItem:SetFontSize(self.itemTextFontSize)
			if itemData.indent then
				dropdownMenuItem:SetHorizontalPadding(self.itemHorizontalPadding + itemData.indent)
			else
				dropdownMenuItem:SetHorizontalPadding(self.itemHorizontalPadding)
			end
			dropdownMenuItem:SetMultiselect(self.multiselect)
			dropdownMenuItem:SetCallback("OnValueChanged", function(widget, _, selected, value, owningDropdownMenuItem)
				HandleMenuItemValueChanged(self, widget, selected, value, owningDropdownMenuItem)
			end)
			dropdownMenuItem:SetClickable(itemData.itemMenuClickable)
			dropdownMenuItem:SetNeverShowItemsAsSelected(notSelectable)
			self.pullout:InsertItem(dropdownMenuItem, index)
			if itemData.dropdownItemMenuData then
				dropdownMenuItem:SetMenuItems(itemData.dropdownItemMenuData, self)
			end
		elseif itemType == "EPDropdownItemToggle" then
			local dropdownItemToggle = AceGUI:Create("EPDropdownItemToggle")
			dropdownItemToggle.parentDropdown = self
			dropdownItemToggle.parentDropdownItemMenu = nil
			dropdownItemToggle:GetUserDataTable().level = 1
			dropdownItemToggle:SetValue(itemData.itemValue)
			dropdownItemToggle:SetText(itemData.text)
			dropdownItemToggle:SetFontSize(self.itemTextFontSize)
			if itemData.indent then
				dropdownItemToggle:SetHorizontalPadding(self.itemHorizontalPadding + itemData.indent)
			else
				dropdownItemToggle:SetHorizontalPadding(self.itemHorizontalPadding)
			end
			if itemData.customTexture and itemData.customTextureVertexColor then
				dropdownItemToggle:SetCustomTexture(
					itemData.customTexture,
					itemData.customTextureVertexColor,
					itemData.customTextureSelectable,
					notSelectable == true
				)
			end
			if itemData.customTextureSelectable then
				local itemValue = itemData.itemValue
				dropdownItemToggle:SetCallback("Clicked", function(widget)
					self:Fire("CustomTextureClicked", widget, itemValue)
				end)
			end
			if not itemData.notClickable then
				dropdownItemToggle:SetCallback("OnValueChanged", function(widget, _, selected)
					HandleItemValueChanged(self, widget, selected)
				end)
			end
			if notSelectable == true then
				dropdownItemToggle:SetNeverShowItemsAsSelected(true)
			end
			self.pullout:InsertItem(dropdownItemToggle, index)
		end
	end

	---@param self EPDropdown
	---@param itemValue any the internal value used to index an item
	local function RemoveItem(self, itemValue)
		local itemDataTable = FindItems(self, itemValue, true)
		for _, itemData in ipairs(itemDataTable) do
			itemData.item.parentPullout:RemoveItem(itemValue)
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
	-- The type of item to create for direct children of the dropdown. Ignored if any top level itemData has child data
	---@param leafType "EPDropdownItemMenu"|"EPDropdownItemToggle"?
	---@param notSelectable boolean? If true, items will not be selectable. If unspecified, uses value provided for each item.
	---@param startIndex integer?
	local function AddItems(self, dropdownItemData, leafType, notSelectable, startIndex)
		local currentIndex = startIndex
		leafType = leafType or "EPDropdownItemToggle"
		for index, itemData in ipairs(dropdownItemData) do
			if type(itemData) == "string" then
				self:AddItem({ itemValue = index, text = itemData }, leafType, currentIndex)
			elseif type(itemData) == "table" then
				if notSelectable == true then
					itemData.notSelectable = true
				end
				if type(itemData.dropdownItemMenuData) == "table" then
					self:AddItem(itemData, "EPDropdownItemMenu", currentIndex)
				else
					self:AddItem(itemData, leafType, currentIndex)
				end
			end
			if currentIndex then
				currentIndex = currentIndex + 1
			end
		end
	end

	-- Adds items to an existing dropdown menu item.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	---@param dropdownItemData table<integer, DropdownItemData> table of dropdown item data
	---@param index integer? item index to insert into. Only valid if only one item exists with existingItemValue.
	local function AddItemsToExistingDropdownItemMenu(self, existingItemValue, dropdownItemData, index)
		local itemDataTable = FindItems(self, existingItemValue, true)
		for _, itemData in ipairs(itemDataTable) do
			if itemData.item.type == "EPDropdownItemMenu" then
				local item = itemData.item
				---@cast item EPDropdownItemMenu
				item:AddMenuItems(dropdownItemData, self, index)
			end
		end
	end

	-- Removes items from a dropdown menu item's immediate children.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index a dropdown menu item
	---@param dropdownItemData table<integer, DropdownItemData> table of dropdown item data to remove from existing menu
	local function RemoveItemsFromExistingDropdownItemMenu(self, existingItemValue, dropdownItemData)
		local itemDataTable = FindItems(self, existingItemValue, true)
		for _, itemData in ipairs(itemDataTable) do
			local item = itemData.item
			if item.type == "EPDropdownItemMenu" then
				---@cast item EPDropdownItemMenu
				item:RemoveMenuItems(dropdownItemData)
			end
		end
	end

	-- Returns a list of a dropdown item menu's immediate child values. Only valid if only one item exists with itemValue.
	---@param self EPDropdown
	---@param itemValue any the internal value used to index an item
	---@return table<integer, DropdownItemData>
	local function GetItemsFromDropdownItemMenu(self, itemValue)
		local existingDropdownMenuItem, _ = FindItemAndText(self, itemValue, true)
		local dropdownItemData = {}
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			---@cast existingDropdownMenuItem EPDropdownItemMenu
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
		local itemDataTable = FindItems(self, existingItemValue, true)
		for _, itemData in ipairs(itemDataTable) do
			local item = itemData.item
			if item.type == "EPDropdownItemMenu" then
				---@cast item EPDropdownItemMenu
				item:Clear()
			end
		end
	end

	-- Hides the highlight texture for any existing dropdown item menu children.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	local function ClearHighlightsForExistingDropdownItemMenu(self, existingItemValue)
		local itemDataTable = FindItems(self, existingItemValue, true)
		for _, itemData in ipairs(itemDataTable) do
			local item = itemData.item
			if item.type == "EPDropdownItemMenu" and item.childPullout then
				---@cast item EPDropdownItemMenu
				for _, childPulloutItem in ipairs(item.childPullout.items) do
					childPulloutItem.highlight:Hide()
				end
			end
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
		self.button:SetWidth(height)
		self.pullout:SetItemHeight(height)
	end

	---@param self EPDropdown
	---@param visible boolean
	local function SetButtonVisibility(self, visible)
		self.text:ClearAllPoints()
		if visible then
			self.button:Show()
			self.text:SetPoint("LEFT", self.frame, "LEFT", self.textHorizontalPadding, 0)
			self.text:SetPoint("RIGHT", self.button, "LEFT", -self.textHorizontalPadding / 2, 0)
		else
			self.text:SetPoint("LEFT", self.frame, "LEFT", self.textHorizontalPadding, 0)
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.textHorizontalPadding, 0)
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
		if self.button:IsShown() then
			self.text:SetPoint("LEFT", self.frame, "LEFT", self.textHorizontalPadding, 0)
			self.text:SetPoint("RIGHT", self.button, "LEFT", -self.textHorizontalPadding / 2, 0)
		else
			self.text:SetPoint("LEFT", self.frame, "LEFT", self.textHorizontalPadding, 0)
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.textHorizontalPadding, 0)
		end
	end

	---@param self EPDropdown
	---@param size integer
	local function SetItemHorizontalPadding(self, size)
		self.itemHorizontalPadding = size
	end

	-- Sorts the immediate children of the pullout matching value. If value is nil, the top level pullout is sorted.
	---@param self EPDropdown
	---@param value any
	---@param byText boolean|nil If true, items are sorted by text appearing after an icon, otherwise by item value.
	---@param sortFunction? fun(a: EPItemBase, b: EPItemBase):boolean
	local function Sort(self, value, byText, sortFunction)
		if value then
			local itemDataTable = FindItems(self, value, true)
			for _, itemData in ipairs(itemDataTable) do
				if itemData.item.type == "EPDropdownItemMenu" then
					itemData.item.childPullout:Sort(byText, sortFunction)
				end
			end
		else
			self.pullout:Sort(byText, sortFunction)
		end
	end

	---@param self EPDropdown
	---@param maxVisibleItems integer
	local function SetMaxVisibleItems(self, maxVisibleItems)
		self.maxItems = maxVisibleItems
		self.pullout:SetMaxVisibleItems(maxVisibleItems)
	end

	---@param self EPDropdown
	---@param show boolean
	---@param levelsToInclude table<integer|string>?
	local function SetShowPathText(self, show, levelsToInclude)
		self.showPathText = show
		self.levelsToInclude = levelsToInclude or {}
	end

	---@param self EPDropdown
	---@param use boolean
	local function SetUseLineEditForDoubleClick(self, use)
		if not self.lineEdit and use then
			self.lineEdit = AceGUI:Create("EPLineEdit")
			self.lineEdit:SetMaxLetters(36)
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
		frame:SetBackdrop(k.DropdownBackdrop)
		frame:SetBackdropColor(unpack(k.DropdownBackdropColor))
		frame:SetBackdropBorderColor(unpack(k.DropdownBackdropBorderColor))

		local button = CreateFrame("Button", Type .. "Button" .. count, frame)
		button:ClearAllPoints()
		button:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
		button:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		button:SetNormalTexture(k.DropdownTexture)
		button:SetPushedTexture(k.DropdownTexture)
		button:SetHighlightTexture(k.DropdownTexture)
		button:SetDisabledTexture(k.DropdownTexture)
		button:GetDisabledTexture():SetVertexColor(unpack(k.DisabledTextColor))

		local buttonCover = CreateFrame("Button", Type .. "ButtonCover" .. count, frame)
		buttonCover:SetFrameLevel(button:GetFrameLevel() + 1)
		buttonCover:SetPoint("TOPLEFT")
		buttonCover:SetPoint("BOTTOMRIGHT")

		local background = frame:CreateTexture(Type .. "Background" .. count, "BORDER")
		background:SetPoint("TOPLEFT", buttonCover, 1, -1)
		background:SetPoint("BOTTOMRIGHT", buttonCover, -1, 1)
		background:SetColorTexture(unpack(k.NeutralButtonColor))
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

		local text = frame:CreateFontString(nil, "OVERLAY")
		text:SetWordWrap(false)
		text:SetPoint("LEFT", frame, "LEFT", k.DefaultHorizontalItemPadding, 0)
		text:SetPoint("RIGHT", frame, "RIGHT", -k.DefaultHorizontalItemPadding, 0)
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		if fPath then
			text:SetFont(fPath, k.FontSize)
		end

		---@class EPDropdown : AceGUIWidget
		---@field text FontString
		---@field slider table|BackdropTemplate|Slider
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
		---@field showHighlight boolean
		---@field itemTextFontSize number
		---@field itemHorizontalPadding number
		---@field textHorizontalPadding number
		---@field maxItems integer
		---@field showPathText boolean
		---@field levelsToInclude table<integer|string>
		local widget = {
			OnAcquire = OnAcquire,
			OnRelease = OnRelease,
			SetEnabled = SetEnabled,
			ClearFocus = ClearFocus,
			FindItems = FindItems,
			FindItemAndText = FindItemAndText,
			SetText = SetText,
			SetTextCentered = SetTextCentered,
			SetValue = SetValue,
			GetValue = GetValue,
			SetItemEnabled = SetItemEnabled,
			AddItem = AddItem,
			RemoveItem = RemoveItem,
			AddItems = AddItems,
			EditItemValueAndText = EditItemValueAndText,
			SetDropdownItemHeight = SetDropdownItemHeight,
			AddItemsToExistingDropdownItemMenu = AddItemsToExistingDropdownItemMenu,
			GetItemsFromDropdownItemMenu = GetItemsFromDropdownItemMenu,
			RemoveItemsFromExistingDropdownItemMenu = RemoveItemsFromExistingDropdownItemMenu,
			ClearExistingDropdownItemMenu = ClearExistingDropdownItemMenu,
			ClearHighlightsForExistingDropdownItemMenu = ClearHighlightsForExistingDropdownItemMenu,
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
			SetMaxVisibleItems = SetMaxVisibleItems,
			SetShowPathText = SetShowPathText,
			SetTextFromValue = SetTextFromValue,
			frame = frame,
			type = Type,
			count = count,
			text = text,
			buttonCover = buttonCover,
			button = button,
			background = background,
			fadeIn = fadeInGroup,
			fadeOut = fadeOutGroup,
			isFake = false,
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
				local textMaybeWithIcon = widget.text:GetText()
				textMaybeWithIcon = textMaybeWithIcon:match(k.RegexIconText) or textMaybeWithIcon
				widget.lineEdit:SetText(textMaybeWithIcon)
				widget.lineEdit.frame:Show()
				widget.lineEdit:SetFocus()
			end
		end)
		buttonCover:SetScript("OnClick", function()
			if #widget.pullout.items == 0 then
				widget:Fire("Clicked")
			end
			if not widget.isFake then
				HandleToggleDropdownPullout(widget)
			end
		end)
		frame:SetScript("OnHide", function()
			HandleDropdownHide(widget)
		end)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
