local Type               = "EPLabel"
local Version            = 1
local AceGUI             = LibStub("AceGUI-3.0")
local LSM                = LibStub("LibSharedMedia-3.0")
local defaultFrameHeight = 24
local defaultFrameWidth  = 200
local defaultFontHeight  = 14
local defaultIconPadding = { x = 2, y = 2 }
local defaultTextPadding = { x = 5, y = "none" }

local function HandleTooltipOnUpdate(frame, elapsed)
	frame.updateTooltipTimer = frame.updateTooltipTimer - elapsed
	if frame.updateTooltipTimer > 0 then
		return
	end
	frame.updateTooltipTimer = EncounterPlanner.tooltipUpdateTime
	local owner = frame:GetOwner()
	if owner and frame.spellID then
		frame:SetSpellByID(frame.spellID)
	end
end

---@param epLabel EPLabel
local function HandleIconEnter(epLabel)
	if epLabel.spellID then
		EncounterPlanner.tooltip:ClearLines()
		EncounterPlanner.tooltip:SetOwner(epLabel.frame, "ANCHOR_BOTTOMLEFT", 0, epLabel.frame:GetHeight())
		EncounterPlanner.tooltip:SetSpellByID(epLabel.spellID)
		EncounterPlanner.tooltip:SetScript("OnUpdate", HandleTooltipOnUpdate)
	end
end

---@param epLabel EPLabel
local function HandleIconLeave(epLabel)
	EncounterPlanner.tooltip:SetScript("OnUpdate", nil)
	EncounterPlanner.tooltip:Hide()
end

---@param self EPLabel
local function UpdateFrameSize(self)
	if self.textPadding.y == "auto" then
		self.frame:SetHeight(self.text:GetLineHeight())
	elseif type(self.textPadding.y) == "number" then
		self.frame:SetHeight(self.text:GetLineHeight() + self.textPadding.y * 2)
	end

	if self.icon:IsShown() then
		self.frame:SetWidth(self.frame:GetHeight() + self.text:GetStringWidth() + self.textPadding.x * 2)
	else
		self.frame:SetWidth(self.text:GetStringWidth() + self.textPadding.x * 2)
	end
end

---@param self EPLabel
local function UpdateIconSizeAndPadding(self)
	if self.icon:IsShown() then
		self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.iconPadding.x, -self.iconPadding.y)
		self.icon:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.iconPadding.x, self.iconPadding.y)
		self.icon:SetWidth(self.frame:GetHeight() - 2 * self.iconPadding.y)
		self.text:SetPoint("LEFT", self.icon, "RIGHT", self.textPadding.x, 0)
	else
		self.text:SetPoint("LEFT", self.frame, "LEFT", self.textPadding.x, 0)
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
---@field textPadding table{x: number, y: number|string}
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
	self.iconPadding = defaultIconPadding
	self.textPadding = defaultTextPadding
	self.frame:Show();
	self:SetHeight(defaultFrameHeight)
	self:SetDisabled(false)
	self:SetTextHeight(defaultFontHeight)
	self:SetIcon(nil)
end

---@param self EPLabel
local function OnRelease(self)
	self:SetIcon(nil)
	self.textPadding = nil
	self.iconPadding = nil
	self.spellID = nil
end

---@param self EPLabel
---@param iconID number|nil
---@param spellID number|nil
local function SetIcon(self, iconID, spellID)
	self.icon:SetTexture(iconID)
	self.spellID = spellID
	if iconID then
		self.icon:Show()
	else
		self.icon:Hide()
	end
	UpdateFrameSize(self)
	UpdateIconSizeAndPadding(self)
end

---@param self EPLabel
---@param text string
local function SetText(self, text)
	self.text:SetText(text or "")
	UpdateFrameSize(self)
	UpdateIconSizeAndPadding(self)
end

---@param self EPLabel
---@param height number
local function SetTextHeight(self, height)
	self.text:SetTextHeight(height or defaultFontHeight)
	UpdateFrameSize(self)
	UpdateIconSizeAndPadding(self)
end

---@param self EPLabel
---@param x number
---@param y number
local function SetIconPadding(self, x, y)
	self.iconPadding.x = x
	self.iconPadding.y = y
	UpdateIconSizeAndPadding(self)
end

---@param self EPLabel
---@param x number
---@param y number|string
local function SetTextPadding(self, x, y)
	self.textPadding.x = x
	self.textPadding.y = y
	UpdateFrameSize(self)
	UpdateIconSizeAndPadding(self)
end

---@param self EPLabel
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
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
	if fPath then text:SetFont(fPath, defaultFontHeight) end
	text:SetPoint("LEFT", icon, "RIGHT", defaultTextPadding.x, 0)
	text:SetWordWrap(false)

	---@class EPLabel
	local widget = {
		OnAcquire      = OnAcquire,
		OnRelease      = OnRelease,
		SetDisabled    = SetDisabled,
		SetIcon        = SetIcon,
		SetText        = SetText,
		SetTextHeight  = SetTextHeight,
		LayoutFinished = LayoutFinished,
		SetTextPadding = SetTextPadding,
		SetIconPadding = SetIconPadding,
		frame          = frame,
		type           = Type,
		icon           = icon,
		text           = text,
		spellID        = nil
	}

	icon:SetScript("OnEnter", function() HandleIconEnter(widget) end)
	icon:SetScript("OnLeave", function() HandleIconLeave(widget) end)

	frame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
