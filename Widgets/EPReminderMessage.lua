local _, Namespace = ...
local L = Namespace.L

local Type = "EPReminderMessage"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent

local ceil = math.ceil
local CreateFrame = CreateFrame
local floor = math.floor
local GetTime = GetTime
local NewTicker = C_Timer.NewTicker
local unpack = unpack

local defaultFrameHeight = 24
local defaultFrameWidth = 200
local defaultTextPadding = 4
local defaultBackdropColor = { 0, 0, 0, 0 }
local anchorModeBackdropColor = { 0.1, 0.1, 0.1, 0.25 }
local defaultDisplayTime = 2
local defaultFadeDuration = 1.2
local timerTickRate = 0.1
local timeThreshold = 0.1
local secondsInHour = 3600.0
local secondsInMinute = 60.0
local slightlyUnderSecondsInHour = secondsInHour - timeThreshold
local slightlyUnderSecondsInMinute = secondsInMinute - timeThreshold
local slightlyUnderTenSeconds = 10.0 - timeThreshold
local greaterThanHourFormat = "%d:%02d:%02d"
local greaterThanMinuteFormat = "%d:%02d"
local greaterThanTenSecondsFormat = "%.0f"
local fallbackFormat = "%.1f"
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = nil,
	tile = true,
	tileSize = 0,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local previousPointDetails = {}

---@param self EPReminderMessage
local function HandleFrameMouseDown(self, button)
	if button == "LeftButton" then
		local point, relativeTo, relativePoint, _, _ = self.frame:GetPoint()
		previousPointDetails = {
			point = point,
			relativeTo = relativeTo:GetName(),
			relativePoint = relativePoint,
		}
		self.frame:StartMoving()
	end
end

---@param self EPReminderMessage
local function HandleFrameMouseUp(self, button)
	if button == "LeftButton" then
		self.frame:StopMovingOrSizing()
		local point = previousPointDetails.point
		local relativeFrame = previousPointDetails.relativeTo
		local relativePoint = previousPointDetails.relativePoint
		self:Fire("NewPoint", point, relativeFrame, relativePoint)
	end
end

local scaleUpTime, scaleDownTime = 0.2, 0.4
local scaleDownMinusScaleUp = scaleDownTime - scaleUpTime
---@param self EPReminderMessage
local function BounceAnimation(self, elapsed, minSize, maxSize, sizeDiff, minIconSize)
	if elapsed <= scaleUpTime then
		local value = floor(minSize + (sizeDiff * elapsed / scaleUpTime))
		self.text:SetTextHeight(value)
		self.duration:SetTextHeight(value)
		local iconValue = value / minSize * minIconSize
		self.icon:SetSize(iconValue, iconValue)
	elseif elapsed <= scaleDownTime then
		local value = floor(maxSize - (sizeDiff * (elapsed - scaleUpTime) / scaleDownMinusScaleUp))
		self.text:SetTextHeight(value)
		self.duration:SetTextHeight(value)
		local iconValue = value / minSize * minIconSize
		self.icon:SetSize(iconValue, iconValue)
	else
		self.text:SetTextHeight(minSize)
		self.duration:SetTextHeight(minSize)
		self.icon:SetSize(minIconSize, minIconSize)
		self.textAnimationGroup:SetScript("OnUpdate", nil)
	end
end

---@param self EPReminderMessage
local function UpdateFrameWidth(self)
	if self.showIcon then
		if self.remaining > 0 then
			local stringWidth = self.text:GetStringWidth() + self.duration:GetStringWidth()
			self.frame:SetWidth(self.frame:GetHeight() + stringWidth + self.horizontalTextPadding * 3)
		else
			self.frame:SetWidth(self.frame:GetHeight() + self.text:GetStringWidth() + self.horizontalTextPadding * 2)
		end
	else
		if self.remaining > 0 then
			local stringWidth = self.text:GetStringWidth() + self.duration:GetStringWidth()
			self.frame:SetWidth(stringWidth + self.horizontalTextPadding * 3)
		else
			self.frame:SetWidth(self.text:GetStringWidth() + self.horizontalTextPadding * 2)
		end
	end
