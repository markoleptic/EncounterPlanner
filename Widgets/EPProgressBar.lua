local Type = "EPProgressBar"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local GetTime = GetTime
local floor = math.floor

local defaultHeight = 24
local defaultWidth = 200
local defaultFontSize = 14

local animationTickRate = 0.04
local greaterThanHourFormat = "%d:%02d:%02d"
local greaterThanMinuteFormat = "%d:%02d"
local greaterThanTenSecondsFormat = "%.0f"
local fallbackFormat = "%.1f"

local greaterThanHourFormatApproximate = "~%d:%02d:%02d"
local greaterThanMinuteFormatApproximate = "~%d:%02d"
local greaterThanTenSecondsFormatApproximate = "~%.1f"
local fallbackFormatApproximate = "~%.0f"

local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
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
	self.icon:ClearAllPoints()
	self.statusBar:ClearAllPoints()
	if self.iconTexture then
		self.icon:SetWidth(self.frame:GetHeight())
		if self.iconPosition == "RIGHT" then
			self.icon:SetPoint("TOPRIGHT", self.frame)
			self.icon:SetPoint("BOTTOMRIGHT", self.frame)
			self.statusBar:SetPoint("TOPRIGHT", self.icon, "TOPLEFT")
			self.statusBar:SetPoint("BOTTOMRIGHT", self.icon, "BOTTOMLEFT")
			self.statusBar:SetPoint("TOPLEFT", self.frame)
			self.statusBar:SetPoint("BOTTOMLEFT", self.frame)
		else
			self.icon:SetPoint("TOPLEFT", self.frame)
			self.icon:SetPoint("BOTTOMLEFT", self.frame)
			self.statusBar:SetPoint("TOPLEFT", self.icon, "TOPRIGHT")
			self.statusBar:SetPoint("BOTTOMLEFT", self.icon, "BOTTOMRIGHT")
			self.statusBar:SetPoint("TOPRIGHT", self.frame)
			self.statusBar:SetPoint("BOTTOMRIGHT", self.frame)
		end
		self.icon:Show()
	else
		self.statusBar:SetPoint("TOPLEFT", self.frame)
		self.statusBar:SetPoint("BOTTOMRIGHT", self.frame)
		self.icon:Hide()
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
end

---@param self EPProgressBar
local function BarUpdate(self)
	local currentTime = GetTime()
	if currentTime >= self.expirationTime then
		self.updater:SetScript("OnLoop", nil)
		self:Fire("Completed")
	else
		local relativeTime = self.expirationTime - currentTime
		self.remaining = relativeTime
		self.statusBar:SetValue(self.fill and (currentTime - self.startTime) + self.gap or relativeTime)
		if relativeTime > 3599.9 then
			local h = floor(relativeTime / 3600)
			local m = floor((relativeTime - (h * 3600)) / 60)
			local s = (relativeTime - (m * 60)) - (h * 3600)
			self.duration:SetFormattedText(greaterThanHourFormat, h, m, s)
		elseif relativeTime > 59.9 then
			local m = floor(relativeTime / 60)
			local s = relativeTime - (m * 60)
			self.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
		elseif relativeTime < 10 then
			self.duration:SetFormattedText(fallbackFormat, relativeTime)
		else
			self.duration:SetFormattedText(greaterThanTenSecondsFormat, relativeTime)
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
		if relativeTime > 3599.9 then
			local h = floor(relativeTime / 3600)
			local m = floor((relativeTime - (h * 3600)) / 60)
			local s = (relativeTime - (m * 60)) - (h * 3600)
			self.duration:SetFormattedText(greaterThanHourFormatApproximate, h, m, s)
		elseif relativeTime > 59.9 then
			local m = floor(relativeTime / 60)
			local s = relativeTime - (m * 60)
			self.duration:SetFormattedText(greaterThanMinuteFormatApproximate, m, s)
		elseif relativeTime < 10 then
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
---@field backdrop BackdropTemplate|Frame
---@field iconBackdrop table|Frame
---@field duration FontString
---@field label FontString
---@field updater AnimationGroup
---@field repeater table
---@field fill boolean
---@field showTime boolean
---@field showLabel boolean
---@field remaining number
---@field isApproximate boolean
---@field paused boolean
---@field pauseTime number
---@field expirationTime number
---@field startTime number
---@field running boolean
---@field gap number
---@field iconPosition "LEFT"|"RIGHT"
---@field iconTexture string|integer

---@param self EPProgressBar
local function OnAcquire(self)
	self.fill = false
	self.showTime = true
	self.showLabel = true
	self.remaining = 0
	self.isApproximate = false
	self.paused = false
	self.pauseTime = 0
	self.expirationTime = 0
	self.startTime = 0
	self.running = false
	self.gap = 0
	self.iconPosition = "LEFT"
	self.iconTexture = [[Interface\Icons\INV_MISC_QUESTIONMARK]]

	self.label:SetJustifyH("LEFT")
	self.label:SetJustifyV("MIDDLE")

	self.duration:SetJustifyH("RIGHT")
	self.duration:SetJustifyV("MIDDLE")

	self:SetHeight(defaultHeight)
	self:SetWidth(defaultWidth)
	self:SetBackgroundColor(0.5, 0.5, 0.5, 0.3)
	self:SetColor(0.5, 0.5, 0.5, 1)
	self:SetIconAndText(self.iconTexture, "Text")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	local defaultBackgroundTexture = LSM:Fetch("statusbar", "Clean")
	self:SetTexture(defaultBackgroundTexture)
	self:SetFont(fPath, defaultFontSize)

	self.frame:SetFrameStrata("MEDIUM")
	self.frame:SetFrameLevel(100)
	self.frame:Show()
