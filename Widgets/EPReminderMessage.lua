local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPReminderMessage"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetTime = GetTime
local next = next
local unpack = unpack

local k = {
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 200,
	DefaultTextPadding = 4,
	DefaultBackdropColor = { 0, 0, 0, 0 },
	AnchorModeBackdropColor = { 10.0 / 255.0, 10.0 / 255.0, 10.0 / 255.0, 0.25 },
	DefaultDisplayTime = 2,
	DefaultFadeDuration = 1.2,
	TimerTickRate = 0.1,
	TimeThreshold = 0.1,
	SecondsInMinute = 60.0,
	GreaterThanMinuteFormat = "%d:%02d",
	GreaterThanTenSecondsFormat = "%.0f",
	LessThanTenSecondsFormat = "%.1f",
	FrameBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = nil,
		tile = true,
		tileSize = 0,
		edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
}
k.SlightlyUnderSecondsInMinute = k.SecondsInMinute - k.TimeThreshold
k.SlightlyUnderTenSeconds = 10.0 - k.TimeThreshold

---@enum TimeThreshold
local TimeThreshold = {
	None = 0,
	OverHour = 1,
	OverMinute = 2,
	OverTenSeconds = 3,
	UnderTenSeconds = 4,
}

---@param self EPReminderMessage
local function UpdateFrameWidth(self)
	if self.showIcon then
		if self.countdownDuration > 0 then
			local textWidth = self.text:GetWidth() + self.durationText:GetWidth()
			self.frame:SetWidth(self.frame:GetHeight() + textWidth + self.horizontalTextPadding * 3)
		else
			self.frame:SetWidth(self.frame:GetHeight() + self.text:GetWidth() + self.horizontalTextPadding * 2)
		end
	else
		if self.countdownDuration > 0 then
			local textWidth = self.text:GetWidth() + self.durationText:GetWidth()
			self.frame:SetWidth(textWidth + self.horizontalTextPadding * 3)
		else
			self.frame:SetWidth(self.text:GetWidth() + self.horizontalTextPadding * 2)
		end
	end
end

---@param self EPReminderMessage
local function UpdateIconAndTextAnchors(self)
	self.icon:ClearAllPoints()
	self.text:ClearAllPoints()
	self.durationText:ClearAllPoints()

	local lineHeight = self.text:GetLineHeight()
	local showDuration = self.countdownDuration > 0
	local hasIcon = self.showIcon
	local horizontalPadding = self.horizontalTextPadding

	self.frame:SetHeight(lineHeight + horizontalPadding * 2)

	local durationWidth = showDuration and self.durationText:GetWidth() or 0
	local offset = 0
	if hasIcon then
		if showDuration then
			offset = (lineHeight - durationWidth) / 2.0
		else
			offset = (horizontalPadding + lineHeight) / 2.0
		end
	else
		if showDuration then
			offset = -(horizontalPadding + durationWidth) / 2.0
			-- else offset = 0
		end
	end
	self.text:SetPoint("CENTER", self.frame, "CENTER", offset, 0)

	if hasIcon then
		self.icon:SetSize(lineHeight, lineHeight)
		self.icon:SetPoint("RIGHT", self.text, "LEFT", -horizontalPadding, 0)
		self.icon:Show()
	else
		self.icon:Hide()
	end

	if showDuration then
		self.durationText:SetPoint("LEFT", self.text, "RIGHT", horizontalPadding, 0)
		self.durationText:Show()
	else
		self.durationText:Hide()
	end
end

local activeMessages = {} ---@type table<EPReminderMessage, boolean>

local sharedUpdater = CreateFrame("Frame"):CreateAnimationGroup()
sharedUpdater:SetLooping("REPEAT")

local repeater = sharedUpdater:CreateAnimation()
repeater:SetDuration(k.TimerTickRate)

