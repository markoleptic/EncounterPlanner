local Type = "EPLineEdit"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local ClearCursor = ClearCursor
local CreateFrame = CreateFrame
local GetSpellInfo = C_Spell.GetSpellInfo
local tostring = tostring

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
---@field disabled boolean
---@field lastText string
---@field obj any

local function HandleEditBoxEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function HandleEditBoxLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function HandleFrameShow(frame)
	frame.obj.editBox:SetFocus()
	frame:SetScript("OnShow", nil)
end

local function HandleEditBoxEscapePressed(frame)
	AceGUI:ClearFocus()
end

local function HandleEditBoxEnterPressed(frame)
	local self = frame.obj
	local value = frame:GetText()
	self:Fire("OnEnterPressed", value)
	ClearCursor()
	AceGUI:ClearFocus()
end

local function HandleEditBoxReceiveDrag(frame)
	local self = frame.obj
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

local function HandleEditBoxTextChanged(frame)
	local self = frame.obj
	local value = frame:GetText()
	if tostring(value) ~= tostring(self.lastText) then
		self:Fire("OnTextChanged", value)
		self.lastText = value
	end
end

local function HandleEditBoxFocusGained(frame)
	AceGUI:SetFocus(frame.obj)
end

---@param self EPLineEdit
local function OnAcquire(self)
	self.frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	self:SetDisabled(false)
	self:SetText()
	self:SetMaxLetters(256)
end

---@param self EPLineEdit
local function OnRelease(self)
	self:ClearFocus()
end

---@param self EPLineEdit
local function SetDisabled(self, disabled)
	self.disabled = disabled
	if disabled then
		self.editBox:EnableMouse(false)
		self.editBox:ClearFocus()
		self.editBox:SetTextColor(0.5, 0.5, 0.5)
	else
		self.editBox:EnableMouse(true)
		self.editBox:SetTextColor(1, 1, 1)
	end
end

---@param self EPLineEdit
local function SetText(self, text)
	self.lastText = text or ""
	self.editBox:SetText(text or "")
	self.editBox:SetCursorPosition(0)
end

local function GetText(self, text)
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
		self.frame:SetScript("OnShow", HandleFrameShow)
	end
end

---@param self EPLineEdit
local function HighlightText(self, from, to)
	self.editBox:HighlightText(from, to)
end

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. num, UIParent, "BackdropTemplate")
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local editBox = CreateFrame("EditBox", Type .. num .. "EditBox", frame)
	editBox:SetAutoFocus(false)

	editBox:SetScript("OnEnter", HandleEditBoxEnter)
	editBox:SetScript("OnLeave", HandleEditBoxLeave)
	editBox:SetScript("OnEscapePressed", HandleEditBoxEscapePressed)
	editBox:SetScript("OnEnterPressed", HandleEditBoxEnterPressed)
	editBox:SetScript("OnTextChanged", HandleEditBoxTextChanged)
	editBox:SetScript("OnReceiveDrag", HandleEditBoxReceiveDrag)
	editBox:SetScript("OnMouseDown", HandleEditBoxReceiveDrag)
	editBox:SetScript("OnEditFocusGained", HandleEditBoxFocusGained)
	editBox:SetMaxLetters(256)
	editBox:SetPoint("TOPLEFT")
	editBox:SetPoint("BOTTOMRIGHT")
	editBox:SetTextInsets(8, 8, 0, 0)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		editBox:SetFont(fPath, 14, "")
	end

	---@class EPLineEdit
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetDisabled = SetDisabled,
		SetText = SetText,
		GetText = GetText,
		SetMaxLetters = SetMaxLetters,
		ClearFocus = ClearFocus,
		SetFocus = SetFocus,
		HighlightText = HighlightText,
		frame = frame,
		type = Type,
		editBox = editBox,
	}

	frame.obj = widget
	editBox.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
