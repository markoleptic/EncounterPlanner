local Type = "EPEditBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local defaultFrameHeight = 400
local defaultFrameWidth = 600
local windowBarHeight = 28
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1.0 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local okayButtonHeight = 24
local resizerSize = 16
local framePadding = 15
local otherPadding = 10
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

---@param self EPEditBox
local function OnAcquire(self)
	self.editBox:SetText("")
	self:SetTitle("")

	self.frame:SetHeight(defaultFrameHeight)
	self.frame:SetWidth(defaultFrameWidth)
	self.editBox:SetSize(defaultFrameWidth, defaultFrameWidth)
	self.frame:Show()

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame --[[@as Frame]])
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", framePadding, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -framePadding)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -framePadding, 0)
	self.scrollFrame.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, framePadding)
	self.scrollFrame:SetScrollChild(self.editBox --[[@as Frame]], true, true)

	self.editBox:SetScript("OnTextChanged", function()
		self.scrollFrame:UpdateVerticalScroll()
		self.scrollFrame:UpdateThumbPositionAndSize()
	end)

	self:ShowOkayButton(false)
end

---@param self EPEditBox
local function OnRelease(self)
	self.editBox:SetText("")
	self.editBox:SetScript("OnTextChanged", nil)

	if self.scrollFrame then
		self.scrollFrame:Release()
	end
	self.scrollFrame = nil

	if self.closeButton then
		self.closeButton:Release()
	end
	self.closeButton = nil

	if self.okayButton then
		self.okayButton:Release()
	end
	self.okayButton = nil

	if self.container then
		self.container:Release()
	end
	self.container = nil

	self.checkBox = nil
	self.lineEdit = nil
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
			self.okayButton.frame:SetParent(self.frame --[[@as Frame]])
			self.okayButton:SetText(okayButtonText or "Okay")
			self.okayButton:SetHeight(okayButtonHeight)
			self.okayButton:SetWidthFromText()
			self.okayButton:SetCallback("Clicked", function()
				self:Fire("OkayButtonClicked")
			end)
			self.okayButton.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, framePadding)
		end
		self.scrollFrame.frame:SetPoint("BOTTOM", self.okayButton.frame, "TOP", 0, framePadding)
	else
		if self.okayButton then
			self.okayButton:Release()
		end
		self.okayButton = nil
		self.scrollFrame.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, framePadding)
	end
end

---@param self EPEditBox
---@param show boolean
---@param checkBoxText string
---@param lineEditLabelText string
---@param lineEditText string
local function ShowCheckBoxAndLineEdit(self, show, checkBoxText, lineEditLabelText, lineEditText)
	if show then
		if not self.container then
			self.container = AceGUI:Create("EPContainer")
			self.container:SetLayout("EPVerticalLayout")
			self.container:SetSpacing(0, 10)
			self.container.frame:SetParent(self.frame --[[@as Frame]])
			self.container.frame:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -framePadding)

			local lineEditLabel = AceGUI:Create("EPLabel")
			lineEditLabel:SetText(lineEditLabelText)
			lineEditLabel:SetFrameWidthFromText()

			self.checkBox = AceGUI:Create("EPCheckBox")
			self.checkBox:SetText(checkBoxText)
			self.checkBox:SetChecked(false)
			self.checkBox:SetFrameWidthFromText()
			self.checkBox:SetCallback("OnValueChanged", function(_, _, checked)
				self.lineEdit:SetEnabled(not checked)
				lineEditLabel:SetEnabled(not checked)
				self:Fire("OverwriteCheckBoxValueChanged", checked)
			end)

			self.lineEdit = AceGUI:Create("EPLineEdit")
			self.lineEdit:SetText(lineEditText)
			self.lineEdit:SetMaxLetters(36)
			self.lineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
				self:Fire("ValidatePlanName", value)
			end)

			local container = AceGUI:Create("EPContainer")
			container:SetLayout("EPHorizontalLayout")
			container:SetSpacing(8, 0)
			container:AddChildren(lineEditLabel, self.lineEdit)

			self.container:AddChildren(self.checkBox, container)
			self.scrollFrame.frame:SetPoint("TOP", self.container.frame, "BOTTOM", 0, -otherPadding)
		end
	else
		if self.container then
			self.container:Release()
		end
		self.container = nil
		self.checkBox = nil
		self.lineEdit = nil
		self.scrollFrame.frame:SetPoint("TOP", self.windowBar, "TOP", 0, -framePadding)
	end
end

---@param self EPEditBox
local function HighlightTextAndFocus(self)
	self.editBox:SetFocus()
	self.editBox:HighlightText()
end

---@param self EPEditBox
local function SetFocusAndCursorPosition(self, position)
	self.editBox:SetFocus()
	self.editBox:SetCursorPosition(position)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
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
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText("Title")
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

	local editBox = CreateFrame("EditBox", Type .. "EditBox" .. count, frame)
	editBox:SetMultiLine(true)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetMaxLetters(99999)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetTextInsets(5, 5, 5, 5)

	local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	resizer:SetPoint("BOTTOMRIGHT", -1, 1)
	resizer:SetSize(resizerSize, resizerSize)
	resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	---@class EPEditBox : AceGUIWidget
	---@field closeButton EPButton
	---@field okayButton EPButton
	---@field checkBox EPCheckBox
	---@field lineEdit EPLineEdit
	---@field container EPContainer
	---@field windowBar Frame|table
	---@field scrollFrame EPScrollFrame
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		HighlightTextAndFocus = HighlightTextAndFocus,
		ShowOkayButton = ShowOkayButton,
		SetTitle = SetTitle,
		ShowCheckBoxAndLineEdit = ShowCheckBoxAndLineEdit,
		SetFocusAndCursorPosition = SetFocusAndCursorPosition,
		frame = frame,
		type = Type,
		editBox = editBox,
		windowBar = windowBar,
		windowBarText = windowBarText,
	}

	resizer:SetScript("OnMouseDown", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			frame:StartSizing("BOTTOMRIGHT")
		end
	end)

	resizer:SetScript("OnMouseUp", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			frame:StopMovingOrSizing()
		end
	end)

	editBox:SetScript("OnEscapePressed", function()
		widget:Release()
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
