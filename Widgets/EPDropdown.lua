local AceGUI                  = LibStub("AceGUI-3.0")
local LSM                     = LibStub("LibSharedMedia-3.0")

local textOffsetX             = 4
local checkOffsetLeftX        = -2
local checkOffsetRightX       = -8
local checkSize               = 16
local fontSize                = 10
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

local dropdownItemHeight      = 20
local dropdownItemExtraOffset = 0
local dropdownSliderOffsetX   = -8

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


do
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

	-- See the note in Constructor() for each scroll related function
	local function OnMouseWheel(frame, value)
		local self = frame.obj
		if self then
			self:MoveScroll(value)
		end
	end

	local function OnScrollValueChanged(frame, value)
		local self = frame.obj
		if self then
			self:SetScroll(value)
		end
	end

	local function OnSizeChanged(frame)
		local self = frame.obj
		if self then
			self:FixScroll()
		end
	end

	local methods = {
		["OnAcquire"] = function(self)
			self.frame:SetParent(UIParent)
		end,

		["OnRelease"] = function(self)
			self:Clear()
			self.frame:ClearAllPoints()
			self.frame:Hide()
		end,

		["AddItem"] = function(self, item)
			self.items[#self.items + 1] = item

			local h = #self.items * dropdownItemHeight
			self.itemFrame:SetHeight(h)
			self.frame:SetHeight(min(h + dropdownItemExtraOffset, self.maxHeight)) -- +34: 20 for scrollFrame placement (10 offset) and +14 for item placement

			item.frame:SetPoint("LEFT", self.itemFrame, "LEFT")
			item.frame:SetPoint("RIGHT", self.itemFrame, "RIGHT")

			item:SetPullout(self)
			item:SetOnEnter(OnEnter)
		end,

		["Open"] = function(self, point, relFrame, relPoint, x, y)
			local items = self.items
			local frame = self.frame
			local itemFrame = self.itemFrame

			frame:SetPoint(point, relFrame, relPoint, x, y)

			local height = --[[8]] 0
			for i, item in pairs(items) do
				item:SetPoint("TOP", itemFrame, "TOP", 0, --[[-2+]] (i - 1) * -dropdownItemHeight)
				item:Show()

				height = height + dropdownItemHeight
			end
			itemFrame:SetHeight(height)
			fixstrata("TOOLTIP", frame, frame:GetChildren())
			frame:Show()
			self:Fire("OnOpen")
		end,

		["Close"] = function(self)
			self.frame:Hide()
			self:Fire("OnClose")
		end,

		["Clear"] = function(self)
			local items = self.items
			for i, item in pairs(items) do
				AceGUI:Release(item)
				items[i] = nil
			end
		end,

		["IterateItems"] = function(self)
			return ipairs(self.items)
		end,

		["SetHideOnLeave"] = function(self, val)
			self.hideOnLeave = val
		end,

		["SetMaxHeight"] = function(self, height)
			self.maxHeight = height or defaultMaxHeight
			if self.frame:GetHeight() > height then
				self.frame:SetHeight(height)
			elseif (self.itemFrame:GetHeight() + dropdownItemExtraOffset) < height then
				self.frame:SetHeight(self.itemFrame:GetHeight() + dropdownItemExtraOffset) -- see :AddItem
			end
		end,

		-- ["GetRightBorderWidth"] = function(self)
		-- 	return 6 + (self.slider:IsShown() and 12 or 0)
		-- end,

		-- ["GetLeftBorderWidth"] = function(self, value, text, itemType)
		-- 	return 6
		-- end,

		["SetScroll"] = function(self, value)
			local status = self.scrollStatus
			local frame, child = self.scrollFrame, self.itemFrame
			local height, viewheight = frame:GetHeight(), child:GetHeight()

			local offset
			if height >= viewheight then
				offset = 0
			else
				offset = floor((viewheight - height) / 1000 * value)
			end
			child:ClearAllPoints()
			child:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, offset)
			child:SetPoint("TOPRIGHT", frame, "TOPRIGHT", self.slider:IsShown() and -12 or 0, offset)
			status.offset = offset
			status.scrollvalue = value
		end,

		["MoveScroll"] = function(self, value)
			local status = self.scrollStatus
			local frame, child = self.scrollFrame, self.itemFrame
			local height, viewheight = frame:GetHeight(), child:GetHeight()

			if height >= viewheight then
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
		end,

		["FixScroll"] = function(self)
			local status = self.scrollStatus
			local frame, child = self.scrollFrame, self.itemFrame
			local height, viewheight = frame:GetHeight(), child:GetHeight()
			local offset = status.offset or 0

			if viewheight <= height then
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
		end,
	}

	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
		frame:SetBackdrop(pulloutBackdrop)
		frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetWidth(defaultWidth)
		frame:SetHeight(defaultMaxHeight)

		local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
		scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
		scrollFrame:SetToplevel(true)
		scrollFrame:SetFrameStrata("FULLSCREEN_DIALOG")

		local itemFrame = CreateFrame("Frame", nil, scrollFrame)
		itemFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		itemFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
		itemFrame:SetHeight(400)
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
		slider:SetScript("OnValueChanged", OnScrollValueChanged)
		slider:SetMinMaxValues(0, 1000)
		slider:SetValueStep(1)
		slider:SetValue(0)

		scrollFrame:Show()
		itemFrame:Show()
		slider:Hide()

		local widget    = {
			frame        = frame,
			scrollFrame  = scrollFrame,
			itemFrame    = itemFrame,
			slider       = slider,
			type         = Type,
			count        = count,
			maxHeight    = defaultMaxHeight,
			scrollStatus = {
				scrollvalue = 0,
			},
			items        = {}
		}

		frame.obj       = widget
		scrollFrame.obj = widget
		itemFrame.obj   = widget
		slider.obj      = widget

		for method, func in pairs(methods) do
			widget[method] = func
		end

		widget:FixScroll()

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end