end

---@param self EPReminderMessage
local function TextUpdate(self)
	local currentTime = GetTime()
	if currentTime >= self.expirationTime then
		self.durationTicker:Cancel()
		self.running = false
		self.currentThreshold = ""
		self.iconAnimationGroup:Stop()
		self.textAnimationGroup:Stop()
		self.textAnimationGroup:SetScript("OnUpdate", nil)
		self:Fire("Completed")
	else
		local relativeTime = self.expirationTime - currentTime
		self.remaining = relativeTime
		if relativeTime > slightlyUnderSecondsInHour then
			local h = floor(relativeTime / secondsInHour)
			local m = floor((relativeTime - (h * secondsInHour)) / secondsInMinute)
			local s = (relativeTime - (m * secondsInMinute)) - (h * secondsInHour)
			self.duration:SetFormattedText(greaterThanHourFormat, h, m, s)
		elseif relativeTime > slightlyUnderSecondsInMinute then
			local m = floor(relativeTime / secondsInMinute)
			local s = relativeTime - (m * secondsInMinute)
			self.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
			if self.currentThreshold ~= "OverMinute" then
				self.currentThreshold = "OverMinute"
				UpdateFrameWidth(self)
			end
		elseif relativeTime > slightlyUnderTenSeconds then
			self.duration:SetFormattedText(greaterThanTenSecondsFormat, relativeTime)
			if self.currentThreshold ~= "OverTenSeconds" then
				self.currentThreshold = "OverTenSeconds"
				UpdateFrameWidth(self)
			end
		else
			self.duration:SetFormattedText(fallbackFormat, relativeTime)
			if self.currentThreshold ~= "UnderTenSeconds" then
				self.currentThreshold = "UnderTenSeconds"
				UpdateFrameWidth(self)
			end
		end
	end
end

---@param self EPReminderMessage
local function UpdateIconAndTextAnchors(self)
	self.icon:ClearAllPoints()
	self.text:ClearAllPoints()
	self.duration:ClearAllPoints()

	local lineHeight = self.text:GetLineHeight()
	local hasDuration = self.remaining > 0
	local hasIcon = self.showIcon
	local horizontalPadding = self.horizontalTextPadding

	self.frame:SetHeight(lineHeight + horizontalPadding * 2)

	local durationWidth = hasDuration and self.duration:GetStringWidth() or 0
	local iconWidth = hasIcon and lineHeight or 0
	local textWidth = self.text:GetStringWidth()
	local totalWidth = textWidth + iconWidth + durationWidth

	local offset, paddingCount
	if hasIcon then
		offset = hasDuration and (lineHeight - durationWidth) / 2.0 or (horizontalPadding + lineHeight) / 2.0
		paddingCount = hasDuration and 4 or 3
	else
		offset = hasDuration and -(horizontalPadding + durationWidth) / 2.0 or 0
		paddingCount = hasDuration and 3 or 2
	end

	self.frame:SetWidth(totalWidth * 1.4 + horizontalPadding * paddingCount)
	self.text:SetPoint("CENTER", self.frame, "CENTER", offset, 0)

	if hasIcon then
		self.icon:SetSize(lineHeight, lineHeight)
		self.icon:SetPoint("RIGHT", self.text, "LEFT", -horizontalPadding, 0)
		self.icon:Show()
	else
		self.icon:Hide()
	end

	if hasDuration then
		self.duration:SetPoint("LEFT", self.text, "RIGHT", horizontalPadding, 0)
		self.duration:Show()
	else
		self.duration:Hide()
	end
end

