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

local defaultHorizontalItemPadding = 4
local fontSize = 14
local defaultDropdownItemHeight = 24
local minimumPulloutWidth = 100
local pulloutBackdropColor = { 0.1, 0.1, 0.1, 1 }
local pulloutBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local dropdownBackdropColor = { 0.1, 0.1, 0.1, 1 }
local dropdownBackdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local disabledTextColor = Private.constants.colors.kDisabledTextColor
local neutralButtonColor = Private.constants.colors.kNeutralButtonActionColor
local enabledTextColor = Private.constants.colors.kEnabledTextColor
local defaultDropdownWidth = 200
local defaultPulloutWidth = 200
local defaultMaxItems = 13
local rightArrow = " |TInterface\\AddOns\\EncounterPlanner\\Media\\icons8-right-arrow-32:16|t "
local spellIconRegex = "|T.-|t%s(.+)"
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
local edgeSize = dropdownBackdrop.edgeSize

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
	return combinedLevelString
end

---@class DropdownItemData
---@field itemValue string|number the internal value used to index a dropdown item
---@field text string the value shown in the dropdown
---@field dropdownItemMenuData table<integer, DropdownItemData>|nil nested dropdown item menus
---@field selectable? boolean
---@field customTexture? string|integer
---@field customTextureVertexColor? number[]

