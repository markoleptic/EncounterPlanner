local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPProgressBar"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetTime = GetTime
local next = next
local pairs = pairs
local unpack = unpack

local k = {
	AnimationTickRate = 0.04,
	BackdropBorderColor = { 0, 0, 0, 1 },
	BackdropColor = { 0, 0, 0, 0 },
	DefaultBackgroundColor = { 0.05, 0.05, 0.05, 0.3 },
	DefaultColor = { 0.5, 0.5, 0.5, 1 },
	DefaultHeight = 24,
	DefaultWidth = 200,
	FrameBackdrop = {
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = false,
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	GreaterThanMinuteFormat = "%d:%02d",
	GreaterThanTenSecondsFormat = "%.0f",
	IconFrameBackdrop = {
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = false,
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	LessThanTenSecondsFormat = "%.1f",
	SecondsInMinute = 60.0,
	TimeThreshold = 0.1,
}
k.SlightlyUnderSecondsInMinute = k.SecondsInMinute - k.TimeThreshold
k.SlightlyUnderTenSeconds = 10.0 - k.TimeThreshold

local s = {
	ActiveBars = {}, ---@type table<EPProgressBar, boolean>
	SharedUpdater = CreateFrame("Frame"):CreateAnimationGroup(),
	TestFontString = UIParent:CreateFontString(nil, "OVERLAY"),
}
s.SharedUpdater:SetLooping("REPEAT")
s.Repeater = s.SharedUpdater:CreateAnimation()
s.Repeater:SetDuration(k.AnimationTickRate)
s.TestFontString:Hide()

local function SharedBarUpdate()
	local currentTime = GetTime()
	for bar in pairs(s.ActiveBars) do
		if currentTime >= bar.expirationTime then
			s.ActiveBars[bar] = nil
			bar.running = false
			bar.frame:Hide()
			bar:Fire("Completed")
		else
			local relativeTime = bar.expirationTime - currentTime
			bar.remaining = relativeTime
			bar.statusBar:SetValue(bar.fill and (currentTime - bar.startTime) + bar.gap or relativeTime)

			if relativeTime <= k.SlightlyUnderTenSeconds then
				bar.duration:SetFormattedText(k.LessThanTenSecondsFormat, relativeTime)
			elseif relativeTime <= k.SlightlyUnderSecondsInMinute then
				bar.duration:SetFormattedText(k.GreaterThanTenSecondsFormat, relativeTime)
			else
				local minutes = floor(relativeTime / k.SecondsInMinute)
				local seconds = relativeTime - (minutes * k.SecondsInMinute)
				bar.duration:SetFormattedText(k.GreaterThanMinuteFormat, minutes, seconds)
			end
		end
	end

	if not next(s.ActiveBars) then
		s.SharedUpdater:Stop()
	end
end

s.SharedUpdater:SetScript("OnLoop", SharedBarUpdate)

local kMinimumFontSize = 8

---@param text string
---@param font string
---@param fontHeight number
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
---@param maxWidth integer
---@return integer
local function CalculateFontSizeToFit(text, font, fontHeight, flags, maxWidth)
	s.TestFontString:SetFont(font, fontHeight, flags)
	s.TestFontString:SetText(text)

	if s.TestFontString:GetStringWidth() <= maxWidth then
		return fontHeight
	end

	local minSize = kMinimumFontSize
	local bestSize = minSize

	while minSize <= fontHeight do
		local mid = floor((minSize + fontHeight) / 2)
		s.TestFontString:SetFont(font, mid)
		local width = s.TestFontString:GetStringWidth()

		if width <= maxWidth then
			bestSize = mid
			minSize = mid + 1
		else
			fontHeight = mid - 1
		end
	end

	return bestSize
end

---@param text string
---@param font string?
---@param fontHeight number
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
---@return number
local function GetRequiredWidthForText(text, font, fontHeight, flags)
	if font then
		s.TestFontString:SetFont(font, fontHeight, flags)
	end
	s.TestFontString:SetText(text)
	return s.TestFontString:GetStringWidth()
end

---@param self EPProgressBar
local function RestyleBar(self)
	self.iconBackdrop:ClearAllPoints()
	self.statusBar:ClearAllPoints()

	local edgeSize = k.FrameBackdrop.edgeSize

	if self.iconTexture then
		self.iconBackdrop:SetWidth(self.frame:GetHeight())
		if self.iconPosition == "RIGHT" then
			self.iconBackdrop:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
			self.iconBackdrop:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT")
			self.statusBar:SetPoint("RIGHT", self.iconBackdrop, "LEFT")
			self.statusBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", edgeSize, -edgeSize)
			self.statusBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", edgeSize, edgeSize)
		else
			self.iconBackdrop:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
			self.iconBackdrop:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT")
			self.statusBar:SetPoint("LEFT", self.iconBackdrop, "RIGHT")
			self.statusBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -edgeSize, -edgeSize)
			self.statusBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -edgeSize, edgeSize)
		end
		self.iconBackdrop:Show()
		local iconEdgeSize = k.IconFrameBackdrop.edgeSize
		self.icon:SetPoint("TOPLEFT", iconEdgeSize, -iconEdgeSize)
		self.icon:SetPoint("BOTTOMRIGHT", -iconEdgeSize, iconEdgeSize)
	else
		self.statusBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", edgeSize, -edgeSize)
		self.statusBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -edgeSize, edgeSize)
		self.iconBackdrop:Hide()
	end

	self.label:ClearAllPoints()
	self.duration:ClearAllPoints()
	if self.label:GetJustifyH() == "LEFT" and self.duration:GetJustifyH() == "RIGHT" then
		local stringWidth = self.statusBar:GetWidth()
		local durationWidth = GetRequiredWidthForText("10.0", self.duration:GetFont()) - 2
		local labelWidth = stringWidth - durationWidth - 2
		self.label:SetWidth(labelWidth)
		self.duration:SetWidth(durationWidth)
		self.label:SetPoint("LEFT", self.statusBar, "LEFT", 2, 0)
		self.duration:SetPoint("RIGHT", self.statusBar, "RIGHT", -2, 0)
	elseif self.label:GetJustifyH() == "RIGHT" and self.duration:GetJustifyH() == "LEFT" then
		local stringWidth = self.statusBar:GetWidth()
		local durationWidth = GetRequiredWidthForText("10.0", self.duration:GetFont()) - 2
		local labelWidth = stringWidth - durationWidth - 2
		self.label:SetWidth(labelWidth)
		self.duration:SetWidth(durationWidth)
		self.duration:SetPoint("LEFT", self.statusBar, "LEFT", 2, 0)
		self.label:SetPoint("RIGHT", self.statusBar, "RIGHT", -2, 0)
	else
		self.label:SetPoint("LEFT", self.statusBar, "LEFT", 2, 0)
		self.label:SetPoint("RIGHT", self.statusBar, "RIGHT", -2, 0)
		self.duration:SetPoint("LEFT", self.statusBar, "LEFT", 2, 0)
		self.duration:SetPoint("RIGHT", self.statusBar, "RIGHT", -2, 0)
	end