local function SharedMessageUpdate()
	local currentTime = GetTime()
	for message in pairs(activeMessages) do
		if currentTime >= message.countdownDurationEndTime then
			activeMessages[message] = nil
			message.currentThreshold = TimeThreshold.None
			message.countdownDuration = 0
			message.countdownDurationEndTime = 0
			UpdateIconAndTextAnchors(message)
			UpdateFrameWidth(message)
		else
			local relativeTime = message.countdownDurationEndTime - currentTime
			message.countdownDuration = relativeTime
			if relativeTime <= k.SlightlyUnderTenSeconds then
				message.durationText:SetFormattedText(k.LessThanTenSecondsFormat, relativeTime)
				if message.currentThreshold ~= TimeThreshold.UnderTenSeconds then
					message.currentThreshold = TimeThreshold.UnderTenSeconds
					UpdateIconAndTextAnchors(message)
					UpdateFrameWidth(message)
				end
			elseif relativeTime <= k.SlightlyUnderSecondsInMinute then
				message.durationText:SetFormattedText(k.GreaterThanTenSecondsFormat, relativeTime)
				if message.currentThreshold ~= TimeThreshold.OverTenSeconds then
					message.currentThreshold = TimeThreshold.OverTenSeconds
					UpdateIconAndTextAnchors(message)
					UpdateFrameWidth(message)
				end
			else
				local minutes = floor(relativeTime / k.SecondsInMinute)
				local seconds = relativeTime - (minutes * k.SecondsInMinute)
				message.durationText:SetFormattedText(k.GreaterThanMinuteFormat, minutes, seconds)
				if message.currentThreshold ~= TimeThreshold.OverMinute then
					message.currentThreshold = TimeThreshold.OverMinute
					UpdateIconAndTextAnchors(message)
					UpdateFrameWidth(message)
				end
			end
		end
	end
	if not next(activeMessages) then
		sharedUpdater:Stop()
	end
end

sharedUpdater:SetScript("OnLoop", SharedMessageUpdate)

---@param self EPReminderMessage
local function OnAcquire(self)
	self.frame:Show()
end

---@param self EPReminderMessage
local function OnRelease(self)
	self.iconAnimationGroup:Stop()
	self.textAnimationGroup:Stop()
	self.countdownDuration = 0
	self.countdownDurationEndTime = 0
	self.currentThreshold = TimeThreshold.None
	self.running = false
	self:SetAnchorMode(false)
	self.icon:SetTexture(nil)
	self.showIcon = false
	self.horizontalTextPadding = k.DefaultTextPadding
end

---@param self EPReminderMessage
---@param iconID number|string|nil
local function SetIcon(self, iconID)
	self.icon:SetTexture(iconID)
	if iconID then
		self.showIcon = true
	else
		self.showIcon = false
	end
	UpdateIconAndTextAnchors(self)
end

---@param self EPReminderMessage
---@param text string
---@param paddingX number|nil
---@param fontFile string|nil
---@param size integer|nil
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"|nil
local function SetText(self, text, paddingX, fontFile, size, flags)
	self.text:SetText(text or "")
	self.horizontalTextPadding = paddingX or self.horizontalTextPadding
	if fontFile and size then
		self.text:SetFont(fontFile, size, flags)
		self.durationText:SetFont(fontFile, size, flags)
	end
	UpdateIconAndTextAnchors(self)
end

---@param self EPReminderMessage
---@param countdownDuration number
---@param holdDuration number
local function SetDuration(self, countdownDuration, holdDuration)
	self.countdownDuration = countdownDuration
	self.holdDuration = holdDuration
	if countdownDuration == 0.0 then
		self.durationText:SetText("")
		self.currentThreshold = TimeThreshold.None
	elseif countdownDuration <= k.SlightlyUnderTenSeconds then
		self.currentThreshold = TimeThreshold.UnderTenSeconds
		self.durationText:SetFormattedText(k.LessThanTenSecondsFormat, countdownDuration)
	elseif countdownDuration <= k.SlightlyUnderSecondsInMinute then
		self.currentThreshold = TimeThreshold.OverTenSeconds
		self.durationText:SetFormattedText(k.GreaterThanTenSecondsFormat, countdownDuration)
	else
		local minutes = floor(countdownDuration / k.SecondsInMinute)
		local seconds = countdownDuration - (minutes * k.SecondsInMinute)
		self.durationText:SetFormattedText(k.GreaterThanMinuteFormat, minutes, seconds)
		self.currentThreshold = TimeThreshold.OverMinute
	end
	UpdateIconAndTextAnchors(self)
	UpdateFrameWidth(self)
end

---@param self EPReminderMessage
---@param countdownDuration number
---@param holdDuration number
local function Start(self, countdownDuration, holdDuration)
	if self.running then
		return
	end

	self.iconAnimationGroup:Stop()
	self.textAnimationGroup:Stop()

	self.text:Show()
	SetDuration(self, countdownDuration, holdDuration)

	local fadeStartDelay = 0.0
	if self.countdownDuration == 0.0 then
		fadeStartDelay = self.holdDuration
	else
		fadeStartDelay = self.countdownDuration + self.holdDuration
	end

	self.textFade:SetStartDelay(fadeStartDelay)
	self.iconFade:SetStartDelay(fadeStartDelay)

	self.iconAnimationGroup:Play()
	self.textAnimationGroup:Play()

	if self.countdownDuration > 0.0 then
		self.countdownDurationEndTime = GetTime() + self.countdownDuration
		activeMessages[self] = true
		if not sharedUpdater:IsPlaying() then
			sharedUpdater:Play()
		end
	end

	self.running = true
