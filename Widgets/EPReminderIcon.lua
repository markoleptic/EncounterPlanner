local Type = "EPReminderIcon"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local GetTime = GetTime
local min = math.min
local next = next
local unpack = unpack

local defaultFrameHeight = 30
local defaultFrameWidth = 30
local defaultTextPadding = 4
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

local backdropBorderColor = { 0, 0, 0, 1 }

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
	self.showText = false
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
---@param show boolean
local function SetShowText(self, show)
	self.showText = show
	if self.frame:IsVisible() then
		if show then
			self.text:Show()
		else
			self.text:Hide()
		end
	end
end

---@param self EPReminderIcon
---@param start number The time when the cooldown started (as returned by GetTime()).
---@param duration number Cooldown duration in seconds.
local function Start(self, start, duration)
	if self.running then
		return
	end
	self.cooldown:SetCooldown(start, duration)
	if self.showText then
		self.text:Show()
	else
		self.text:Hide()
	end
	self.running = true
end

---@param self EPReminderIcon
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
local function SetFont(self, fontFile, size, flags)
	if fontFile then
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
---@param borderSize integer
local function SetBorderSize(self, borderSize)
	self.frame:ClearBackdrop()
	if borderSize > 1 then
		self.frame:SetBackdrop({
			edgeFile = "Interface\\BUTTONS\\White8x8",
			edgeSize = borderSize,
		})
		self.frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	end
	self.icon:SetPoint("TOPLEFT", borderSize, -borderSize)
	self.icon:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
end

---@param self EPReminderIcon
---@param drawEdge boolean
---@param drawSwipe boolean
local function SetDraw(self, drawEdge, drawSwipe)
	self.cooldown:SetDrawEdge(drawEdge)
	self.cooldown:SetDrawSwipe(drawSwipe)
end

---@param self EPReminderIcon
---@param preferences IconPreferences
---@param text string
---@param icon string|number|nil
local function Set(self, preferences, text, icon)
	self.frame:SetSize(preferences.width, preferences.height)
	self.showText = preferences.showText
	self.text:SetText(text or "")
	if preferences.font and preferences.fontSize then
		self.text:SetFont(preferences.font, preferences.fontSize, preferences.fontOutline)
	end
	SetDraw(self, preferences.drawEdge, preferences.drawSwipe)
	SetAlpha(self, preferences.alpha)
	SetTextColor(self, unpack(preferences.textColor))
	SetIcon(self, icon)
	SetBorderSize(self, preferences.borderSize)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetBackdrop({
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 2,
	})
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))

	local icon = frame:CreateTexture(Type .. "Icon" .. count, "ARTWORK")
	icon:SetPoint("TOPLEFT")
	icon:SetPoint("BOTTOMRIGHT")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local cooldown = CreateFrame("Cooldown", Type .. "Cooldown" .. count, frame, "CooldownFrameTemplate")
	cooldown:SetPoint("TOPLEFT")
	cooldown:SetPoint("BOTTOMRIGHT")
	cooldown:SetDrawSwipe(false)

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	text:SetJustifyH("CENTER")
	text:SetWordWrap(false)
	text:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
	text:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
	text:Hide()

	---@class EPReminderIcon : AceGUIWidget
	---@field parent EPContainer
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFont = SetFont,
		Start = Start,
		SetTextColor = SetTextColor,
		SetAlpha = SetAlpha,
		Set = Set,
		SetShowText = SetShowText,
		SetBorderSize = SetBorderSize,
		SetDraw = SetDraw,
		frame = frame,
		cooldown = cooldown,
		icon = icon,
		type = Type,
		text = text,
		remaining = 0,
		expirationTime = 0,
		currentThreshold = "",
		running = false,
		showText = false,
	}

	cooldown:SetScript("OnCooldownDone", function()
		widget.frame:Hide()
		widget.running = false
		widget:Fire("Completed")
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