do
	---@class EPDropdownPullout : AceGUIWidget
	---@field frame table|BackdropTemplate|Frame
	---@field scrollFrame ScrollFrame
	---@field itemFrame table|Frame
	---@field type string
	---@field count integer
	---@field maxHeight number
	---@field maxItems integer
	---@field items table<integer, EPDropdownItemToggle|EPDropdownItemMenu>
	---@field dropdownItemHeight number
	---@field autoWidth boolean

	local Type = "EPDropdownPullout"
	local Version = 1

	---@param self EPDropdownPullout
	local function OnAcquire(self)
		self.dropdownItemHeight = defaultDropdownItemHeight
		self.scrollIndicatorFrame:SetHeight(defaultDropdownItemHeight / 2)
		self.frame:SetParent(UIParent)
		self.autoWidth = false
	end

	---@param self EPDropdownPullout
	local function OnRelease(self)
		self:Clear()
		self.scrollIndicatorFrame:Hide()
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.maxHeight = defaultMaxItems * defaultDropdownItemHeight
		self.maxItems = defaultMaxItems
	end

	---@param item EPDropdownItemToggle|EPDropdownItemMenu
	local function OnEnter(item)
		local self = item.parentPullout
		for _, v in ipairs(self.items) do
			if v.CloseMenu and v ~= item then
				---@cast v EPDropdownItemMenu
				v:CloseMenu()
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
		self.frame:SetHeight(min(h + edgeSize * 2, self.maxHeight))
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
		self.frame:SetHeight(min(h + edgeSize * 2, self.maxHeight))
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
		self.frame:SetHeight(min(h + edgeSize * 2, self.maxHeight))
		self:FixScroll()
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
				if item.childSelectedIndicator:IsShown() then
					width = width + item.childSelectedIndicator:GetWidth() + item.childSelectedIndicatorOffsetX
				elseif not item.neverShowItemsAsSelected then
					width = width + item.check:GetWidth() + item.checkOffsetX
				end
				if item.customTexture:IsShown() then
					width = width + item.customTexture:GetWidth() + item.checkOffsetX
				end
				maxItemWidth = max(maxItemWidth, width)
			end
			previousFrame = item.frame
		end

		local height = #self.items * self.dropdownItemHeight
		self.itemFrame:SetHeight(height)

		if height + edgeSize * 2 > self.maxHeight then
			local halfHeight = self.dropdownItemHeight / 2.0
			self.frame:SetHeight(self.maxHeight + halfHeight)
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, halfHeight + edgeSize)
			self.scrollIndicatorFrame:SetHeight(halfHeight)
			self.scrollIndicator:SetSize(halfHeight, halfHeight)
			self.scrollIndicatorFrame:Show()
			self:SetScroll(self.scrollFrame:GetVerticalScroll())
		else
			self.frame:SetHeight(min(height + edgeSize * 2, self.maxHeight))
			self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, edgeSize)
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
		self.maxHeight = maxVisibleItems * self.dropdownItemHeight + edgeSize * 2
		if self.frame:GetHeight() > self.maxHeight then
			self.frame:SetHeight(self.maxHeight)
		elseif (self.itemFrame:GetHeight()) < self.maxHeight - edgeSize * 2 then
			self.frame:SetHeight(self.itemFrame:GetHeight() + edgeSize * 2)
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
		self.maxHeight = self.maxItems * height + edgeSize * 2
		for _, item in ipairs(self.items) do
			item:SetHeight(height)
		end
		local h = #self.items * height
		self.itemFrame:SetHeight(h)
		self.frame:SetHeight(min(h + edgeSize * 2, self.maxHeight))
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
		if self.itemFrame:GetWidth() ~= self.scrollFrame:GetWidth() then
			self.itemFrame:SetWidth(self.scrollFrame:GetWidth())
		end
	end

	---@param self EPDropdownPullout
	local function FixScroll(self)
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local itemFrameHeight = self.itemFrame:GetHeight()
		local maxVerticalScroll = itemFrameHeight - scrollFrameHeight
		local currentVerticalScroll = self.scrollFrame:GetVerticalScroll()

		local newVerticalScroll = max(min(currentVerticalScroll, maxVerticalScroll), 0)
		self:SetScroll(newVerticalScroll)
	end

	---@param self EPDropdownPullout
	---@param byText boolean|nil
	local function Sort(self, byText)
		if byText then
			sort(self.items, function(a, b)
				return a:GetText():match(spellIconRegex) < b:GetText():match(spellIconRegex)
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
		frame:SetBackdrop(pulloutBackdrop)
		frame:SetBackdropColor(unpack(pulloutBackdropColor))
		frame:SetBackdropBorderColor(unpack(pulloutBackdropBorderColor))
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(defaultPulloutWidth)
		frame:SetHeight(defaultDropdownItemHeight)

		local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -edgeSize)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, edgeSize)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetFrameStrata("DIALOG")

		local itemFrame = CreateFrame("Frame", Type .. "ItemFrame" .. count, scrollFrame)
		itemFrame:SetWidth(defaultPulloutWidth)
		itemFrame:SetFrameStrata("DIALOG")
		scrollFrame:SetScrollChild(itemFrame)
		itemFrame:SetPoint("TOPLEFT")
		itemFrame:SetPoint("RIGHT")

		local scrollIndicatorFrame =
			CreateFrame("Frame", Type .. "ScrollIndicatorFrame" .. count, frame, "BackdropTemplate")
		scrollIndicatorFrame:SetBackdrop(pulloutBackdrop)
		scrollIndicatorFrame:SetBackdropColor(unpack(pulloutBackdropColor))
		scrollIndicatorFrame:SetBackdropBorderColor(unpack(pulloutBackdropColor))
		local scrollIndicator = scrollIndicatorFrame:CreateTexture(nil, "OVERLAY")
		scrollIndicatorFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", edgeSize, edgeSize)
		scrollIndicatorFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -edgeSize, edgeSize)
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
			SetMaxVisibleItems = SetMaxVisibleItems,
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
			maxItems = defaultMaxItems,
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
	---@field maxItems integer
	---@field showPathText boolean
	---@field levelsToInclude table<integer|string>

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
		local self = pullout:GetUserDataTable().obj
		---@cast self EPDropdown
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
		local self = pullout:GetUserDataTable().obj
		---@cast self EPDropdown
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
	---@param text string
	local function HandleMenuItemValueChanged(dropdownItem, _, selected, value, text)
		local self = dropdownItem:GetUserDataTable().obj
		if self.multiselect then
			self:Fire("OnValueChanged", value, selected, dropdownItem:GetValue())
		else
			self:SetValue(value)
			if self.showPathText then
				self:SetText(text)
			end
			self:Fire("OnValueChanged", value, nil, dropdownItem:GetValue())
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
			if dropdownItem.neverShowItemsAsSelected then
				self:Fire("OnValueChanged", dropdownItem:GetValue())
				if self.open then
					self.pullout:Close()
				end
			else
				self:Fire("OnValueChanged", dropdownItem:GetValue(), selected)
			end
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
		self.frame:SetBackdrop(dropdownBackdrop)
		self.frame:SetBackdropColor(unpack(dropdownBackdropColor))
		self.frame:SetBackdropBorderColor(unpack(dropdownBackdropBorderColor))
		self.frame:Show()
		self.text:Show()
		self.buttonCover:Show()
		self.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
		self.button:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT")
		self.button:SetWidth(defaultDropdownItemHeight)
		self.button:Show()
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
		self:SetMaxVisibleItems(defaultMaxItems)
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
	local function SetTextFromValue(self)
		local textLevels = {}
		local item, itemText = self:FindItemAndText(self.value)
		while item do
			tinsert(textLevels, 1, itemText)
			item = item:GetUserDataTable().parentItemMenu
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
		local textLevels = {}
		local item, text = self:FindItemAndText(value)
		while item do -- Follow chain of parents up to dropdown
			local menuItemParent = item:GetUserDataTable().parentItemMenu
			if self.showPathText then
				tinsert(textLevels, 1, text)
				if menuItemParent then
					text = menuItemParent:GetText()
				end
			end
			if not menuItemParent then
				break
			end
			menuItemParent:SetChildValue(value)
			menuItemParent:SetIsSelectedBasedOnChildValue()
			item = menuItemParent
		end
		if self.showPathText then
			text = CreateCombinedLevelString(self.levelsToInclude, textLevels)
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

	---@param self EPDropdown
	---@param currentValue any
	---@param newValue any
	---@param newText string
	local function EditItemValueAndText(self, currentValue, newValue, newText)
		local item, _ = self:FindItemAndText(currentValue)
		if item then
			item:SetValue(newValue)
			item:SetText(newText)
			if self.value == currentValue then
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
	---@param customTexture? string|integer
	---@param customTextureVertexColor? number[]
	local function AddItem(
		self,
		itemValue,
		text,
		itemType,
		dropdownItemData,
		neverShowItemsAsSelected,
		customTexture,
		customTextureVertexColor
	)
		local exists = AceGUI:GetWidgetVersion(itemType)
		if not exists then
			error(("The given item type, %q, does not"):format(tostring(itemType)), 2)
			return
		end

		if itemType == "EPDropdownItemMenu" then
			local dropdownMenuItem = AceGUI:Create("EPDropdownItemMenu")
			dropdownMenuItem:GetUserDataTable().obj = self
			dropdownMenuItem:GetUserDataTable().level = 1
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
			dropdownItemToggle:GetUserDataTable().level = 1
			dropdownItemToggle:SetValue(itemValue)
			dropdownItemToggle:SetText(text)
			dropdownItemToggle:SetFontSize(self.itemTextFontSize)
			dropdownItemToggle:SetHorizontalPadding(self.itemHorizontalPadding)
			if customTexture and customTextureVertexColor then
				dropdownItemToggle:SetCustomTexture(customTexture, customTextureVertexColor)
			end
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
						neverShowItemsAsSelected or itemData.selectable == false,
						itemData.customTexture,
						itemData.customTextureVertexColor
					)
				else
					self:AddItem(
						itemData.itemValue,
						itemData.text,
						leafType,
						nil,
						neverShowItemsAsSelected or itemData.selectable == false,
						itemData.customTexture,
						itemData.customTextureVertexColor
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
			---@cast existingDropdownMenuItem EPDropdownItemMenu
			existingDropdownMenuItem:AddMenuItems(dropdownItemData, self, index)
		end
	end

	-- Removes items from a dropdown menu item's immediate children.
	---@param self EPDropdown
	---@param existingItemValue any the internal value used to index an item
	---@param dropdownItemData table<integer, DropdownItemData> table of dropdown item data
	local function RemoveItemsFromExistingDropdownItemMenu(self, existingItemValue, dropdownItemData)
		local existingDropdownMenuItem, _ = FindItemAndText(self, existingItemValue, true)
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			---@cast existingDropdownMenuItem EPDropdownItemMenu
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
		local existingDropdownMenuItem, _ = FindItemAndText(self, existingItemValue, true)
		if existingDropdownMenuItem and existingDropdownMenuItem.type == "EPDropdownItemMenu" then
			---@cast existingDropdownMenuItem EPDropdownItemMenu
			existingDropdownMenuItem:Clear()
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

	-- Sorts the immediate children of the pullout.
	---@param self EPDropdown
	---@param value any
	local function Sort(self, value)
		if value then
			local item, _ = FindItemAndText(self, value, true)
			if item then
				if item.type == "EPDropdownItemMenu" then
					item.childPullout:Sort()
				end
			end
		else
			self.pullout:Sort()
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
		frame:SetBackdrop(dropdownBackdrop)
		frame:SetBackdropColor(unpack(dropdownBackdropColor))
		frame:SetBackdropBorderColor(unpack(dropdownBackdropBorderColor))

		local button = CreateFrame("Button", Type .. "Button" .. count, frame)
		button:ClearAllPoints()
		button:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
		button:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		button:SetNormalTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetPushedTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetHighlightTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:SetDisabledTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
		button:GetDisabledTexture():SetVertexColor(unpack(disabledTextColor))

		local buttonCover = CreateFrame("Button", Type .. "ButtonCover" .. count, frame)
		buttonCover:SetFrameLevel(button:GetFrameLevel() + 1)
		buttonCover:SetPoint("TOPLEFT")
		buttonCover:SetPoint("BOTTOMRIGHT")

		local background = frame:CreateTexture(Type .. "Background" .. count, "BORDER")
		background:SetPoint("TOPLEFT", buttonCover, 1, -1)
		background:SetPoint("BOTTOMRIGHT", buttonCover, -1, 1)
		background:SetColorTexture(unpack(neutralButtonColor))
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
		text:SetPoint("LEFT", frame, "LEFT", defaultHorizontalItemPadding, 0)
		text:SetPoint("RIGHT", frame, "RIGHT", -defaultHorizontalItemPadding, 0)
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		if fPath then
			text:SetFont(fPath, fontSize)
		end

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
			EditItemValueAndText = EditItemValueAndText,
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
				textMaybeWithIcon = textMaybeWithIcon:match(spellIconRegex) or textMaybeWithIcon
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
