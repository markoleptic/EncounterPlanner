local Type = "EPReminderMessage"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local defaultFrameHeight = 24
local defaultFrameWidth = 200
local defaultFontHeight = 14
local defaultIconPadding = { x = 2, y = 2 }
local defaultTextPadding = 2
local defaultBackdropColor = { 0, 0, 0, 0 }
local anchorModeBackdropColor = { 0.1, 0.1, 0.1, 0.25 }
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
local function UpdateIconAndTextAnchors(self)
	self.icon:ClearAllPoints()
	self.text:ClearAllPoints()
	self.frame:SetHeight(self.text:GetLineHeight() + self.horizontalTextPadding * 2)
	if self.showIcon then
		self.frame:SetWidth(self.frame:GetHeight() + self.text:GetStringWidth() + self.horizontalTextPadding * 2)
		self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.iconPadding.x, -self.iconPadding.y)
		self.icon:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.iconPadding.x, self.iconPadding.y)
		self.icon:SetWidth(self.frame:GetHeight() - 2 * self.iconPadding.y)
		self.icon:Show()
		self.text:SetPoint("LEFT", self.icon, "RIGHT", self.horizontalTextPadding, 0)
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -self.horizontalTextPadding, 0)
	else
		self.frame:SetWidth(self.text:GetStringWidth() + self.horizontalTextPadding * 2)
		self.text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.horizontalTextPadding, 0)
		self.text:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -self.horizontalTextPadding, 0)
		self.icon:Hide()
	end
end

---@class EPReminderMessage : AceGUIWidget
---@field frame Frame|table
---@field type string
---@field text FontString
---@field highlight Texture
---@field icon Texture|nil
---@field showIcon boolean
---@field horizontalTextPadding number
---@field iconPadding table{x: number, y: number}

---@param self EPReminderMessage
local function OnAcquire(self)
	self:SetIcon(nil)
	self.frame:SetFrameStrata("MEDIUM")
	self.frame:SetFrameLevel(100)
	self.frame:Show()
end

---@param self EPReminderMessage
local function OnRelease(self)
	self:SetAnchorMode(false)
	self.text:ClearAllPoints()
	self.icon:ClearAllPoints()
	self.horizontalTextPadding = defaultTextPadding
	self.iconPadding = defaultIconPadding
end

---@param self EPReminderMessage
---@param iconID number|string|nil
---@param paddingX number|nil
---@param paddingY number|nil
local function SetIcon(self, iconID, paddingX, paddingY)
	self.iconPadding.x = paddingX or self.iconPadding.x
	self.iconPadding.y = paddingY or self.iconPadding.y
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
local function SetText(self, text, paddingX)
	self.text:SetText(text or "")
	self.horizontalTextPadding = paddingX or self.horizontalTextPadding
	UpdateIconAndTextAnchors(self)
end

---@param self EPReminderMessage
---@param fontFile string
---@param size integer
---@param flags ""|"MONOCHROME"|"OUTLINE"|"THICKOUTLINE"
local function SetFont(self, fontFile, size, flags)
	if fontFile then
		self.text:SetFont(fontFile, size, flags)
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
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, defaultFontHeight)
	end

	---@class EPReminderMessage
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFont = SetFont,
		GetText = GetText,
		SetAnchorMode = SetAnchorMode,
		frame = frame,
		type = Type,
		icon = icon,
		text = text,
		showIcon = false,
		horizontalTextPadding = defaultTextPadding,
		iconPadding = defaultIconPadding,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
