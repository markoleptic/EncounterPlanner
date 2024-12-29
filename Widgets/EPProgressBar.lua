local Type = "EPProgressBar"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetTime = GetTime
local floor = math.floor
local ceil = math.ceil

local defaultHeight = 24
local defaultWidth = 200
local defaultVerticalTextPadding = 2
local defaultBackgroundColor = { 0.05, 0.05, 0.05, 0.3 }
local defaultColor = { 0.5, 0.5, 0.5, 1 }
local timeThreshold = 0.1
local secondsInHour = 3600.0
local secondsInMinute = 60.0
local slightlyUnderSecondsInHour = secondsInHour - timeThreshold
local slightlyUnderSecondsInMinute = secondsInMinute - timeThreshold
local slightlyUnderTenSeconds = 10.0 - timeThreshold

local animationTickRate = 0.04
local greaterThanHourFormat = "%d:%02d:%02d"
local greaterThanMinuteFormat = "%d:%02d"
local greaterThanTenSecondsFormat = "%.0f"
local fallbackFormat = "%.1f"

local greaterThanHourFormatApproximate = "~%d:%02d:%02d"
local greaterThanMinuteFormatApproximate = "~%d:%02d"
local greaterThanTenSecondsFormatApproximate = "~%.1f"
local fallbackFormatApproximate = "~%.0f"

