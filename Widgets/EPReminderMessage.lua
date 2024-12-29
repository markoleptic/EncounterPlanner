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
			relativeTo = relativeTo,
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
		local relativeFrame = previousPointDetails.relativeTo or UIParent
		local relativePoint = previousPointDetails.relativePoint
		self:Fire("NewPoint", point, relativeFrame, relativePoint)
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
	self.frame:SetHeight(lineHeight + self.horizontalTextPadding * 2)

	if self.showIcon then
		if self.remaining > 0 then
			local stringWidth = self.text:GetStringWidth() + self.duration:GetStringWidth()
			self.frame:SetWidth(self.frame:GetHeight() + stringWidth + self.horizontalTextPadding * 3)
			self.duration:SetPoint("RIGHT", self.frame, "RIGHT", -self.horizontalTextPadding, 0)
			self.duration:Show()
		else
			self.frame:SetWidth(self.frame:GetHeight() + self.text:GetStringWidth() + self.horizontalTextPadding * 3)
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.horizontalTextPadding, 0)
			self.duration:Hide()
		end
		self.icon:SetPoint("LEFT", self.frame, "LEFT", self.horizontalTextPadding, 0)
		self.icon:SetSize(lineHeight, lineHeight)
		self.text:SetPoint("LEFT", self.icon, "RIGHT", self.horizontalTextPadding, 0)
		self.icon:Show()
	else
		if self.remaining > 0 then
			local stringWidth = self.text:GetStringWidth() + self.duration:GetStringWidth()
			self.frame:SetWidth(stringWidth + self.horizontalTextPadding * 3)
			self.duration:SetPoint("RIGHT", self.frame, "RIGHT", -self.horizontalTextPadding, 0)
			self.duration:Show()
		else
			self.frame:SetWidth(self.text:GetStringWidth() + self.horizontalTextPadding * 2)
			self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.horizontalTextPadding, 0)
			self.duration:Hide()
		end
		self.text:SetPoint("LEFT", self.frame, "LEFT", self.horizontalTextPadding, 0)
		self.icon:Hide()
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

---@param self EPReminderMessage
local function OnAcquire(self)
	self.frame:SetFrameStrata("MEDIUM")
	self.frame:SetFrameLevel(100)
	self.frame:Show()
end

---@param self EPReminderMessage
local function OnRelease(self)
	if self.durationTicker then
		self.durationTicker:Cancel()
	end
	self.durationTicker = nil
	self.remaining = 0
	self.expirationTime = 0
	self.currentThreshold = ""
	self.running = false
	self.paused = nil
	self:SetAnchorMode(false)
	self:SetIcon(nil)
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
local function Start(self)
	if self.running and not self.paused then
		return
	end

	local time = self.remaining
	self.expirationTime = GetTime() + time
	self.running = true
	self.paused = nil

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

	UpdateIconAndTextAnchors(self)

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
		self.paused = GetTime()
	end
end

---@param self EPReminderMessage
local function Resume(self)
	if self.paused then
		local time = GetTime()
		self.expirationTime = time + self.remaining
		local iterations = ceil(self.remaining / timerTickRate) + 1
		self.durationTicker = NewTicker(timerTickRate, function()
			TextUpdate(self)
		end, iterations)
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
---@param anchorMode boolean
local function SetAnchorMode(self, anchorMode)
	if anchorMode then
		self:SetText("Cast spell or something")
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
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
