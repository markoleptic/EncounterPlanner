local Type = "EPEditBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultFrameHeight = 200
local defaultFrameWidth = 400
local windowBarHeight = 28
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

---@class EPEditBox : AceGUIWidget
---@field frame table|Frame
---@field scrollFrame ScrollFrame|table
---@field type string
---@field text FontString
---@field highlight Texture
---@field editBox EditBox
---@field closeButton EPButton
---@field okayButton EPButton
---@field windowBar Frame|table

---@param self EPEditBox
local function OnAcquire(self)
	self.editBox:SetText("")
	self:SetTitle("")
	self.frame:SetHeight(defaultFrameHeight)
	self.frame:SetWidth(defaultFrameWidth)

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-96]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Release()
	end)
	self:ShowOkayButton(false)

	self.frame:Show()
end

---@param self EPEditBox
local function OnRelease(self)
	if self.editBox then
		self.editBox:SetText("")
	end
	if self.closeButton then
		self.closeButton:Release()
	end
	self.closeButton = nil
	if self.okayButton then
		self.okayButton:Release()
	end
	self.okayButton = nil
end

---@param self EPEditBox
---@param text string
local function SetTitle(self, text)
	self.windowBarText:SetText(text or "")
end

---@param self EPEditBox
---@param text string
local function SetText(self, text)
	self.editBox:SetText(text or "")
	self.scrollFrame:UpdateScrollChildRect()
	self.editBox:SetSize(self.scrollFrame:GetSize())
end

---@param self EPEditBox
---@return string
local function GetText(self)
	return self.editBox:GetText()
end

---@param self EPEditBox
---@param show boolean
---@param okayButtonText string?
local function ShowOkayButton(self, show, okayButtonText)
	if show then
		if not self.okayButton then
			self.okayButton = AceGUI:Create("EPButton")
			self.okayButton.frame:SetParent(self.frame)
			self.okayButton:SetText(okayButtonText or "Okay")
			self.okayButton:SetHeight(24)
			self.okayButton:SetWidthFromText()
			self.okayButton:SetCallback("Clicked", function()
				self:Fire("OkayButtonClicked")
			end)
			self.okayButton:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 10)
		end
		self.scrollFrame:SetPoint("BOTTOM", self.okayButton.frame, "TOP", 0, 10)
	else
		if self.okayButton then
			self.okayButton:Release()
		end
		self.okayButton = nil
		self.scrollFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 10 + 16)
	end
end

---@param self EPEditBox
local function HighlightTextAndFocus(self)
	self.editBox:SetSize(self.scrollFrame:GetSize())
	self.editBox:HighlightText()
	self.editBox:SetFocus()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetResizable(true)
	frame:SetResizeBounds(defaultFrameWidth, defaultFrameHeight, nil, nil)
	frame:EnableMouse(true)
	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 1)
	windowBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		windowBarText:SetFont(fPath, h)
	end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("LEFT", 10, 0)
	scrollFrame:SetPoint("RIGHT", -32, 0)
	scrollFrame:SetPoint("TOP", 0, -windowBarHeight - 10)
	scrollFrame:SetPoint("BOTTOM", 0, 10 + 16)

	local editBox = CreateFrame("EditBox", Type .. "EditBox" .. count, scrollFrame)
	editBox:SetSize(scrollFrame:GetSize())
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(true)
	editBox:SetFontObject("ChatFontNormal")
	scrollFrame:SetScrollChild(editBox)

	local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	resizer:SetPoint("BOTTOMRIGHT", -6, 7)
	resizer:SetSize(16, 16)
	resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizer:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:StartSizing("BOTTOMRIGHT")
			self:GetHighlightTexture():Hide()
		end
	end)
	resizer:SetScript("OnMouseUp", function(self, _)
		frame:StopMovingOrSizing()
		self:GetHighlightTexture():Show()
		editBox:SetWidth(scrollFrame:GetWidth())
	end)

	---@class EPEditBox
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		HighlightTextAndFocus = HighlightTextAndFocus,
		ShowOkayButton = ShowOkayButton,
		SetTitle = SetTitle,
		frame = frame,
		scrollFrame = scrollFrame,
		type = Type,
		editBox = editBox,
		windowBar = windowBar,
		windowBarText = windowBarText,
	}
	frame.obj = widget

	editBox:SetScript("OnEscapePressed", function()
		widget:Release()
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