end

---@param self EPProgressBar
local function OnAcquire(self)
	self.frame:Show()
end

---@param self EPProgressBar
local function OnRelease(self)
	self.fill = false
	self.remaining = 0
	self.expirationTime = 0
	self.startTime = 0
	self.running = false
	self.gap = 0
	self.iconPosition = "LEFT"
	self.iconTexture = nil
end

-- Requires that the text already be set.
---@param self EPProgressBar
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
---@param shrinkTextToFit boolean If true, the text will attempt to be shrunk to fit within the status bar.
local function SetFont(self, fontFile, size, flags, shrinkTextToFit)
	local labelFontSize, durationFontSize = size, size
	if fontFile then
		if shrinkTextToFit then
			local availableLabelWidth = self.frame:GetWidth() - 2
			local durationWidth = GetRequiredWidthForText("10.0", fontFile, durationFontSize, flags) - 2
			availableLabelWidth = availableLabelWidth - durationWidth - 2
			local frameHeight = self.frame:GetHeight()
			if self.iconTexture then
				availableLabelWidth = availableLabelWidth - frameHeight
			end

			labelFontSize =
				CalculateFontSizeToFit(self.label:GetText(), fontFile, labelFontSize, flags, availableLabelWidth)
		end
	end
	self.label:SetFont(fontFile, labelFontSize, flags)
	self.duration:SetFont(fontFile, durationFontSize, flags)
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param texture string|integer
---@param foregroundColor {[1]:number, [2]:number, [3]:number, [4]:number}
---@param backgroundColor {[1]:number, [2]:number, [3]:number, [4]:number}
local function SetTexture(self, texture, foregroundColor, backgroundColor)
	self.statusBar:SetStatusBarTexture(texture)
	self.background:SetTexture(texture)
	self:SetColor(unpack(foregroundColor))
	self:SetBackgroundColor(unpack(backgroundColor))
