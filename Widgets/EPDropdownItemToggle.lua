local AceGUI            = LibStub("AceGUI-3.0")
local LSM               = LibStub("LibSharedMedia-3.0")

local textOffsetX       = 4
local checkOffsetLeftX  = -2
local checkOffsetRightX = -8
local checkSize         = 16
local fontSize          = 12

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

local EPItemBase = {
	-- NOTE: The ItemBase version is added to each item's version number
	--       to ensure proper updates on ItemBase changes.
	--       Use at least 1000er steps.
	version = 1000,
	counter = 0,
}

function EPItemBase.Frame_OnEnter(this)
	local self = this.obj

	if self.useHighlight then
		self.highlight:Show()
	end
	self:Fire("OnEnter")

	if self.specialOnEnter then
		self.specialOnEnter(self)
	end
end

function EPItemBase.Frame_OnLeave(this)
	local self = this.obj

	self.highlight:Hide()
	self:Fire("OnLeave")

	if self.specialOnLeave then
		self.specialOnLeave(self)
	end
end

-- exported, AceGUI callback
function EPItemBase.OnAcquire(self)
	self.frame:SetToplevel(true)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
end

-- exported, AceGUI callback
function EPItemBase.OnRelease(self)
	self:SetDisabled(false)
	self.pullout = nil
	self.frame:SetParent(nil)
	self.frame:ClearAllPoints()
	self.frame:Hide()
end

-- exported
-- NOTE: this is called by a Dropdown-Pullout.
--       Do not call this method directly
function EPItemBase.SetPullout(self, pullout)
	self.pullout = pullout

	self.frame:SetParent(nil)
	self.frame:SetParent(pullout.itemFrame)
	self.parent = pullout.itemFrame
	fixlevels(pullout.itemFrame, pullout.itemFrame:GetChildren())
end

-- exported
function EPItemBase.SetText(self, text)
	self.text:SetText(text or "")
end

-- exported
function EPItemBase.GetText(self)
	return self.text:GetText()
end

-- exported
function EPItemBase.SetPoint(self, ...)
	self.frame:SetPoint(...)
end

-- exported
function EPItemBase.Show(self)
	self.frame:Show()
end

-- exported
function EPItemBase.Hide(self)
	self.frame:Hide()
end

-- exported
function EPItemBase.SetDisabled(self, disabled)
	self.disabled = disabled
	if disabled then
		self.useHighlight = false
		self.text:SetTextColor(.5, .5, .5)
	else
		self.useHighlight = true
		self.text:SetTextColor(1, 1, 1)
	end
end

-- exported
-- NOTE: this is called by a Dropdown-Pullout.
--       Do not call this method directly
function EPItemBase.SetOnLeave(self, func)
	self.specialOnLeave = func
end

-- exported
-- NOTE: this is called by a Dropdown-Pullout.
--       Do not call this method directly
function EPItemBase.SetOnEnter(self, func)
	self.specialOnEnter = func
end

function EPItemBase.Create(type)
	local count = AceGUI:GetNextWidgetNum(type)
	local frame = CreateFrame("Button", "EPDropdownItemBase" .. count)
	local self = {}
	self.frame = frame
	frame.obj = self
	self.type = type
	self.useHighlight = true

	frame:SetHeight(20)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetPoint("TOPLEFT", frame, "TOPLEFT", textOffsetX, 0)
	text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", checkOffsetRightX, 0)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then text:SetFont(fPath, fontSize) end
	self.text = text

	local highlight = frame:CreateTexture("EPDropdownItemBase" .. count .. "Highlight", "OVERLAY")
	highlight:SetColorTexture(0.25, 0.25, 0.5, 0.5)
	highlight:SetTexelSnappingBias(0.0)
	highlight:SetSnapToPixelGrid(false)
	highlight:SetPoint("TOPLEFT", 0, 0)
	highlight:SetPoint("BOTTOMRIGHT", 0, 0)
	highlight:SetBlendMode("ADD")
	highlight:Hide()
	self.highlight = highlight

	local check = frame:CreateTexture("EPDropdownItemBase" .. count .. "Check", "OVERLAY")
	check:SetWidth(checkSize)
	check:SetHeight(checkSize)
	check:SetPoint("RIGHT", frame, "RIGHT", checkOffsetLeftX, 0)
	check:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-check-64]])
	check:Hide()
	self.check = check

	frame:SetScript("OnEnter", EPItemBase.Frame_OnEnter)
	frame:SetScript("OnLeave", EPItemBase.Frame_OnLeave)

	self.OnAcquire   = EPItemBase.OnAcquire
	self.OnRelease   = EPItemBase.OnRelease

	self.SetPullout  = EPItemBase.SetPullout
	self.GetText     = EPItemBase.GetText
	self.SetText     = EPItemBase.SetText
	self.SetDisabled = EPItemBase.SetDisabled

	self.SetPoint    = EPItemBase.SetPoint
	self.Show        = EPItemBase.Show
	self.Hide        = EPItemBase.Hide

	self.SetOnLeave  = EPItemBase.SetOnLeave
	self.SetOnEnter  = EPItemBase.SetOnEnter

	return self
end

do
	local widgetType = "EPDropdownItemToggle"
	local widgetVersion = 1

	local function UpdateToggle(self)
		if self.value then
			self.check:Show()
		else
			self.check:Hide()
		end
	end
	local function OnRelease(self)
		EPItemBase.OnRelease(self)
		self:SetValue(nil)
	end

	local function Frame_OnClick(this, button)
		local self = this.obj
		if self.disabled then return end
		self.value = not self.value
		if self.value then
			PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
		else
			PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
		end
		UpdateToggle(self)
		self:Fire("OnValueChanged", self.value)
	end

	-- exported
	local function SetValue(self, value)
		self.value = value
		UpdateToggle(self)
	end

	-- exported
	local function GetValue(self)
		return self.value
	end

	local function Constructor()
		local self = EPItemBase.Create(widgetType)

		self.frame:SetScript("OnClick", Frame_OnClick)

		self.SetValue = SetValue
		self.GetValue = GetValue
		self.OnRelease = OnRelease

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + EPItemBase.version)
end