end

---@param self EPProgressBar
local function OnRelease(self)
	self.updater:SetScript("OnLoop", nil)
	self:SetAnchorMode(false)
end

---@param self EPProgressBar
local function SetFont(self, ...)
	self.label:SetFont(...)
	self.duration:SetFont(...)
end

---@param self EPProgressBar
local function SetTexture(self, texture)
	self.statusBar:SetStatusBarTexture(texture)
	self.background:SetTexture(texture)
end

---@param self EPProgressBar
local function SetColor(self, r, g, b, a)
	self.statusBar:SetStatusBarColor(r, g, b, a)
end

---@param self EPProgressBar
local function SetBackgroundColor(self, r, g, b, a)
	self.background:SetVertexColor(r, g, b, a)
end

---@param self EPProgressBar
local function SetTimeVisibility(self, show)
	self.showTime = show
	if show then
		self.duration:Show()
	else
		self.duration:Hide()
	end
end

---@param self EPProgressBar
local function SetLabelVisibility(self, show)
	self.showLabel = show
	if show then
		self.label:Show()
	else
		self.label:Hide()
	end
end

---@param self EPProgressBar
local function SetDuration(self, duration, isApprox)
	self.remaining = duration
	self.isApproximate = isApprox
end

---@param self EPProgressBar
---@param icon string|integer
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
end

---@param self EPProgressBar
local function Start(self, maxValue)
	RestyleBar(self)

	self.running = true
	local time = self.remaining
	self.gap = maxValue and maxValue - time or 0
	self.startTime = GetTime()
	self.expirationTime = self.startTime + time

	self.statusBar:SetMinMaxValues(0, maxValue or time)
	self.statusBar:SetValue(self.fill and 0 or time)

	if self.isApproximate then
		if time > 3599.99 then -- > 1 hour
			local h = floor(time / 3600)
			local m = floor((time - (h * 3600)) / 60)
			local s = (time - (m * 60)) - (h * 3600)
			self.duration:SetFormattedText(greaterThanHourFormatApproximate, h, m, s)
		elseif time > 59.99 then -- 1 minute to 1 hour
			local m = floor(time / 60)
			local s = time - (m * 60)
			self.duration:SetFormattedText(greaterThanMinuteFormatApproximate, m, s)
		elseif time < 10 then -- 0 to 10 seconds
			self.duration:SetFormattedText(greaterThanTenSecondsFormatApproximate, time)
		else -- 10 seconds to one minute
			self.duration:SetFormattedText(fallbackFormatApproximate, time)
		end
		self.updater:SetScript("OnLoop", function()
			BarUpdateApproximate(self)
		end)
	else
		if time > 3599.99 then
			local h = floor(time / 3600)
			local m = floor((time - (h * 3600)) / 60)
			local s = (time - (m * 60)) - (h * 3600)
			self.duration:SetFormattedText(greaterThanHourFormat, h, m, s)
		elseif time > 59.99 then
			local m = floor(time / 60)
			local s = time - (m * 60)
			self.duration:SetFormattedText(greaterThanMinuteFormat, m, s)
		elseif time < 10 then
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
		self.pauseTime = GetTime()
	end
end

---@param self EPProgressBar
local function Resume(self)
	if self.paused then
		local time = GetTime()
		self.expirationTime = time + self.remaining
		self.startTime = self.startTime + (time - self.paused)
		self.updater:Play()
		self.paused = false
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

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(100)

	local icon = frame:CreateTexture()
	icon:SetPoint("TOPLEFT")
	icon:SetPoint("BOTTOMLEFT")
	icon:Show()

	local statusBar = CreateFrame("StatusBar", Type .. "StatusBar" .. count, frame)
	statusBar:SetPoint("TOPRIGHT")
	statusBar:SetPoint("BOTTOMRIGHT")

	local background = statusBar:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()

	local backdrop = CreateFrame("Frame", Type .. "Backdrop" .. count, frame, "BackdropTemplate")
	backdrop:SetFrameLevel(0)

	local iconBackdrop = CreateFrame("Frame", Type .. "IconBackdrop" .. count, frame, "BackdropTemplate")
	iconBackdrop:SetFrameLevel(0)

	local duration = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
	duration:SetPoint("TOPLEFT", statusBar, "TOPLEFT", 2, 0)
	duration:SetPoint("BOTTOMRIGHT", statusBar, "BOTTOMRIGHT", -2, 0)

	local label = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
	label:SetPoint("TOPLEFT", statusBar, "TOPLEFT", 2, 0)
	label:SetPoint("BOTTOMRIGHT", statusBar, "BOTTOMRIGHT", -2, 0)

	local updater = frame:CreateAnimationGroup()
	updater:SetLooping("REPEAT")

	local repeater = updater:CreateAnimation()
	repeater:SetDuration(animationTickRate)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	local defaultBackgroundTexture = LSM:Fetch("statusbar", "Clean")
	statusBar:SetStatusBarTexture(defaultBackgroundTexture --[[@as string]])
	background:SetTexture(defaultBackgroundTexture)

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
		frame = frame,
		type = Type,
		statusBar = statusBar,
		background = background,
		backdrop = backdrop,
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
		paused = false,
		pauseTime = 0,
		expirationTime = 0,
		startTime = 0,
		running = false,
		gap = 0,
		iconPosition = "LEFT",
		iconTexture = [[Interface\Icons\INV_MISC_QUESTIONMARK]],
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
