local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPLabel"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local tooltip = Private.tooltip

local CreateFrame = CreateFrame
local unpack = unpack

local k = {
	DefaultFontHeight = 14,
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 200,
	DefaultIconPadding = { left = 2, top = 2, right = 2, bottom = 2 },
	DefaultTextPadding = { left = 0, right = 2 },
	DisabledTextColor = { 0.5, 0.5, 0.5, 1 },
	EnabledTextColor = { 1, 1, 1, 1 },
}

---@param epLabel EPLabel
local function HandleIconEnter(epLabel)
	if epLabel.spellID then
		tooltip:ClearLines()
		tooltip:SetOwner(epLabel.frame, "ANCHOR_BOTTOMLEFT", 0, epLabel.frame:GetHeight())
		tooltip:SetSpellByID(epLabel.spellID)
		tooltip:RefreshData()
		tooltip:AddLine("|r|cFFFFFFFF" .. L["Spell ID"] .. ":|r " .. "|cFFFFD200" .. epLabel.spellID .. "|r")
		tooltip:Show()
	end
end

local function HandleIconLeave(_)
	tooltip:SetScript("OnUpdate", nil)
	tooltip:Hide()
end

---@param self EPLabel
local function UpdateIconAndTextAnchors(self)
	local textPadding = self.horizontalTextPadding
	if self.showIcon then
		self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.iconPadding.left, -self.iconPadding.top)
		self.icon:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.iconPadding.left, self.iconPadding.bottom)
		self.icon:SetWidth(self.frame:GetHeight() - self.iconPadding.top - self.iconPadding.bottom)
		self.icon:Show()
		self.text:SetPoint("LEFT", self.icon, "RIGHT", textPadding.left, 0)
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -textPadding.right, 0)
	else
		self.text:SetPoint("LEFT", self.frame, "LEFT", textPadding.left, 0)
		self.text:SetPoint("RIGHT", self.frame, "RIGHT", -textPadding.right, 0)
		self.icon:Hide()
	end
end

---@param self EPLabel
---@param enabled boolean
local function SetEnabled(self, enabled)
	self.enabled = enabled
	if enabled then
		self.text:SetTextColor(unpack(k.EnabledTextColor))
	else
		self.text:SetTextColor(unpack(k.DisabledTextColor))
	end
end

---@param self EPLabel
local function OnAcquire(self)
	self.horizontalTextPadding = { left = k.DefaultTextPadding.left, right = k.DefaultTextPadding.right }
	self.iconPadding = {
		left = k.DefaultIconPadding.left,
		top = k.DefaultIconPadding.top,
		right = k.DefaultIconPadding.right,
		bottom = k.DefaultIconPadding.bottom,
	}
	self.text:ClearAllPoints()
	self.icon:ClearAllPoints()
	self:SetFontSize(k.DefaultFontHeight)
	self:SetHeight(k.DefaultFrameHeight)
	self:SetHorizontalTextAlignment("LEFT")
	self:SetIcon(nil)
	self:SetEnabled(true)
	self.frame:Show()
end

---@param self EPLabel
local function OnRelease(self)
	self.horizontalTextPadding = nil
	self.iconPadding = nil
	self.spellID = nil
	self.value = nil
end

---@param self EPLabel
---@param iconID number|string|nil
---@param paddingXOrLeft number?
---@param paddingYOrTop number?
---@param spellID number?
---@param paddingRight number?
---@param paddingBottom number?
local function SetIcon(self, iconID, paddingXOrLeft, paddingYOrTop, spellID, paddingRight, paddingBottom)
	self.iconPadding.left = paddingXOrLeft or self.iconPadding.left
	self.iconPadding.right = paddingRight or paddingXOrLeft or self.iconPadding.right
	self.iconPadding.top = paddingYOrTop or self.iconPadding.top
	self.iconPadding.bottom = paddingBottom or paddingYOrTop or self.iconPadding.bottom
	self.icon:SetTexture(iconID)
	self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
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
---@param value? any
local function SetText(self, text, paddingX, value)
	self.text:SetText(text or "")
	self.value = value
	self.horizontalTextPadding.left = paddingX or self.horizontalTextPadding.left
	self.horizontalTextPadding.right = paddingX or self.horizontalTextPadding.right
	UpdateIconAndTextAnchors(self)
end

---@param self EPLabel
---@param left number|nil
---@param right number|nil
local function SetHorizontalTextPadding(self, left, right)
	self.horizontalTextPadding.left = left or self.horizontalTextPadding.left
	self.horizontalTextPadding.right = right or self.horizontalTextPadding.right
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
---@return any
local function GetValue(self)
	return self.value
end

---@param self EPLabel
---@param paddingY number|nil
local function SetFrameHeightFromText(self, paddingY)
	paddingY = paddingY or 2
	self.frame:SetHeight(self.text:GetLineHeight() + paddingY * 2)
end

---@param self EPLabel
local function SetFrameWidthFromText(self)
	local paddingWidth = self.horizontalTextPadding.left + self.horizontalTextPadding.right
	if self.showIcon then
		self.frame:SetWidth(self.frame:GetHeight() + self.text:GetStringWidth() + paddingWidth)
	else
		self.frame:SetWidth(self.text:GetStringWidth() + paddingWidth)
	end
end

---@param self EPLabel
---@param paddingXOrLeft number?
---@param paddingYOrTop number?
---@param paddingRight number?
---@param paddingBottom number?
local function SetIconPadding(self, paddingXOrLeft, paddingYOrTop, paddingRight, paddingBottom)
	self.iconPadding.left = paddingXOrLeft or self.iconPadding.left
	self.iconPadding.right = paddingRight or paddingXOrLeft or self.iconPadding.right
	self.iconPadding.top = paddingYOrTop or self.iconPadding.top
	self.iconPadding.bottom = paddingBottom or paddingYOrTop or self.iconPadding.bottom
	UpdateIconAndTextAnchors(self)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local icon = frame:CreateTexture(Type .. "Icon" .. count, "ARTWORK")
	icon:SetPoint("TOPLEFT", frame, "TOPLEFT", k.DefaultIconPadding.left, -k.DefaultIconPadding.top)
	icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", k.DefaultIconPadding.left, k.DefaultIconPadding.bottom)

	local text = frame:CreateFontString(Type .. "Text" .. count, "OVERLAY", "GameFontNormal")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, k.DefaultFontHeight)
	end
	text:SetWordWrap(false)

	---@class EPLabel : AceGUIWidget
	---@field spellID number|nil
	---@field enabled boolean
	---@field showIcon boolean
	---@field value any
	---@field horizontalTextPadding {left: number, right:number}
	---@field iconPadding {left:number, top:number, right:number, bottom:number}
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetIcon = SetIcon,
		SetText = SetText,
		SetFontSize = SetFontSize,
		SetHorizontalTextAlignment = SetHorizontalTextAlignment,
		GetText = GetText,
		GetValue = GetValue,
		SetFrameHeightFromText = SetFrameHeightFromText,
		SetFrameWidthFromText = SetFrameWidthFromText,
		SetHorizontalTextPadding = SetHorizontalTextPadding,
		OnHeightSet = UpdateIconAndTextAnchors,
		SetIconPadding = SetIconPadding,
		frame = frame,
		type = Type,
		count = count,
		icon = icon,
		text = text,
		spellID = nil,
	}

	icon:SetScript("OnEnter", function()
		if widget.enabled then
			HandleIconEnter(widget)
		end
	end)
	icon:SetScript("OnLeave", function()
		if widget.enabled then
			HandleIconLeave(widget)
		end
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
