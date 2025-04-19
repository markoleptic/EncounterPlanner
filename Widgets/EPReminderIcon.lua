local Type = "EPReminderIcon"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local floor = math.floor
local unpack = unpack

local defaultFrameHeight = 30
local defaultFrameWidth = 30
local backdropBorderColor = { 0, 0, 0, 1 }
local kMinimumFontSize = 8

local testFontString = UIParent:CreateFontString(nil, "OVERLAY")
testFontString:Hide()

---@param text string
---@param font string
---@param fontHeight number
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
---@param maxWidth integer
---@return integer
local function CalculateFontSizeToFit(text, font, fontHeight, flags, maxWidth)
	testFontString:SetFont(font, fontHeight, flags)
	testFontString:SetText(text)

	if testFontString:GetStringWidth() <= maxWidth then
		return fontHeight
	end

	local minSize = kMinimumFontSize
	local bestSize = minSize

	while minSize <= fontHeight do
		local mid = floor((minSize + fontHeight) / 2)
		testFontString:SetFont(font, mid)
		local width = testFontString:GetStringWidth()

		if width <= maxWidth then
			bestSize = mid
			minSize = mid + 1
		else
			fontHeight = mid - 1
		end
	end

	return bestSize
end

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
	self.text:Hide()
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

-- Requires that the text already be set.
---@param self EPReminderIcon
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
---@param shrinkTextToFit boolean If true, the text will attempt to be shrunk to fit within the icon width.
---@param width integer Width of the EPReminderIcon
local function SetFont(self, fontFile, size, flags, shrinkTextToFit, width)
	if fontFile then
		if self.showText and shrinkTextToFit then
			size = CalculateFontSizeToFit(self.text:GetText(), fontFile, size, flags, width)
		end
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
	self.text:SetText(text)
	SetFont(
		self,
		preferences.font,
		preferences.fontSize,
		preferences.fontOutline,
		preferences.shrinkTextToFit,
		preferences.width
	)
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