---@class EPReminderMessage : AceGUIWidget
---@field frame Frame|table
---@field type string
---@field text FontString
---@field duration FontString
---@field highlight Texture
---@field icon Texture|nil
---@field showIcon boolean
---@field horizontalTextPadding number
---@field remaining number
---@field expirationTime number
---@field durationTicker FunctionContainer|nil
---@field currentThreshold "OverHour"|"OverMinute"|"OverTenSeconds"|"UnderTenSeconds"|""
---@field running boolean
---@field paused number|nil
---@field parent EPContainer

---@param self EPReminderMessage
local function OnAcquire(self)
	self.frame:SetFrameStrata("MEDIUM")
	self.frame:SetFrameLevel(100)
	self.frame:Show()
	self.text:Show()
end

---@param self EPReminderMessage
local function OnRelease(self)
	if self.durationTicker then
		self.durationTicker:Cancel()
	end
	self.iconAnimationGroup:Stop()
	self.textAnimationGroup:Stop()
	self.textAnimationGroup:SetScript("OnUpdate", nil)
	self.durationTicker = nil
	self.remaining = 0
	self.expirationTime = 0
	self.currentThreshold = ""
	self.running = false
	self.paused = nil
	self:SetAnchorMode(false)
	self:SetIcon(nil)
	self:SetAlpha(1.0)
	self.horizontalTextPadding = defaultTextPadding
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
		self.duration:SetFont(fontFile, size, flags)
	end
	UpdateIconAndTextAnchors(self)
end

---@param self EPReminderMessage
---@param duration number
local function SetDuration(self, duration)
	self.remaining = duration
	UpdateIconAndTextAnchors(self)
end

---@param self EPReminderMessage
---@param showCountdown boolean
local function Start(self, showCountdown)
	if self.running and not self.paused then
		return
	end

	UpdateIconAndTextAnchors(self)

	self.iconAnimationGroup:Stop()
	self.textAnimationGroup:Stop()

	self.textFade:SetFromAlpha(self.text:GetAlpha())
	self.iconFade:SetFromAlpha(self.icon:GetAlpha())

	local totalElapsed = 0
	local _, minSize, _ = self.text:GetFont()
	local maxSize = minSize + 10
	local minIconSize = self.icon:GetWidth()
	self.textAnimationGroup:SetScript("OnUpdate", function(_, elapsed)
		totalElapsed = totalElapsed + elapsed
		BounceAnimation(self, totalElapsed, minSize, maxSize, 10, minIconSize)
	end)

	if not showCountdown then
		self.textFade:SetStartDelay(defaultDisplayTime)
		self.iconFade:SetStartDelay(defaultDisplayTime)
	else
		self.textFade:SetStartDelay(self.remaining + defaultDisplayTime)
		self.iconFade:SetStartDelay(self.remaining + defaultDisplayTime)
	end

	self.iconAnimationGroup:Play()
	self.textAnimationGroup:Play()

	self.running = true
	self.paused = nil

	if not showCountdown then
		return
	end

	local time = self.remaining
	self.expirationTime = GetTime() + time

	if time > slightlyUnderSecondsInHour then
		local h = floor(time / secondsInHour)
		local m = floor((time - (h * secondsInHour)) / secondsInMinute)
		local s = (time - (m * secondsInMinute)) - (h * secondsInHour)
		self.duration:SetFormattedText(greaterThanHourFormat, h, m, s)
		self.currentThreshold = "OverHour"
	elseif time > slightlyUnderSecondsInMinute then
		local m = floor(time / secondsInMinute)
		local s = time - (m * secondsInMinute)
		self.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
		self.currentThreshold = "OverMinute"
	elseif time > slightlyUnderTenSeconds then
		self.currentThreshold = "OverTenSeconds"
		self.duration:SetFormattedText(greaterThanTenSecondsFormat, time)
	else
		self.currentThreshold = "UnderTenSeconds"
		self.duration:SetFormattedText(fallbackFormat, time)
	end

	local iterations = ceil(time / timerTickRate) + 1
	self.durationTicker = NewTicker(timerTickRate, function()
		TextUpdate(self)
	end, iterations)