end

---@param self EPProgressBar
---@param r number
---@param g number
---@param b number
---@param a number
local function SetColor(self, r, g, b, a)
	self.statusBar:SetStatusBarColor(r, g, b, a)
end

---@param self EPProgressBar
---@param r number
---@param g number
---@param b number
---@param a number
local function SetBackgroundColor(self, r, g, b, a)
	self.background:SetVertexColor(r, g, b, a)
end

---@param self EPProgressBar
---@param show boolean
local function SetShowBorder(self, show)
	self.frame:ClearBackdrop()
	if show then
		k.FrameBackdrop.edgeSize = 1
		self.frame:SetBackdrop(k.FrameBackdrop)
		self.frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	else
		k.FrameBackdrop.edgeSize = 0
	end
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param show boolean
local function SetShowIconBorder(self, show)
	self.iconBackdrop:ClearBackdrop()
	if show then
		k.IconFrameBackdrop.edgeSize = 1
		self.iconBackdrop:SetBackdrop(k.IconFrameBackdrop)
		self.iconBackdrop:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	else
		k.IconFrameBackdrop.edgeSize = 0
	end
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param duration number
local function SetDuration(self, duration)
	self.remaining = duration
end

---@param self EPProgressBar
---@param icon string|integer|nil
---@param text string
local function SetIconAndText(self, icon, text)
	self.iconTexture = icon
	self.label:SetText(text)
	self.icon:SetTexture(icon)
	self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

---@param self EPProgressBar
---@param alignment "LEFT"|"RIGHT"
local function SetDurationTextAlignment(self, alignment)
	self.duration:SetJustifyH(alignment)
	if alignment == "LEFT" then
		self.label:SetJustifyH("RIGHT")
	else
		self.label:SetJustifyH("LEFT")
	end
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param alignment "LEFT"|"RIGHT"
local function SetIconPosition(self, alignment)
	self.iconPosition = alignment
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param fill boolean
local function SetFill(self, fill)
	self.fill = fill
end

---@param self EPProgressBar
---@param alpha number
local function SetAlpha(self, alpha)
	self.frame:SetAlpha(alpha)
end

---@param self EPProgressBar
---@param preferences ProgressBarPreferences
---@param text string
---@param duration number
---@param icon string|number|nil
local function Set(self, preferences, text, duration, icon)
	self.frame:SetSize(preferences.width, preferences.height)
	self.duration:SetJustifyH(preferences.durationAlignment)
	if preferences.durationAlignment == "LEFT" then
		self.label:SetJustifyH("RIGHT")
	else
		self.label:SetJustifyH("LEFT")
	end
	self.frame:ClearBackdrop()
	if preferences.showBorder then
		k.FrameBackdrop.edgeSize = 1
		self.frame:SetBackdrop(k.FrameBackdrop)
		self.frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	else
		k.FrameBackdrop.edgeSize = 0
	end
	self.iconBackdrop:ClearBackdrop()
	if preferences.showIconBorder then
		k.IconFrameBackdrop.edgeSize = 1
		self.iconBackdrop:SetBackdrop(k.IconFrameBackdrop)
		self.iconBackdrop:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	else
		k.IconFrameBackdrop.edgeSize = 0
	end
	self.statusBar:SetStatusBarTexture(preferences.texture)
	self.background:SetTexture(preferences.texture)
	self:SetColor(unpack(preferences.color))
	self:SetBackgroundColor(unpack(preferences.backgroundColor))
	self.iconPosition = preferences.iconPosition
	self.fill = preferences.fill
	self.frame:SetAlpha(preferences.alpha)
	self.remaining = duration
	self.iconTexture = icon
	self.icon:SetTexture(icon)
	self.label:SetText(text)
	SetFont(self, preferences.font, preferences.fontSize, preferences.fontOutline, preferences.shrinkTextToFit)
