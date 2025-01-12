local Type = "EPLineEdit"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local ClearCursor = ClearCursor
local CreateFrame = CreateFrame
local GetCursorInfo = GetCursorInfo
local GetMacroInfo = GetMacroInfo
local GetSpellInfo = C_Spell.GetSpellInfo
local tostring = tostring
local unpack = unpack

local backdropColor = { 0.1, 0.1, 0.1, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1.0 }
local disabledTextColor = { 0.5, 0.5, 0.5, 1 }
local enabledTextColor = { 1, 1, 1, 1 }
local textInsets = { 4, 4, 0, 0 }
local defaultFontSize = 14
local defaultFrameHeight = 24
local defaultFrameWidth = 200
local backdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 1,
}

---@class EPLineEdit : AceGUIWidget
---@field frame table|Frame
---@field type string
---@field editBox EditBox|BackdropTemplate
---@field enabled boolean
---@field readOnly boolean
---@field lastText string

local function HandleEditBoxReceiveDrag(self)
	local type, id, info = GetCursorInfo()
	local name
	if type == "item" then
		name = info
	elseif type == "spell" then
		local spellInfo = GetSpellInfo(tostring(id))
		if spellInfo then
			name = spellInfo.name
		end
	elseif type == "macro" then
		name = GetMacroInfo(tostring(id))
	end
	if name then
		self:SetText(name)
		self:Fire("OnEnterPressed", name)
		ClearCursor()
		AceGUI:ClearFocus()
	end
end

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
	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	self:SetEnabled(true)
	self:SetText()
	self:SetMaxLetters(256)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		self:SetFont(fPath, defaultFontSize, "")
	end
	self:SetTextInsets(unpack(textInsets))
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
		self.editBox:SetTextColor(unpack(enabledTextColor))
	else
		self.editBox:EnableMouse(false)
		self.editBox:ClearFocus()
		self.editBox:SetTextColor(unpack(disabledTextColor))
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
	self.editBox:SetCursorPosition(0)
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
		self.frame:SetScript("OnShow", function(frame, ...)
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
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local editBox = CreateFrame("EditBox", Type .. "EditBox" .. count, frame)
	editBox:SetAutoFocus(false)

	editBox:SetScript("OnEscapePressed", function(f, ...)
		AceGUI:ClearFocus()
	end)
	editBox:SetScript("OnEnterPressed", function()
		ClearCursor()
		AceGUI:ClearFocus()
	end)

	editBox:SetMaxLetters(256)
	editBox:SetPoint("TOPLEFT")
	editBox:SetPoint("BOTTOMRIGHT")
	editBox:SetTextInsets(unpack(textInsets))
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		editBox:SetFont(fPath, defaultFontSize, "")
	end

	---@class EPLineEdit
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
		editBox = editBox,
	}

	editBox:SetScript("OnEnter", function(f, ...)
		widget:Fire("OnEnter")
	end)
	editBox:SetScript("OnLeave", function(f, ...)
		widget:Fire("OnLeave")
	end)
	editBox:SetScript("OnEditFocusGained", function()
		AceGUI:SetFocus(widget)
	end)
	editBox:SetScript("OnEditFocusLost", function(f, ...)
		local value = f:GetText()
		widget:Fire("OnTextSubmitted", value)
	end)
	editBox:SetScript("OnTextChanged", function(f, ...)
		HandleEditBoxTextChanged(widget, f)
	end)
	editBox:SetScript("OnReceiveDrag", function()
		HandleEditBoxReceiveDrag(widget)
	end)
	editBox:SetScript("OnMouseDown", function()
		HandleEditBoxReceiveDrag(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
