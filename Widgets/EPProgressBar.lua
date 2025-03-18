local Type = "EPProgressBar"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetTime = GetTime
local next = next
local pairs = pairs

local defaultHeight = 24
local defaultWidth = 200
local defaultBackgroundColor = { 0.05, 0.05, 0.05, 0.3 }
local defaultColor = { 0.5, 0.5, 0.5, 1 }
local timeThreshold = 0.1
local secondsInMinute = 60.0
local slightlyUnderSecondsInMinute = secondsInMinute - timeThreshold
local slightlyUnderTenSeconds = 10.0 - timeThreshold

local animationTickRate = 0.04
local greaterThanMinuteFormat = "%d:%02d"
local greaterThanTenSecondsFormat = "%.0f"
local lessThanTenSecondsFormat = "%.1f"

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

local activeBars = {} ---@type table<EPProgressBar, boolean>

local sharedUpdater = CreateFrame("Frame"):CreateAnimationGroup()
sharedUpdater:SetLooping("REPEAT")

local repeater = sharedUpdater:CreateAnimation()
repeater:SetDuration(animationTickRate)

local function SharedBarUpdate()
	local currentTime = GetTime()
	for bar in pairs(activeBars) do
		if currentTime >= bar.expirationTime then
			activeBars[bar] = nil
			bar.running = false
			bar.frame:Hide()
			bar:Fire("Completed")
		else
			local relativeTime = bar.expirationTime - currentTime
			bar.remaining = relativeTime
			bar.statusBar:SetValue(bar.fill and (currentTime - bar.startTime) + bar.gap or relativeTime)

			if relativeTime <= slightlyUnderTenSeconds then
				bar.duration:SetFormattedText(lessThanTenSecondsFormat, relativeTime)
			elseif relativeTime <= slightlyUnderSecondsInMinute then
				bar.duration:SetFormattedText(greaterThanTenSecondsFormat, relativeTime)
			else
				local m = floor(relativeTime / secondsInMinute)
				local s = relativeTime - (m * secondsInMinute)
				bar.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
			end
		end
	end

	if not next(activeBars) then
		sharedUpdater:Stop()
	end
end

sharedUpdater:SetScript("OnLoop", SharedBarUpdate)

---@param self EPProgressBar
local function RestyleBar(self)
	self.iconBackdrop:ClearAllPoints()
	self.statusBar:ClearAllPoints()

	local edgeSize = frameBackdrop.edgeSize

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

---@class EPProgressBar : AceGUIWidget
---@field frame table|Frame
---@field type string
---@field statusBar StatusBar
---@field background Texture
---@field iconBackdrop table|Frame|BackdropTemplate
---@field duration FontString
---@field label FontString
---@field fill boolean
---@field remaining number
---@field expirationTime number
---@field startTime number
---@field running boolean
---@field gap number
---@field iconPosition "LEFT"|"RIGHT"
---@field iconTexture string|integer|nil
---@field parent EPContainer

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
		frameBackdrop.edgeSize = 1
		self.frame:SetBackdrop(frameBackdrop)
		self.frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	else
		frameBackdrop.edgeSize = 0
	end
	self.iconBackdrop:ClearBackdrop()
	if preferences.showIconBorder then
		iconFrameBackdrop.edgeSize = 1
		self.iconBackdrop:SetBackdrop(iconFrameBackdrop)
		self.iconBackdrop:SetBackdropBorderColor(unpack(backdropBorderColor))
	else
		iconFrameBackdrop.edgeSize = 0
	end
	self.statusBar:SetStatusBarTexture(preferences.texture)
	self.background:SetTexture(preferences.texture)
	self:SetColor(unpack(preferences.color))
	self:SetBackgroundColor(unpack(preferences.backgroundColor))
	self.iconPosition = preferences.iconPosition
	self.fill = preferences.fill
	self.frame:SetAlpha(preferences.alpha)
	self.label:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
	self.duration:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
	self.remaining = duration
	self.iconTexture = icon
	self.label:SetText(text)
	self.icon:SetTexture(icon)
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

	activeBars[self] = true

	if not sharedUpdater:IsPlaying() then
		sharedUpdater:Play()
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

	---@class EPProgressBar
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
