local Type = "EPStatusBar"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local ColorMixin = ColorMixin
local CreateFrame = CreateFrame
local ipairs = ipairs
local LSM = LibStub("LibSharedMedia-3.0")
local select = select
local tinsert = tinsert
local UIParent = UIParent
local wipe = wipe

local defaultFrameHeight = 400
local defaultFrameWidth = 400
local fontSize = 12
local lineNumberWidth = 20
local textPadding = 2
local padding = { left = 2, top = 2, right = 2, bottom = 2 }

---@class EPStatusBar : AceGUIWidget
---@field frame table|Frame|BackdropTemplate
---@field messageFrame table|Frame
---@field scrollFrame EPScrollFrame
---@field activeMessages table<integer, {lineNumber: FontString, line:FontString}>
---@field messagePool table<integer, {lineNumber: FontString, line:FontString}>
---@field lineNumberPool table<integer, FontString>
---@field type string
---@field lineNumber integer

---@param self EPStatusBar
local function OnAcquire(self)
	self.lineNumber = 1
	self.messageFrame:SetHeight(padding.top)
	self.messagePool = self.messagePool or {}
	self.activeMessages = {}
	self.frame:Show()
	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame --[[@as Frame]])
	self.scrollFrame.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	self.scrollFrame.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT")
	self.scrollFrame:SetScrollChild(self.messageFrame, true, true)
end

---@param self EPStatusBar
local function OnRelease(self)
	self:ClearMessages()
	self.scrollFrame:Release()
	self.scrollFrame = nil
end

---@param self EPStatusBar
---@param message string
---@param severityLevel SeverityLevel?
---@param indentLevel IndentLevel?
---@return number -- textHeight
local function AddSingleMessage(self, message, severityLevel, indentLevel)
	local lineNumber, --[[@as FontString]]
		line --[[@as FontString]]
	if #self.messagePool > 0 then
		local obj = self.messagePool[#self.messagePool]
		self.messagePool[#self.messagePool] = nil
		lineNumber, line = obj.lineNumber, obj.line
	else
		lineNumber = self.messageFrame:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
		lineNumber:SetJustifyH("LEFT")
		lineNumber:SetTextColor(0.35, 0.35, 0.35)

		line = self.messageFrame:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
		line:SetJustifyH("LEFT")
		line:SetWordWrap(true)
		line:SetSpacing(0)
		line:SetIndentedWordWrap(false)

		local fPath = LSM:Fetch("font", "PT Sans Narrow")
		if fPath then
			lineNumber:SetFont(fPath, fontSize)
			line:SetFont(fPath, fontSize)
		end
	end

	lineNumber:Show()
	line:Show()

	lineNumber:SetText(format("%d", self.lineNumber))

	if not severityLevel or severityLevel == 1 then
		ColorMixin:SetRGB(1, 1, 1)
	elseif severityLevel == 2 then
		ColorMixin:SetRGB(1, 0.82, 0)
	elseif severityLevel == 3 then
		ColorMixin:SetRGB(0.85, 0.2, 0.2)
	end
	message = ColorMixin:WrapTextInColorCode(message)

	if not indentLevel or indentLevel == 1 then
		line:SetText(message)
	elseif indentLevel == 2 then
		line:SetText("    " .. message)
	elseif indentLevel == 3 then
		line:SetText("    " .. "    " .. message)
	end

	lineNumber:SetWidth(lineNumberWidth)

	lineNumber:ClearAllPoints()
	line:ClearAllPoints()

	line:SetPoint("LEFT", self.messageFrame, "LEFT", lineNumberWidth + padding.left, 0)
	line:SetPoint("RIGHT", self.messageFrame, "RIGHT", -padding.right, 0)
	lineNumber:SetPoint("RIGHT", line, "LEFT")

	local textHeight = line:GetHeight()
	if #self.activeMessages > 0 then
		local lastLine = self.activeMessages[#self.activeMessages].line
		line:SetPoint("TOP", lastLine, "BOTTOM", 0, -textPadding)
		textHeight = textHeight + textPadding
	else
		line:SetPoint("TOP", self.messageFrame, "TOP", 0, -padding.top)
		textHeight = textHeight + padding.top
	end

	self.lineNumber = self.lineNumber + 1
	tinsert(self.activeMessages, { lineNumber = lineNumber, line = line })

	return textHeight
end

---@param self EPStatusBar
---@param message string
---@param severityLevel SeverityLevel?
---@param indentLevel IndentLevel?
local function AddMessage(self, message, severityLevel, indentLevel)
	local textHeight = AddSingleMessage(self, message, severityLevel, indentLevel)
	self.messageFrame:SetHeight(self.messageFrame:GetHeight() + textHeight)
	self.scrollFrame:SetScroll(select(2, self.scrollFrame:GetScrollRange()))
end

---@param self EPStatusBar
---@param messages table<integer, {message: string, severityLevel: integer, indentLevel: integer}>
local function AddMessages(self, messages)
	local height = self.messageFrame:GetHeight()
	for _, message in ipairs(messages) do
		height = height + AddSingleMessage(self, message.message, message.severityLevel, message.indentLevel)
	end
	self.messageFrame:SetHeight(height)
	self.scrollFrame:SetScroll(select(2, self.scrollFrame:GetScrollRange()))
end

---@param self EPStatusBar
local function ClearMessages(self)
	for _, obj in ipairs(self.activeMessages) do
		obj.lineNumber:ClearAllPoints()
		obj.lineNumber:SetText("")
		obj.lineNumber:Hide()
		obj.line:ClearAllPoints()
		obj.line:SetText("")
		obj.line:Hide()
		tinsert(self.messagePool, obj)
	end
	wipe(self.activeMessages)
	self.messageFrame:SetHeight(padding.bottom)
	self.lineNumber = 1
end

---@param self EPStatusBar
local function OnWidthSet(self)
	local height = 0.0
	for _, obj in ipairs(self.activeMessages) do
		height = height + obj.line:GetHeight() + textPadding
	end
	if height > 0.0 then
		height = height + padding.top
	end
	self.messageFrame:SetHeight(height + padding.bottom)
	self.scrollFrame:SetScroll(select(2, self.scrollFrame:GetScrollRange()))
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:EnableMouse(true)

	local messageFrame = CreateFrame("Frame", Type .. "MessageContainer" .. count, frame)
	messageFrame:SetSize(defaultFrameWidth, defaultFrameHeight)
	messageFrame:EnableMouse(true)

	---@class EPStatusBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		ClearMessages = ClearMessages,
		AddMessage = AddMessage,
		AddMessages = AddMessages,
		OnWidthSet = OnWidthSet,
		frame = frame,
		messageFrame = messageFrame,
		type = Type,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