end

---@param self EPReminderMessage
local function Pause(self)
	if not self.paused then
		if self.durationTicker then
			self.durationTicker:Cancel()
		end
		self.iconAnimationGroup:Pause()
		self.textAnimationGroup:Pause()
		self.paused = GetTime()
	end
end

---@param self EPReminderMessage
local function Resume(self)
	if self.paused then
		local time = GetTime()
		if self.expirationTime > 0 then
			self.expirationTime = time + self.remaining
			local iterations = ceil(self.remaining / timerTickRate) + 1
			self.durationTicker = NewTicker(timerTickRate, function()
				TextUpdate(self)
			end, iterations)
		end
		self.iconAnimationGroup:Play(false, self.iconAnimationGroup:GetElapsed())
		self.textAnimationGroup:Play(false, self.textAnimationGroup:GetElapsed())
		self.paused = nil
	end
end

---@param self EPReminderMessage
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
local function SetFont(self, fontFile, size, flags)
	if fontFile then
		self.text:SetFont(fontFile, size, flags)
		self.duration:SetFont(fontFile, size, flags)
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
	self.duration:SetTextColor(r, g, b, a)
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
		self:SetText(L["Cast spell or something"])
		self.frame:SetBackdropColor(unpack(anchorModeBackdropColor))
		self.frame:SetMovable(true)
		self.frame:SetScript("OnMouseDown", function(_, button)
			HandleFrameMouseDown(self, button)
		end)
		self.frame:SetScript("OnMouseUp", function(_, button)
			HandleFrameMouseUp(self, button)
		end)
		UpdateIconAndTextAnchors(self)
	else
		self:SetText("")
		self.frame:SetBackdropColor(unpack(defaultBackdropColor))
		self.frame:SetMovable(false)
		self.frame:SetScript("OnMouseDown", nil)
		self.frame:SetScript("OnMouseUp", nil)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(defaultBackdropColor))
	frame:SetBackdropBorderColor(unpack(defaultBackdropColor))

	local icon = frame:CreateTexture(Type .. "Icon" .. count, "ARTWORK")

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	text:SetJustifyH("CENTER")
	text:SetWordWrap(false)

	local duration = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	duration:SetJustifyH("RIGHT")
	duration:Hide()

	local textAnimationGroup = frame:CreateAnimationGroup()
	local textFade = textAnimationGroup:CreateAnimation("Alpha")
	textFade:SetStartDelay(defaultDisplayTime)
	textFade:SetDuration(defaultFadeDuration)
	textFade:SetFromAlpha(1)
	textFade:SetToAlpha(0)

	local iconAnimationGroup = icon:CreateAnimationGroup()
	local iconFade = iconAnimationGroup:CreateAnimation("Alpha")
	iconFade:SetStartDelay(defaultDisplayTime)
	iconFade:SetDuration(defaultFadeDuration)
	iconFade:SetFromAlpha(1)
	iconFade:SetToAlpha(0)

	---@class EPReminderMessage
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFont = SetFont,
		GetText = GetText,
		SetAnchorMode = SetAnchorMode,
		SetDuration = SetDuration,
		Start = Start,
		Pause = Pause,
		Resume = Resume,
		SetTextColor = SetTextColor,
		SetAlpha = SetAlpha,
		frame = frame,
		type = Type,
		icon = icon,
		text = text,
		duration = duration,
		showIcon = false,
		horizontalTextPadding = defaultTextPadding,
		remaining = 0,
		expirationTime = 0,
		currentThreshold = "",
		running = false,
		textFade = textFade,
		iconFade = iconFade,
		textAnimationGroup = textAnimationGroup,
		iconAnimationGroup = iconAnimationGroup,
	}

	textAnimationGroup:SetScript("OnFinished", function()
		widget.text:Hide()
		widget.icon:Hide()
		if widget.expirationTime == 0 then
			widget:Fire("Completed")
		end
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