end

---@param self EPReminderMessage
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
local function SetFont(self, fontFile, size, flags)
	if fontFile then
		self.text:SetFont(fontFile, size, flags)
		self.durationText:SetFont(fontFile, size, flags)
		UpdateIconAndTextAnchors(self)
	end
end

---@param self EPReminderMessage
---@param r number
---@param g number
---@param b number
---@param a number
local function SetTextColor(self, r, g, b, a)
	self.text:SetTextColor(r, g, b, a)
	self.durationText:SetTextColor(r, g, b, a)
end

---@param self EPReminderMessage
---@param alpha number
local function SetAlpha(self, alpha)
	self.frame:SetAlpha(alpha)
end

---@param self EPReminderMessage
---@param anchorMode boolean
local function SetAnchorMode(self, anchorMode)
	if anchorMode then
		self.frame:SetBackdropColor(unpack(k.AnchorModeBackdropColor))
	else
		self.frame:SetBackdropColor(unpack(k.DefaultBackdropColor))
	end
end

---@param self EPReminderMessage
---@param preferences MessagePreferences
---@param text string
---@param icon string|number|nil
local function Set(self, preferences, text, icon)
	self.text:SetText(text or "")
	if preferences.font and preferences.fontSize then
		self.text:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
		self.durationText:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
	end
	self.frame:SetAlpha(preferences.alpha)
	local r, g, b, a = unpack(preferences.textColor)
	self.text:SetTextColor(r, g, b, a)
	self.durationText:SetTextColor(r, g, b, a)
	if icon and preferences.showIcon == true then
		self.showIcon = true
		self.icon:SetTexture(icon)
	else
		self.showIcon = false
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.DefaultBackdropColor))
	frame:SetBackdropBorderColor(unpack(k.DefaultBackdropColor))

	local icon = frame:CreateTexture(Type .. "Icon" .. count, "ARTWORK")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)

	local durationText = frame:CreateFontString(Type .. "DurationText" .. count, "OVERLAY", "GameFontNormal")
	durationText:SetJustifyH("RIGHT")
	durationText:Hide()

	local textAnimationGroup = text:CreateAnimationGroup()
	local textFade = textAnimationGroup:CreateAnimation("Alpha")
	textFade:SetStartDelay(k.DefaultDisplayTime)
	textFade:SetDuration(k.DefaultFadeDuration)
	textFade:SetFromAlpha(1)
	textFade:SetToAlpha(0)

	local iconAnimationGroup = icon:CreateAnimationGroup()
	local iconFade = iconAnimationGroup:CreateAnimation("Alpha")
	iconFade:SetStartDelay(k.DefaultDisplayTime)
	iconFade:SetDuration(k.DefaultFadeDuration)
	iconFade:SetFromAlpha(1)
	iconFade:SetToAlpha(0)

	---@class EPReminderMessage : AceGUIWidget
	---@field showIcon boolean
	---@field horizontalTextPadding number
	---@field countdownDuration number A value of 0 indicates not to show the duration text.
	---@field holdDuration number
	---@field countdownDurationEndTime number
	---@field currentThreshold TimeThreshold
	---@field parent EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFont = SetFont,
		SetAnchorMode = SetAnchorMode,
		SetDuration = SetDuration,
		Start = Start,
		SetTextColor = SetTextColor,
		SetAlpha = SetAlpha,
		Set = Set,
		frame = frame,
		type = Type,
		count = count,
		icon = icon,
		text = text,
		durationText = durationText,
		showIcon = false,
		horizontalTextPadding = k.DefaultTextPadding,
		countdownDuration = 0,
		holdDuration = 0,
		countdownDurationEndTime = 0,
		currentThreshold = TimeThreshold.None,
		running = false,
		textFade = textFade,
		iconFade = iconFade,
		textAnimationGroup = textAnimationGroup,
		iconAnimationGroup = iconAnimationGroup,
	}

	textAnimationGroup:SetScript("OnFinished", function()
		widget.frame:Hide()
		widget.running = false
		widget:Fire("Completed")
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
