local Type = "EPReminderIcon"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetTime = GetTime
local next = next
local unpack = unpack

local defaultFrameHeight = 30
local defaultFrameWidth = 30
local defaultTextPadding = 4
local defaultBackdropColor = { 0, 0, 0, 0 }
local anchorModeBackdropColor = { 10.0 / 255.0, 10.0 / 255.0, 10.0 / 255.0, 0.25 }
local defaultDisplayTime = 2
local defaultFadeDuration = 1.2
local timerTickRate = 0.1
local timeThreshold = 0.1
local secondsInMinute = 60.0
local slightlyUnderSecondsInMinute = secondsInMinute - timeThreshold
local slightlyUnderTenSeconds = 10.0 - timeThreshold
local greaterThanMinuteFormat = "%d:%02d"
local greaterThanTenSecondsFormat = "%.0f"
local lessThanTenSecondsFormat = "%.1f"
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = nil,
	tile = true,
	tileSize = 0,
	edgeSize = 0,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

---@param self EPReminderIcon
local function OnAcquire(self)
	self.frame:Show()
end

---@param self EPReminderIcon
local function OnRelease(self)
	self.cooldown:Clear()
	self.remaining = 0
	self.expirationTime = 0
	self.currentThreshold = ""
	self.running = false
	self:SetAnchorMode(false)
end

---@param self EPReminderIcon
---@param iconID number|string|nil
local function SetIcon(self, iconID)
	if iconID then
		self.icon:SetTexture(iconID)
	else
		self.icon:SetTexture("Interface\\Icons\\INV_MISC_QUESTIONMARK")
	end
end

---@param self EPReminderIcon
---@param text string
---@param fontFile string|nil
---@param size integer|nil
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"|nil
local function SetText(self, text, fontFile, size, flags)
	self.text:SetText(text or "")
	if fontFile and size then
		self.text:SetFont(fontFile, size, flags)
	end
end

---@param self EPReminderIcon
---@param start number The time when the cooldown started (as returned by GetTime()).
---@param duration number Cooldown duration in seconds.
local function Start(self, start, duration)
	if self.running then
		return
	end
	self.cooldown:SetCooldownDuration(start, duration)
	self.text:Show()
	self.running = true
end

---@param self EPReminderIcon
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
local function SetFont(self, fontFile, size, flags)
	if fontFile then
		self.cooldown:SetCountdownFont(fontFile)
		self.text:SetFont(fontFile, size, flags)
	end
end

---@param self EPReminderIcon
---@param r number
---@param g number
---@param b number
---@param a number
local function SetTextColor(self, r, g, b, a)
	self.text:SetTextColor(r, g, b, a)
end

---@param self EPReminderIcon
---@param alpha number
local function SetAlpha(self, alpha)
	self.frame:SetAlpha(alpha)
end

---@param self EPReminderIcon
---@param anchorMode boolean
local function SetAnchorMode(self, anchorMode)
	if anchorMode then
		self.frame:SetBackdropColor(unpack(anchorModeBackdropColor))
	else
		self.frame:SetBackdropColor(unpack(defaultBackdropColor))
	end
end

---@param self EPReminderIcon
---@param preferences MessagePreferences
---@param text string
---@param icon string|number|nil
local function Set(self, preferences, text, icon)
	self.text:SetText(text or "")
	if preferences.font and preferences.fontSize then
		self.cooldown:SetCountdownFont(preferences.font)
		self.text:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
	end
	self.frame:SetAlpha(preferences.alpha)
	local r, g, b, a = unpack(preferences.textColor)
	self.text:SetTextColor(r, g, b, a)
	SetIcon(self, icon)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(defaultBackdropColor))
	frame:SetBackdropBorderColor(unpack(defaultBackdropColor))

	local icon = frame:CreateTexture(Type .. "Icon" .. count, "ARTWORK")
	icon:SetPoint("TOPLEFT")
	icon:SetPoint("BOTTOMRIGHT")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
	cooldown:SetPoint("TOPLEFT")
	cooldown:SetPoint("BOTTOMRIGHT")

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	text:SetJustifyH("CENTER")
	text:SetWordWrap(false)
	text:SetPoint("TOPLEFT", cooldown, "BOTTOMLEFT", 0, -2)
	text:SetPoint("TOPRIGHT", cooldown, "BOTTOMRIGHT", 0, -2)

	---@class EPReminderIcon : AceGUIWidget
	---@field frame Frame|table
	---@field cooldown table|Cooldown
	---@field type string
	---@field text FontString
	---@field remaining number
	---@field expirationTime number
	---@field currentThreshold "OverHour"|"OverMinute"|"OverTenSeconds"|"UnderTenSeconds"|""
	---@field running boolean
	---@field parent EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFont = SetFont,
		SetAnchorMode = SetAnchorMode,
		Start = Start,
		SetTextColor = SetTextColor,
		SetAlpha = SetAlpha,
		Set = Set,
		frame = frame,
		cooldown = cooldown,
		icon = icon,
		type = Type,
		text = text,
		remaining = 0,
		expirationTime = 0,
		currentThreshold = "",
		running = false,
	}

	cooldown:SetScript("OnCooldownDone", function()
		widget.frame:Hide()
		widget.running = false
		widget:Fire("Completed")
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
