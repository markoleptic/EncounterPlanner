local Type = "EPMessageBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local max = math.max
local unpack = unpack

local defaultFrameHeight = 200
local defaultFrameWidth = 400
local windowBarHeight = 28
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1.0 }
local defaultButtonHeight = 24
local framePadding = 15
local defaultFontSize = 14
local title = "Export as MRT Note"
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

---@class EPMessageBox : AceGUIWidget
---@field frame table|Frame
---@field type string
---@field text FontString
---@field acceptButton EPButton
---@field rejectButton EPButton
---@field windowBar Frame|table

---@param self EPMessageBox
local function OnAcquire(self)
	self:SetTitle("")
	self.frame:SetHeight(defaultFrameHeight)
	self.frame:SetWidth(defaultFrameWidth)

	self.acceptButton = AceGUI:Create("EPButton")
	self.acceptButton:SetText("Okay")
	self.acceptButton:SetWidthFromText()
	self.acceptButton:SetHeight(defaultButtonHeight)
	self.acceptButton.frame:SetParent(self.frame)
	self.acceptButton:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOM", -framePadding / 2.0, 10)
	self.acceptButton:SetCallback("Clicked", function()
		self:Fire("Accepted")
		self:Release()
	end)

	self.rejectButton = AceGUI:Create("EPButton")
	self.rejectButton:SetText("Cancel")
	self.rejectButton:SetWidthFromText()
	self.rejectButton:SetHeight(defaultButtonHeight)
	self.rejectButton.frame:SetParent(self.frame)
	self.rejectButton:SetPoint("BOTTOMLEFT", self.frame, "BOTTOM", framePadding / 2.0, 10)
	self.rejectButton:SetCallback("Clicked", function()
		self:Fire("Rejected")
		self:Release()
	end)

	local maxWidth = max(self.rejectButton.frame:GetWidth(), self.acceptButton.frame:GetWidth())
	self.rejectButton:SetWidth(maxWidth)
	self.acceptButton:SetWidth(maxWidth)

	self.frame:Show()
end

---@param self EPMessageBox
local function OnRelease(self)
	if self.acceptButton then
		self.acceptButton:Release()
	end
	if self.rejectButton then
		self.rejectButton:Release()
	end
	self.acceptButton = nil
	self.rejectButton = nil
end

---@param self EPMessageBox
---@param text string
local function SetTitle(self, text)
	self.windowBarText:SetText(text or "")
end

---@param self EPMessageBox
---@param text string
local function SetText(self, text)
	self.text:ClearAllPoints()
	self.text:SetText(text)
	self.text:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -framePadding)
	self.text:SetWidth(self.frame:GetWidth() - 2 * framePadding)
	self:SetHeight(self.windowBar:GetHeight() + self.text:GetStringHeight() + defaultButtonHeight + framePadding * 3)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetWordWrap(true)
	text:SetSpacing(framePadding / 2)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, defaultFontSize)
	end
	text:SetPoint("TOP", windowBar, "BOTTOM", 0, -framePadding)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	if fPath then
		windowBarText:SetFont(fPath, h)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	---@class EPMessageBox
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		SetTitle = SetTitle,
		frame = frame,
		type = Type,
		windowBar = windowBar,
		windowBarText = windowBarText,
		text = text,
	}
	frame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