do
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
			self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, self.label:IsShown() and -2 or 0)
			AceGUI:SetFocus(self)
		end
	end

	local function OnPulloutOpen(frame)
		local self = frame.userdata.obj
		local value = self.value

		if not self.multiselect then
			for i, item in frame:IterateItems() do
				item:SetValue(item.userdata.value == value)
			end
		end
		self.open = true
		self.button:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
		self:Fire("OnOpened")
	end

	local function OnPulloutClose(frame)
		local self = frame.userdata.obj
		self.open = nil
		self.button:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
		self.button:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
		self.button:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		self:Fire("OnClosed")
	end

	local function ShowMultiText(self)
		local text
		for i, widget in self.pullout:IterateItems() do
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

	local function OnItemValueChanged(frame, event, checked)
		local self = frame.userdata.obj

		if self.multiselect then
			self:Fire("OnValueChanged", frame.userdata.value, checked)
			ShowMultiText(self)
		else
			if checked then
				self:SetValue(frame.userdata.value)
				self:Fire("OnValueChanged", frame.userdata.value)
			else
				frame:SetValue(true)
			end
			if self.open then
				self.pullout:Close()
			end
		end
	end

	local methods = {
		["OnAcquire"] = function(self)
			local pullout = AceGUI:Create("EPDropdownPullout")
			self.pullout = pullout
			pullout.userdata.obj = self
			pullout:SetCallback("OnClose", OnPulloutClose)
			pullout:SetCallback("OnOpen", OnPulloutOpen)
			self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
			fixlevels(self.pullout.frame, self.pullout.frame:GetChildren())

			self:SetHeight(44)
			self:SetWidth(200)
			self:SetLabel()
			self:SetPulloutWidth(nil)
			self.list = {}
		end,
		["OnRelease"] = function(self)
			if self.open then
				self.pullout:Close()
			end
			AceGUI:Release(self.pullout)
			self.pullout = nil

			self:SetText("")
			self:SetDisabled(false)
			self:SetMultiselect(false)

			self.value = nil
			self.list = nil
			self.open = nil
			self.hasClose = nil

			self.frame:ClearAllPoints()
			self.frame:Hide()
		end,
		["SetDisabled"] = function(self, disabled)
			self.disabled = disabled
			if disabled then
				self.text:SetTextColor(0.5, 0.5, 0.5)
				self.button:Disable()
				self.button_cover:Disable()
				self.label:SetTextColor(0.5, 0.5, 0.5)
			else
				self.button:Enable()
				self.button_cover:Enable()
				self.label:SetTextColor(1, .82, 0)
				self.text:SetTextColor(1, 1, 1)
			end
		end,
		["ClearFocus"] = function(self)
			if self.open then
				self.pullout:Close()
			end
		end,
		["SetText"] = function(self, text)
			self.text:SetText(text or "")
		end,
		["SetLabel"] = function(self, text)
			if text and text ~= "" then
				self.label:SetText(text)
				self.label:Show()
				self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -14)
				self:SetHeight(40)
				--self.alignoffset = 26
			else
				self.label:SetText("")
				self.label:Hide()
				self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -15, 0)
				self:SetHeight(26)
				--self.alignoffset = 12
			end
		end,
		["SetValue"] = function(self, value)
			self:SetText(self.list[value] or "")
			self.value = value
		end,
		["GetValue"] = function(self)
			return self.value
		end,
		["SetItemValue"] = function(self, item, value)
			if not self.multiselect then return end
			for i, widget in self.pullout:IterateItems() do
				if widget.userdata.value == item then
					if widget.SetValue then
						widget:SetValue(value)
					end
				end
			end
			ShowMultiText(self)
		end,
		["SetItemDisabled"] = function(self, item, disabled)
			for i, widget in self.pullout:IterateItems() do
				if widget.userdata.value == item then
					widget:SetDisabled(disabled)
				end
			end
		end,
		["AddListItem"] = function(self, value, text, itemType)
			if not itemType then itemType = "Dropdown-Item-Toggle" end
			local exists = AceGUI:GetWidgetVersion(itemType)
			if not exists then
				error(
					("The given item type, %q, does not exist within AceGUI-3.0"):format(tostring(itemType)), 2)
			end

			local item = AceGUI:Create(itemType)
			item:SetText(text)
			item.userdata.obj = self
			item.userdata.value = value
			item:SetCallback("OnValueChanged", OnItemValueChanged)
			self.pullout:AddItem(item)
		end,
		["AddCloseButton"] = function(self)
			if not self.hasClose then
				local close = AceGUI:Create("Dropdown-Item-Execute")
				close:SetText("Close")
				self.pullout:AddItem(close)
				self.hasClose = true
			end
		end,
		["SetList"] = function(self, list, order, itemType)
			self.list = list or {}
			self.pullout:Clear()
			self.hasClose = nil
			if not list then return end

			if type(order) ~= "table" then
				for v in pairs(list) do
					sortlist[#sortlist + 1] = v
				end
				table.sort(sortlist, sortTbl)

				for i, key in ipairs(sortlist) do
					self:AddListItem(key, list[key], itemType)
					sortlist[i] = nil
				end
			else
				for i, key in ipairs(order) do
					self:AddListItem(key, list[key], itemType)
				end
			end
			if self.multiselect then
				ShowMultiText(self)
				self:AddCloseButton()
			end
		end,
		["AddItem"] = function(self, value, text, itemType)
			self.list[value] = text
			self:AddListItem(value, text, itemType)
		end,
		["SetMultiselect"] = function(self, multi)
			self.multiselect = multi
			if multi then
				ShowMultiText(self)
				self:AddCloseButton()
			end
		end,
		["GetMultiselect"] = function(self)
			return self.multiselect
		end,
		["SetPulloutWidth"] = function(self, width)
			self.pulloutWidth = width
		end,
	}

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

		local button_cover = CreateFrame("Button", nil, frame)
		button_cover:SetPoint("LEFT", frame, "LEFT")
		button_cover:SetPoint("RIGHT", frame, "RIGHT")
		button_cover:SetScript("OnEnter", HandleButtonEnter)
		button_cover:SetScript("OnLeave", HandleButtonLeave)
		button_cover:SetScript("OnClick", HandleToggleDropdownPullout)

		local text = _G[dropdown:GetName() .. "Text"]
		text:ClearAllPoints()

		text:SetPoint("LEFT", frame, "LEFT", textOffsetX, 0)
		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		if fPath then text:SetFont(fPath, fontSize, "OUTLINE") end

		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", frame, "LEFT", 0, 0)
		--label:SetJustifyH("LEFT")
		label:SetHeight(18)
		label:Hide()

		local widget     = {
			frame        = frame,
			type         = Type,
			count        = count,
			dropdown     = dropdown,
			text         = text,
			label        = label,
			button_cover = button_cover,
			button       = button,
		}

		frame.obj        = widget
		dropdown.obj     = widget
		text.obj         = widget
		button_cover.obj = widget
		button.obj       = widget

		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