local backdropColor = { 0, 0, 0, 0 }
local backdropBorderColor = { 0, 0, 0, 1 }
local frameBackdrop = {
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	edgeSize = 1,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local iconFrameBackdrop = {
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = false,
	edgeSize = 1,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local previousPointDetails = {}

---@param self EPProgressBar
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

---@param self EPProgressBar
local function HandleFrameMouseUp(self, button)
	if button == "LeftButton" then
		self.frame:StopMovingOrSizing()
		local point = previousPointDetails.point
		local relativeFrame = previousPointDetails.relativeTo or UIParent
		local relativePoint = previousPointDetails.relativePoint
		self:Fire("NewPoint", point, relativeFrame, relativePoint)
	end
end

---@param self EPProgressBar
local function RestyleBar(self)
	self.iconBackdrop:ClearAllPoints()
	self.statusBar:ClearAllPoints()

	local edgeSize = frameBackdrop.edgeSize
	self:SetHeight(ceil(self.label:GetLineHeight()) + 2 * defaultVerticalTextPadding + 2 * edgeSize)

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
		local iconEdgeSize = iconFrameBackdrop.edgeSize
		self.icon:SetPoint("TOPLEFT", iconEdgeSize, -iconEdgeSize)
		self.icon:SetPoint("BOTTOMRIGHT", -iconEdgeSize, iconEdgeSize)
	else
		self.statusBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", edgeSize, -edgeSize)
		self.statusBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -edgeSize, edgeSize)
		self.iconBackdrop:Hide()
	end

	local text = self.label:GetText()
	if self.showLabel and text then
		self.label:Show()
	else
		self.label:Hide()
	end

	if self.showTime then
		self.duration:Show()
	else
		self.duration:Hide()
	end

	self.label:ClearAllPoints()
	self.duration:ClearAllPoints()
	if self.label:GetJustifyH() == "LEFT" and self.duration:GetJustifyH() == "RIGHT" then
		local stringWidth = self.statusBar:GetWidth() - 4
		self.label:SetWidth(stringWidth * 0.8)
		self.duration:SetWidth(stringWidth * 0.2)
		self.label:SetPoint("LEFT", self.statusBar, "LEFT", 2, 0)
		self.duration:SetPoint("RIGHT", self.statusBar, "RIGHT", -2, 0)
	elseif self.label:GetJustifyH() == "RIGHT" and self.duration:GetJustifyH() == "LEFT" then
		local stringWidth = self.statusBar:GetWidth() - 4
		self.label:SetWidth(stringWidth * 0.8)
		self.duration:SetWidth(stringWidth * 0.2)
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
local function BarUpdate(self)
	local currentTime = GetTime()
	if currentTime >= self.expirationTime then
		self.updater:SetScript("OnLoop", nil)
		self.running = false
		self:Fire("Completed")
	else
		local relativeTime = self.expirationTime - currentTime
		self.remaining = relativeTime
		self.statusBar:SetValue(self.fill and (currentTime - self.startTime) + self.gap or relativeTime)
		if relativeTime > slightlyUnderSecondsInHour then
			local h = floor(relativeTime / secondsInHour)
			local m = floor((relativeTime - (h * secondsInHour)) / secondsInMinute)
			local s = (relativeTime - (m * secondsInMinute)) - (h * secondsInHour)
			self.duration:SetFormattedText(greaterThanHourFormat, h, m, s)
		elseif relativeTime > slightlyUnderSecondsInMinute then
			local m = floor(relativeTime / secondsInMinute)
			local s = relativeTime - (m * secondsInMinute)
			self.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
		elseif relativeTime > slightlyUnderTenSeconds then
			self.duration:SetFormattedText(greaterThanTenSecondsFormat, relativeTime)
		else
			self.duration:SetFormattedText(fallbackFormat, relativeTime)
		end
	end
end

---@param self EPProgressBar
local function BarUpdateApproximate(self)
	local currentTime = GetTime()
	if currentTime >= self.expirationTime then
		self.updater:SetScript("OnLoop", nil)
		self:Fire("Completed")
	else
		local relativeTime = self.expirationTime - currentTime
		self.remaining = relativeTime
		self.statusBar:SetValue(self.fill and (currentTime - self.startTime) + self.gap or relativeTime)
		if relativeTime > slightlyUnderSecondsInHour then
			local h = floor(relativeTime / secondsInHour)
			local m = floor((relativeTime - (h * secondsInHour)) / secondsInMinute)
			local s = (relativeTime - (m * secondsInMinute)) - (h * secondsInHour)
			self.duration:SetFormattedText(greaterThanHourFormatApproximate, h, m, s)
		elseif relativeTime > slightlyUnderSecondsInMinute then
			local m = floor(relativeTime / secondsInMinute)
			local s = relativeTime - (m * secondsInMinute)
			self.duration:SetFormattedText(greaterThanMinuteFormatApproximate, m, s)
		elseif relativeTime > slightlyUnderTenSeconds then
			self.duration:SetFormattedText(greaterThanTenSecondsFormatApproximate, relativeTime)
		else
			self.duration:SetFormattedText(fallbackFormatApproximate, relativeTime)
		end
	end
end

---@class EPProgressBar : AceGUIWidget
---@field frame table|Frame
---@field type string
---@field statusBar StatusBar
---@field background Texture
---@field iconBackdrop table|Frame|BackdropTemplate
---@field duration FontString
---@field label FontString
---@field updater AnimationGroup
---@field repeater table
---@field fill boolean
---@field showTime boolean
---@field showLabel boolean
---@field remaining number
---@field isApproximate boolean
---@field paused number|nil
---@field expirationTime number
---@field startTime number
---@field running boolean
---@field gap number
---@field iconPosition "LEFT"|"RIGHT"
---@field iconTexture string|integer|nil

---@param self EPProgressBar
local function OnAcquire(self)
	self.frame:SetFrameStrata("MEDIUM")
	self.frame:SetFrameLevel(100)
	self.frame:Show()
end

---@param self EPProgressBar
local function OnRelease(self)
	self.updater:SetScript("OnLoop", nil)
	self.fill = false
	self.showTime = true
	self.showLabel = true
	self.remaining = 0
	self.isApproximate = false
	self.paused = nil
	self.expirationTime = 0
	self.startTime = 0
	self.running = false
	self.gap = 0
	self.iconPosition = "LEFT"
	self.iconTexture = nil
	self.label:SetJustifyH("LEFT")
	self.label:SetJustifyV("MIDDLE")
	self.duration:SetJustifyH("RIGHT")
	self.duration:SetJustifyV("MIDDLE")

	self:SetAnchorMode(false)
end

---@param self EPProgressBar
local function SetFont(self, ...)
	self.label:SetFont(...)
	self.duration:SetFont(...)
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param texture string|integer
local function SetTexture(self, texture)
	self.statusBar:SetStatusBarTexture(texture)
	self.background:SetTexture(texture)
	self:SetBackgroundColor(unpack(defaultBackgroundColor))
	self:SetColor(unpack(defaultColor))
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
		frameBackdrop.edgeSize = 1
		self.frame:SetBackdrop(frameBackdrop)
		self.frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	else
		frameBackdrop.edgeSize = 0
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
		iconFrameBackdrop.edgeSize = 1
		self.iconBackdrop:SetBackdrop(iconFrameBackdrop)
		self.iconBackdrop:SetBackdropBorderColor(unpack(backdropBorderColor))
	else
		iconFrameBackdrop.edgeSize = 0
	end
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param show boolean
local function SetTimeVisibility(self, show)
	self.showTime = show
	if show then
		self.duration:Show()
	else
		self.duration:Hide()
	end
end

---@param self EPProgressBar
---@param show boolean
local function SetLabelVisibility(self, show)
	self.showLabel = show
	if show then
		self.label:Show()
	else
		self.label:Hide()
	end
end

---@param self EPProgressBar
---@param duration number
---@param isApprox? boolean
local function SetDuration(self, duration, isApprox)
	self.remaining = duration
	self.isApproximate = isApprox or false
end

---@param self EPProgressBar
---@param icon string|integer|nil
---@param text string
local function SetIconAndText(self, icon, text)
	self.iconTexture = icon
	self.label:SetText(text)
	self.icon:SetTexture(icon)
	--self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

---@param self EPProgressBar
---@param alignment "CENTER"|"LEFT"|"RIGHT"
local function SetHorizontalTextAlignment(self, alignment)
	self.label:SetJustifyH(alignment)
	if self.running then
		RestyleBar(self)
	end
end

---@param self EPProgressBar
---@param alignment "CENTER"|"LEFT"|"RIGHT"
local function SetDurationTextAlignment(self, alignment)
	self.duration:SetJustifyH(alignment)
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
---@param maxValue? number
local function Start(self, maxValue)
	if self.running and not self.paused then
		return
	end
	RestyleBar(self)

	self.running = true
	self.paused = nil
	local time = self.remaining
	self.gap = maxValue and maxValue - time or 0
	self.startTime = GetTime()
	self.expirationTime = self.startTime + time

	self.statusBar:SetMinMaxValues(0, maxValue or time)
	self.statusBar:SetValue(self.fill and 0 or time)

	if self.isApproximate then
		if time > slightlyUnderSecondsInHour then
			local h = floor(time / secondsInHour)
			local m = floor((time - (h * secondsInHour)) / secondsInMinute)
			local s = (time - (m * secondsInMinute)) - (h * secondsInHour)
			self.duration:SetFormattedText(greaterThanHourFormatApproximate, h, m, s)
		elseif time > slightlyUnderSecondsInMinute then
			local m = floor(time / secondsInMinute)
			local s = time - (m * secondsInMinute)
			self.duration:SetFormattedText(greaterThanMinuteFormatApproximate, m, s)
		elseif time > slightlyUnderTenSeconds then
			self.duration:SetFormattedText(greaterThanTenSecondsFormatApproximate, time)
		else
			self.duration:SetFormattedText(fallbackFormatApproximate, time)
		end
		self.updater:SetScript("OnLoop", function()
			BarUpdateApproximate(self)
		end)
	else
		if time > slightlyUnderSecondsInHour then
			local h = floor(time / secondsInHour)
			local m = floor((time - (h * secondsInHour)) / secondsInMinute)
			local s = (time - (m * secondsInMinute)) - (h * secondsInHour)
			self.duration:SetFormattedText(greaterThanHourFormat, h, m, s)
		elseif time > slightlyUnderSecondsInMinute then
			local m = floor(time / secondsInMinute)
			local s = time - (m * secondsInMinute)
			self.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
		elseif time > slightlyUnderTenSeconds then
			self.duration:SetFormattedText(fallbackFormat, time)
		else
			self.duration:SetFormattedText(greaterThanTenSecondsFormat, time)
		end
		self.updater:SetScript("OnLoop", function()
			BarUpdate(self)
		end)
	end
	self.updater:Play()
end

---@param self EPProgressBar
local function Pause(self)
	if not self.paused then
		self.updater:Pause()
		self.paused = GetTime()
	end
end

---@param self EPProgressBar
local function Resume(self)
	if self.paused then
		local time = GetTime()
		self.expirationTime = time + self.remaining
		self.startTime = self.startTime + (time - self.paused)
		self.updater:Play()
		self.paused = nil
	end
end

---@param self EPProgressBar
---@param anchorMode boolean
local function SetAnchorMode(self, anchorMode)
	if anchorMode then
		self.frame:SetMovable(true)
		self.frame:SetScript("OnMouseDown", function(_, button)
			HandleFrameMouseDown(self, button)
		end)
		self.frame:SetScript("OnMouseUp", function(_, button)
			HandleFrameMouseUp(self, button)
		end)
	else
		self.frame:SetMovable(true)
		self.frame:SetScript("OnMouseDown", nil)
		self.frame:SetScript("OnMouseUp", nil)
	end
end

---@param self EPProgressBar
---@param width number
local function SetProgressBarWidth(self, width)
	self:SetWidth(width)
	if self.running then
		RestyleBar(self)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultWidth, defaultHeight)
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(100)
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))

	local statusBar = CreateFrame("StatusBar", Type .. "StatusBar" .. count, frame)
	statusBar:SetStatusBarColor(unpack(defaultColor))
	statusBar:SetSize(defaultWidth, defaultHeight)

	local background = statusBar:CreateTexture(nil, "BACKGROUND")
	background:SetVertexColor(unpack(defaultBackgroundColor))
	background:SetAllPoints()

	local iconBackdrop = CreateFrame("Frame", Type .. "IconBackdrop" .. count, frame, "BackdropTemplate")
	iconBackdrop:SetBackdrop(iconFrameBackdrop)
	iconBackdrop:SetBackdropColor(unpack(backdropColor))
	iconBackdrop:SetBackdropBorderColor(unpack(backdropBorderColor))

	local icon = iconBackdrop:CreateTexture()
	icon:SetPoint("TOPLEFT")
	icon:SetPoint("BOTTOMRIGHT")

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

	local updater = frame:CreateAnimationGroup()
	updater:SetLooping("REPEAT")

	local repeater = updater:CreateAnimation()
	repeater:SetDuration(animationTickRate)

	---@class EPProgressBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetFont = SetFont,
		SetTexture = SetTexture,
		SetColor = SetColor,
		SetBackgroundColor = SetBackgroundColor,
		SetTimeVisibility = SetTimeVisibility,
		SetLabelVisibility = SetLabelVisibility,
		SetDuration = SetDuration,
		SetIconAndText = SetIconAndText,
		Start = Start,
		Pause = Pause,
		Resume = Resume,
		SetAnchorMode = SetAnchorMode,
		SetHorizontalTextAlignment = SetHorizontalTextAlignment,
		SetDurationTextAlignment = SetDurationTextAlignment,
		SetIconPosition = SetIconPosition,
		SetFill = SetFill,
		SetProgressBarWidth = SetProgressBarWidth,
		SetShowBorder = SetShowBorder,
		SetShowIconBorder = SetShowIconBorder,
		frame = frame,
		type = Type,
		statusBar = statusBar,
		background = background,
		icon = icon,
		iconBackdrop = iconBackdrop,
		duration = duration,
		label = label,
		updater = updater,
		repeater = repeater,
		fill = false,
		showTime = true,
		showLabel = true,
		remaining = 0,
		isApproximate = false,
		paused = nil,
		expirationTime = 0,
		startTime = 0,
		running = false,
		gap = 0,
		iconPosition = "LEFT",
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
