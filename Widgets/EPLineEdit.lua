local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPLineEdit"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local ClearCursor = ClearCursor
local CreateFrame = CreateFrame
local tostring = tostring
local unpack = unpack

local k = {
	Backdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 1,
	},
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1.0 },
	BackdropColor = { 0.1, 0.1, 0.1, 1 },
	DefaultFontSize = 14,
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 200,
	DisabledTextColor = { 0.5, 0.5, 0.5, 1 },
	EnabledTextColor = { 1, 1, 1, 1 },
	TextInsets = { 4, 4, 0, 0 },
}

local function HandleEditBoxTextChanged(self, frame)
	local value = frame:GetText()
	if tostring(value) ~= tostring(self.lastText) then
		self:Fire("OnTextChanged", value)
		self.lastText = value
	end
end

---@param self EPLineEdit
local function OnAcquire(self)
	self.readOnly = false
	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	self:SetEnabled(true)
	self:SetText()
	self:SetMaxLetters(256)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		self:SetFont(fPath, k.DefaultFontSize, "")
	end
	self:SetTextInsets(unpack(k.TextInsets))
end

---@param self EPLineEdit
local function OnRelease(self)
	self:ClearFocus()
end

---@param self EPLineEdit
local function SetEnabled(self, enabled)
	self.enabled = enabled
	if enabled then
		self.editBox:EnableMouse(not self.readOnly)
		self.editBox:SetTextColor(unpack(k.EnabledTextColor))
	else
		self.editBox:EnableMouse(false)
		self.editBox:ClearFocus()
		self.editBox:SetTextColor(unpack(k.DisabledTextColor))
	end
end

---@param self EPLineEdit
local function SetReadOnly(self, readOnly)
	self.readOnly = readOnly
	if self.enabled then
		self.editBox:EnableMouse(not readOnly)
	end
end

---@param self EPLineEdit
local function SetText(self, text)
	self.lastText = text or ""
	self.editBox:SetText(text or "")
	self.editBox:SetCursorPosition(self.editBox:GetText():len())
end

---@param self EPLineEdit
local function GetText(self)
	return self.editBox:GetText()
end

---@param self EPLineEdit
local function SetMaxLetters(self, num)
	self.editBox:SetMaxLetters(num or 0)
end

---@param self EPLineEdit
local function ClearFocus(self)
	self.editBox:ClearFocus()
	self.frame:SetScript("OnShow", nil)
end

---@param self EPLineEdit
local function SetFocus(self)
	self.editBox:SetFocus()
	if not self.frame:IsShown() then
		self.frame:SetScript("OnShow", function(frame)
			self.editBox:SetFocus()
			frame:SetScript("OnShow", nil)
		end)
	end
end

---@param self EPLineEdit
local function HighlightText(self, from, to)
	self.editBox:HighlightText(from, to)
end

---@param self EPLineEdit
local function SetFont(self, ...)
	self.editBox:SetFont(...)
end

---@param self EPLineEdit
---@param left number
---@param right number
---@param top number
---@param bottom number
local function SetTextInsets(self, left, right, top, bottom)
	self.editBox:SetTextInsets(left, right, top, bottom)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(k.Backdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local editBox = CreateFrame("EditBox", Type .. "EditBox" .. count, frame)
	editBox:SetAutoFocus(false)

	editBox:SetScript("OnEscapePressed", function()
		AceGUI:ClearFocus()
	end)
	editBox:SetScript("OnEnterPressed", function()
		ClearCursor()
		AceGUI:ClearFocus()
	end)

	editBox:SetMaxLetters(256)
	editBox:SetPoint("TOPLEFT")
	editBox:SetPoint("BOTTOMRIGHT")
	editBox:SetTextInsets(unpack(k.TextInsets))
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		editBox:SetFont(fPath, k.DefaultFontSize, "")
	end

	---@class EPLineEdit : AceGUIWidget
	---@field enabled boolean
	---@field readOnly boolean
	---@field lastText string
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetEnabled = SetEnabled,
		SetText = SetText,
		GetText = GetText,
		SetMaxLetters = SetMaxLetters,
		ClearFocus = ClearFocus,
		SetFocus = SetFocus,
		HighlightText = HighlightText,
		SetReadOnly = SetReadOnly,
		SetFont = SetFont,
		SetTextInsets = SetTextInsets,
		frame = frame,
		type = Type,
		count = count,
		editBox = editBox,
	}

	editBox:SetScript("OnEnter", function()
		widget:Fire("OnEnter")
	end)
	editBox:SetScript("OnLeave", function()
		widget:Fire("OnLeave")
	end)
	editBox:SetScript("OnEditFocusGained", function()
		AceGUI:SetFocus(widget)
	end)
	editBox:SetScript("OnEditFocusLost", function(f)
		local value = f:GetText()
		widget:Fire("OnTextSubmitted", value)
	end)
	editBox:SetScript("OnTextChanged", function(f)
		HandleEditBoxTextChanged(widget, f)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