end

---@param self EPProgressBar
---@param maxValue? number
local function Start(self, maxValue)
	if self.running then
		return
	end
	RestyleBar(self)

	self.running = true
	local time = self.remaining
	self.gap = maxValue and maxValue - time or 0
	self.startTime = GetTime()
	self.expirationTime = self.startTime + time

	self.statusBar:SetMinMaxValues(0, maxValue or time)
	self.statusBar:SetValue(self.fill and 0 or time)

	s.ActiveBars[self] = true

	if not s.SharedUpdater:IsPlaying() then
		s.SharedUpdater:Play()
	end
end

---@param self EPProgressBar
---@param width number
local function SetProgressBarSize(self, width, height)
	self.frame:SetSize(width, height)
	if self.running then
		RestyleBar(self)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(100)
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))

	local statusBar = CreateFrame("StatusBar", Type .. "StatusBar" .. count, frame)
	statusBar:SetStatusBarColor(unpack(k.DefaultColor))
	statusBar:SetSize(k.DefaultWidth, k.DefaultHeight)

	local background = statusBar:CreateTexture(nil, "BACKGROUND")
	background:SetVertexColor(unpack(k.DefaultBackgroundColor))
	background:SetAllPoints()

	local iconBackdrop = CreateFrame("Frame", Type .. "IconBackdrop" .. count, frame, "BackdropTemplate")
	iconBackdrop:SetBackdrop(k.IconFrameBackdrop)
	iconBackdrop:SetBackdropColor(unpack(k.BackdropColor))
	iconBackdrop:SetBackdropBorderColor(unpack(k.BackdropBorderColor))

	local icon = iconBackdrop:CreateTexture()
	icon:SetPoint("TOPLEFT")
	icon:SetPoint("BOTTOMRIGHT")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local label = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
	label:SetPoint("LEFT", statusBar, "LEFT", 2, 0)
	label:SetPoint("RIGHT", statusBar, "RIGHT", -2, 0)
	label:SetWordWrap(false)
	label:SetJustifyH("LEFT")
	label:SetJustifyV("MIDDLE")

	local duration = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
	duration:SetPoint("LEFT", statusBar, "LEFT", 2, 0)
	duration:SetPoint("RIGHT", statusBar, "RIGHT", -2, 0)
	duration:SetWordWrap(false)
	duration:SetJustifyH("RIGHT")
	duration:SetJustifyV("MIDDLE")

	---@class EPProgressBar : AceGUIWidget
	---@field fill boolean
	---@field remaining number
	---@field expirationTime number
	---@field startTime number
	---@field running boolean
	---@field gap number
	---@field iconPosition "LEFT"|"RIGHT"
	---@field iconTexture string|integer|nil
	---@field parent EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetFont = SetFont,
		SetTexture = SetTexture,
		SetColor = SetColor,
		SetBackgroundColor = SetBackgroundColor,
		SetDuration = SetDuration,
		SetIconAndText = SetIconAndText,
		Start = Start,
		SetDurationTextAlignment = SetDurationTextAlignment,
		SetIconPosition = SetIconPosition,
		SetFill = SetFill,
		SetProgressBarSize = SetProgressBarSize,
		SetShowBorder = SetShowBorder,
		SetShowIconBorder = SetShowIconBorder,
		SetAlpha = SetAlpha,
		RestyleBar = RestyleBar,
		Set = Set,
		frame = frame,
		type = Type,
		count = count,
		statusBar = statusBar,
		background = background,
		icon = icon,
		iconBackdrop = iconBackdrop,
		duration = duration,
		label = label,
		fill = false,
		remaining = 0,
		expirationTime = 0,
		startTime = 0,
		running = false,
		gap = 0,
		iconPosition = "LEFT",
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
