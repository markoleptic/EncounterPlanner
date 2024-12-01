local Type = "EPLabel"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local tooltip = EncounterPlanner.tooltip
local tooltipUpdateTime = EncounterPlanner.tooltipUpdateTime

local defaultFrameHeight = 24
local defaultFrameWidth = 200
local defaultFontHeight = 14
local defaultIconPadding = { x = 2, y = 2 }
local defaultTextPadding = { x = 0, y = 2 }

---@param frame table|GameTooltip
---@param elapsed number
local function HandleTooltipOnUpdate(frame, elapsed)
	frame.updateTooltipTimer = frame.updateTooltipTimer - elapsed
	if frame.updateTooltipTimer > 0 then
		return
	end
	frame.updateTooltipTimer = tooltipUpdateTime
	local owner = frame:GetOwner()
	if owner and frame.spellID then
		frame:SetSpellByID(frame.spellID)
	end
end

---@param epLabel EPLabel
local function HandleIconEnter(epLabel)
	if epLabel.spellID then
		tooltip:ClearLines()
		tooltip:SetOwner(epLabel.frame, "ANCHOR_BOTTOMLEFT", 0, epLabel.frame:GetHeight())
		tooltip:SetSpellByID(epLabel.spellID)
		tooltip:SetScript("OnUpdate", HandleTooltipOnUpdate)
	end
end

local function HandleIconLeave(_)
	tooltip:SetScript("OnUpdate", nil)
	tooltip:Hide()
end

---@param self EPLabel
local function UpdateIconAndTextAnchors(self)
	if self.showIcon then
		self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.iconPadding.x, -self.iconPadding.y)
		self.icon:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.iconPadding.x, self.iconPadding.y)
		self.icon:SetWidth(self.frame:GetHeight() - 2 * self.iconPadding.y)
		self.icon:Show()
		self.text:SetPoint("LEFT", self.icon, "RIGHT", self.horizontalTextPadding, 0)
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", self.horizontalTextPadding, 0)
	else
		self.text:SetPoint("LEFT", self.frame, "LEFT", self.horizontalTextPadding, 0)
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", self.horizontalTextPadding, 0)
		self.icon:Hide()
	end
end

---@class EPLabel : AceGUIWidget
---@field frame Frame
---@field type string
---@field text FontString
---@field highlight Texture
---@field icon Texture|nil
---@field spellID number|nil
---@field disabled boolean
---@field showIcon boolean
---@field horizontalTextPadding number
---@field iconPadding table{x: number, y: number}

---@param self EPLabel
local function SetDisabled(self, disable)
	self.disabled = disable
	if disable then
		self.text:SetTextColor(0.5, 0.5, 0.5)
	else
		self.text:SetTextColor(1, 1, 1)
	end
end

---@param self EPLabel
local function OnAcquire(self)
	self.horizontalTextPadding = defaultTextPadding.x
	self.iconPadding = defaultIconPadding
	self.text:ClearAllPoints()
	self.icon:ClearAllPoints()
	self:SetFontSize(defaultFontHeight)
	self:SetHeight(defaultFrameHeight)
	self:SetHorizontalTextAlignment("LEFT")
	self:SetIcon(nil)
	self:SetDisabled(false)
	self.frame:Show()
end

---@param self EPLabel
local function OnRelease(self)
	self.horizontalTextPadding = nil
	self.iconPadding = nil
	self.spellID = nil
end

---@param self EPLabel
---@param iconID number|string|nil
---@param paddingX number|nil
---@param paddingY number|nil
---@param spellID number|nil
local function SetIcon(self, iconID, paddingX, paddingY, spellID)
	self.iconPadding.x = paddingX or self.iconPadding.x
	self.iconPadding.y = paddingY or self.iconPadding.y
	self.icon:SetTexture(iconID)
	self.spellID = spellID
	if iconID then
		self.showIcon = true
	else
		self.showIcon = false
	end
	UpdateIconAndTextAnchors(self)
end

---@param self EPLabel
---@param text string
---@param paddingX number|nil
local function SetText(self, text, paddingX)
	self.text:SetText(text or "")
	self.horizontalTextPadding = paddingX or self.horizontalTextPadding
	UpdateIconAndTextAnchors(self)
end

---@param self EPLabel
---@param size integer
local function SetFontSize(self, size)
	local fontFile, _, flags = self.text:GetFont()
	if fontFile then
		self.text:SetFont(fontFile, size, flags)
	end
end

---@param self EPLabel
---@param alignment "CENTER"|"LEFT"|"RIGHT"
local function SetHorizontalTextAlignment(self, alignment)
	self.text:SetJustifyH(alignment)
end

---@param self EPLabel
---@return string
local function GetText(self)
	return self.text:GetText()
end

---@param self EPLabel
---@param paddingY number|nil
local function SetFrameHeightFromText(self, paddingY)
	paddingY = paddingY or defaultTextPadding.y
	self.frame:SetHeight(self.text:GetLineHeight() + paddingY * 2)
end

---@param self EPLabel
local function SetFrameWidthFromText(self)
	if self.showIcon then
		self.frame:SetWidth(self.frame:GetHeight() + self.text:GetStringWidth() + self.horizontalTextPadding * 2)
	else
		self.frame:SetWidth(self.text:GetStringWidth() + self.horizontalTextPadding * 2)
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local icon = frame:CreateTexture(Type .. "Icon" .. count, "ARTWORK")
	icon:SetPoint("TOPLEFT", frame, "TOPLEFT", defaultIconPadding.x, -defaultIconPadding.y)
	icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", defaultIconPadding.x, defaultIconPadding.y)

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, defaultFontHeight)
	end
	text:SetPoint("LEFT", frame, "LEFT", defaultTextPadding.x, 0)
	text:SetPoint("RIGHT", frame, "RIGHT", defaultTextPadding.x, 0)
	text:SetWordWrap(false)

	---@class EPLabel
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetDisabled = SetDisabled,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFontSize = SetFontSize,
		SetHorizontalTextAlignment = SetHorizontalTextAlignment,
		GetText = GetText,
		SetFrameHeightFromText = SetFrameHeightFromText,
		SetFrameWidthFromText = SetFrameWidthFromText,
		frame = frame,
		type = Type,
		icon = icon,
		text = text,
		spellID = nil,
	}

	frame.obj = widget

	icon:SetScript("OnEnter", function()
		HandleIconEnter(widget)
	end)
	icon:SetScript("OnLeave", function()
		HandleIconLeave(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
