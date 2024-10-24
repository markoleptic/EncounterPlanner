local AceGUI             = LibStub("AceGUI-3.0")
local LSM                = LibStub("LibSharedMedia-3.0")

local textOffsetX        = 4
local checkOffsetLeftX   = -2
local checkOffsetRightX  = -8
local checkSize          = 16
local fontSize           = 12
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
	frame:SetHeight(20)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetScript("OnEnter", HandleItemBaseFrameEnter)
	frame:SetScript("OnLeave", HandleItemBaseFrameLeave)

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetPoint("TOPLEFT", frame, "TOPLEFT", textOffsetX, 0)
	text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", checkOffsetRightX, 0)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then text:SetFont(fPath, fontSize) end

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
	sub:SetWidth(16)
	sub:SetHeight(16)
	sub:SetPoint("RIGHT", frame, "RIGHT", -3, -1)
	sub:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-dropdown-96]])
	sub:SetRotation(math.pi / 2)
	sub:Hide()

	---@class EPItemBase
	local widget = {
		frame        = frame,
		type         = type,
		useHighlight = true,
		check        = check,
		sub          = sub,
		highlight    = highlight,
		text         = text,
		OnAcquire    = EPItemBase.OnAcquire,
		OnRelease    = EPItemBase.OnRelease,
		SetPullout   = EPItemBase.SetPullout,
		GetText      = EPItemBase.GetText,
		SetText      = EPItemBase.SetText,
		SetDisabled  = EPItemBase.SetDisabled,
		SetPoint     = EPItemBase.SetPoint,
		Show         = EPItemBase.Show,
		Hide         = EPItemBase.Hide,
		SetOnLeave   = EPItemBase.SetOnLeave,
		SetOnEnter   = EPItemBase.SetOnEnter
	}

	frame.obj = widget

	return widget
end

---@class EPDropdownItemToggle : EPItemBase
---@field value any
do
	local widgetType = "EPDropdownItemToggle"
	local widgetVersion = 1

	---@param dropdownItemToggle EPDropdownItemToggle
	local function UpdateToggle(dropdownItemToggle)
		if dropdownItemToggle.value then
			dropdownItemToggle.check:Show()
		else
			dropdownItemToggle.check:Hide()
		end
	end

	local function HandleFrameClick(frame, _)
		local self = frame.obj
		if self.disabled then return end
		self.value = not self.value
		if self.value then
			PlaySound(856)
		else
			PlaySound(857)
		end
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
	local function OnRelease(self)
		EPItemBase.OnRelease(self)
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
		widget.SetValue = SetValue
		widget.GetValue = GetValue
		widget.OnRelease = OnRelease
		AceGUI:RegisterAsWidget(widget)
		return widget
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end

---@class EPDropdownItemMenu : EPItemBase
---@field submenu EPDropdownPullout
---@field value any
---@field multiselect boolean|nil
do
	local widgetType = "EPDropdownItemMenu"
	local widgetVersion = 1

	---@param dropdownItemMenu EPDropdownItemMenu
	local function ShowMultiText(dropdownItemMenu)
		local text
		for _, widget in dropdownItemMenu.submenu:IterateItems() --[[@as EPDropdownItemToggle]] do
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
		dropdownItemMenu:SetText(text)
	end

	local function HandleFrameEnter(frame)
		local self = frame.obj
		self:Fire("OnEnter")
		if self.specialOnEnter then
			self.specialOnEnter(self)
		end
		self.highlight:Show()
		if not self.disabled and self.submenu then
			self.submenu:Open("TOPLEFT", self.frame, "TOPRIGHT", 0, 0, self.frame:GetFrameLevel() + 100)
		end
	end

	local function HandleFrameHide(frame)
		local self = frame.obj
		if self.submenu then
			self.submenu:Close()
		end
	end

	local function HandlePulloutOpen(frame)
		local self = frame.userdata.obj
		local value = self.userdata.value
		if not self.multiselect then
			for _, item in frame:IterateItems() do
				item:SetValue(item.userdata.value == value)
			end
		end
		self.open = true
		self:Fire("OnOpened")
	end

	local function HandlePulloutClose(frame)
		local self = frame.userdata.obj
		self.open = nil
		self:Fire("OnClosed")
	end

	local function HandleItemValueChanged(frame, event, checked)
		local self = frame.userdata.menuObj
		if self.multiselect then
			self:Fire("OnValueChanged", frame.userdata.value, checked)
			ShowMultiText(self)
		else
			if checked then
				self.userdata.value = frame.userdata.value
				self:SetValue(frame.userdata.value)
				self:Fire("OnValueChanged", checked)
			else
				frame:SetValue(true)
			end
			if self.open then
				self.pullout:Close()
			end
		end
	end

	---@param self EPDropdownItemMenu
	---@param pulloutItems table<integer, EPItemBase>
	local function SetMenuItems(self, pulloutItems)
		self.submenu = AceGUI:Create("EPDropdownPullout") --[[@as EPDropdownPullout]]
		self.submenu.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		self.submenu:GetUserDataTable().obj = self
		self.submenu:SetCallback("OnClose", HandlePulloutClose)
		self.submenu:SetCallback("OnOpen", HandlePulloutOpen)
		for _, v in pairs(pulloutItems) do
			self.submenu:AddItem(v)
			v:GetUserDataTable().menuObj = self
			v:SetCallback("OnValueChanged", HandleItemValueChanged)
		end
		fixlevels(self.submenu.frame, self.submenu.frame:GetChildren())
	end

	---@param self EPDropdownItemMenu
	local function CloseMenu(self)
		self.submenu:Close()
	end

	---@param self EPDropdownItemMenu
	---@param value any
	local function SetValue(self, value)
		self.value = value
		if self.value then
			self.sub:SetVertexColor(unpack(checkedVertexColor))
		else
			self.sub:SetVertexColor(1, 1, 1, 1)
		end
		for _, item in self.submenu:IterateItems() --[[@as EPDropdownItemToggle]] do
			item:SetValue(item:GetUserDataTable().value == value)
		end
	end

	---@param self EPDropdownItemMenu
	local function GetValue(self)
		return self.value
	end

	---@param self EPDropdownItemMenu
	local function OnRelease(self)
		if self.submenu then
			self.submenu:Release()
		end
		EPItemBase.OnRelease(self)
		self:SetValue(nil)
	end

	local function Constructor()
		---@class EPDropdownItemMenu
		local widget = EPItemBase.Create(widgetType)
		widget.sub:Show()
		widget.frame:SetScript("OnEnter", HandleFrameEnter)
		widget.frame:SetScript("OnHide", HandleFrameHide)
		widget.SetValue     = SetValue
		widget.GetValue     = GetValue
		widget.OnRelease    = OnRelease
		widget.SetMenuItems = SetMenuItems
		widget.CloseMenu    = CloseMenu
		AceGUI:RegisterAsWidget(widget)
		return widget
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end
