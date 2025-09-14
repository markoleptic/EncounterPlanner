local _, Namespace = ...

---@class Private
local Private = Namespace

local Type = "EPEditBox"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local TextImportType = Private.classes.TextImportType

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1.0 },
	BackdropColor = { 0, 0, 0, 1 },
	DefaultFrameHeight = 400,
	DefaultFrameWidth = 600,
	FrameBackdrop = {
		bgFile = Private.constants.textures.kGenericWhite,
		edgeFile = Private.constants.textures.kGenericWhite,
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	FramePadding = 15,
	OkayButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	OkayButtonHeight = 24,
	OtherPadding = 10,
	RadioButtonGroupSpacing = { 8, 0 },
	ResizerTexture = Private.constants.textures.kResizer,
	ResizerTextureHighlight = Private.constants.textures.kResizerHighlight,
	ResizerTexturePushed = Private.constants.textures.kResizerPushed,
	ResizerSize = 16,
}

---@param self EPEditBox
---@param lineEditLabelText string
---@param lineEditText string
---@return EPContainer
local function CreateLineEditContainer(self, lineEditLabelText, lineEditText)
	local lineEditLabel = AceGUI:Create("EPLabel")
	lineEditLabel:SetText(lineEditLabelText)
	lineEditLabel:SetFrameWidthFromText()

	self.lineEdit = AceGUI:Create("EPLineEdit")
	self.lineEdit:SetMaxLetters(36)
	self.lineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
		self:Fire("ValidatePlanName", value)
		self.lastLineEditText = value
	end)
	self.lineEdit:SetCallback("OnRelease", function()
		self.lineEdit = nil
	end)
	if self.lastLineEditText then
		self.lineEdit:SetText(self.lastLineEditText)
	else
		self.lineEdit:SetText(lineEditText)
	end

	local leftSpacer = AceGUI:Create("EPSpacer")
	leftSpacer:SetFillSpace(true)
	local rightSpacer = AceGUI:Create("EPSpacer")
	rightSpacer:SetFillSpace(true)
	local lineEditContainer = AceGUI:Create("EPContainer")
	lineEditContainer:SetLayout("EPHorizontalLayout")
	lineEditContainer:SetSpacing(8, 0)
	lineEditContainer:AddChildren(leftSpacer, lineEditLabel, self.lineEdit, rightSpacer)
	lineEditContainer:SetFullWidth(true)
	return lineEditContainer
end

---@param self EPEditBox
---@param importType TextImportType
---@param radioButton EPRadioButton
---@param lineEditLabelText string
---@param lineEditText string
local function HandleRadioButtonToggled(self, importType, radioButton, lineEditLabelText, lineEditText)
	if self.radioButtonGroup then
		if importType == TextImportType.CreateNew then
			if not self.lineEdit then
				self.container:AddChild(CreateLineEditContainer(self, lineEditLabelText, lineEditText))
				self.container:DoLayout()
			end
			self:Fire("ValidatePlanName", self.lineEdit:GetText())
		elseif self.lineEdit and #self.container.children > 1 then
			self.container:RemoveChild(self.container.children[2])
		end
		for _, radioButtonGroupChild in ipairs(self.radioButtonGroup.children) do
			if radioButtonGroupChild.type == "EPRadioButton" then
				---@cast radioButtonGroupChild EPRadioButton
				if radioButtonGroupChild ~= radioButton then
					radioButtonGroupChild:SetToggled(false)
				end
			end
		end
	end
end

---@param self EPEditBox
local function OnAcquire(self)
	self.editBox:SetText("")
	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	self.editBox:SetSize(k.DefaultFrameWidth, k.DefaultFrameWidth)

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle("")
	windowBar.frame:SetParent(self.frame)
	windowBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	windowBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
	windowBar:SetCallback("CloseButtonClicked", function()
		self:Fire("CloseButtonClicked")
	end)
	windowBar:SetCallback("OnMouseDown", function()
		self.frame:StartMoving()
	end)
	windowBar:SetCallback("OnMouseUp", function()
		self.frame:StopMovingOrSizing()
		local x, y = self.frame:GetLeft(), self.frame:GetTop()
		self.frame:StopMovingOrSizing()
		self.frame:ClearAllPoints()
		self.frame:SetPoint(
			"TOP",
			x - UIParent:GetWidth() / 2.0 + self.frame:GetWidth() / 2.0,
			-(UIParent:GetHeight() - y)
		)
	end)
	self.windowBar = windowBar

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetScript("OnMouseUp", function()
		if not self.editBox:IsMouseOver() then
			if self.scrollFrame then
				if self.scrollFrame.frame:IsMouseOver(-2, 2, 2, -2) then
					local cursorPosition = self.editBox:GetText():len()
					self.editBox:SetFocus()
					self.editBox:SetCursorPosition(cursorPosition)
				end
			end
		end
	end)
	self.scrollFrame.frame:SetParent(self.frame)
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", k.FramePadding, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.FramePadding)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.FramePadding, 0)
	self.scrollFrame.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.FramePadding)
	self.scrollFrame:SetScrollChild(self.editBox, true, true)

	self.editBox:SetScript("OnTextChanged", function()
		self.scrollFrame:UpdateVerticalScroll()
		self.scrollFrame:UpdateThumbPositionAndSize()
	end)

	self.frame:Show()

	self:ShowOkayButton(false)
end

---@param self EPEditBox
local function OnRelease(self)
	self.windowBar:Release()
	self.windowBar = nil

	self.editBox:SetText("")
	self.editBox:SetScript("OnTextChanged", nil)

	if self.scrollFrame then
		self.scrollFrame.frame:SetScript("OnMouseUp", nil)
		self.scrollFrame:Release()
	end
	self.scrollFrame = nil

	if self.okayButton then
		self.okayButton:Release()
	end
	self.okayButton = nil

	if self.container then
		self.container:Release()
	end
	self.container = nil
	self.radioButtonGroup = nil
	self.lastLineEditText = nil
	self.lineEdit = nil
end

---@param self EPEditBox
---@param text string
local function SetTitle(self, text)
	self.windowBar:SetTitle(text or "")
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
			self.okayButton.frame:SetParent(self.frame)
			self.okayButton:SetText(okayButtonText or "Okay")
			self.okayButton:SetHeight(k.OkayButtonHeight)
			self.okayButton:SetWidthFromText()
			self.okayButton:SetColor(unpack(k.OkayButtonColor))
			self.okayButton:SetCallback("Clicked", function()
				self:Fire("OkayButtonClicked")
			end)
			self.okayButton.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.FramePadding)
		end
		self.scrollFrame.frame:SetPoint("BOTTOM", self.okayButton.frame, "TOP", 0, k.FramePadding)
	else
		if self.okayButton then
			self.okayButton:Release()
		end
		self.okayButton = nil
		self.scrollFrame.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.FramePadding)
	end
end

---@param self EPEditBox
---@param show boolean
---@param radioButtonText table<integer, string>
---@param lineEditLabelText string
---@param lineEditText string
local function ShowRadioButtonGroup(self, show, radioButtonText, lineEditLabelText, lineEditText)
	if show then
		if not self.container then
			self.container = AceGUI:Create("EPContainer")
			self.container:SetLayout("EPVerticalLayout")
			self.container:SetSpacing(0, 10)
			self.container.frame:SetParent(self.frame)
			self.container.frame:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.FramePadding)

			local radioButtonGroupChildren = {}

			for index, text in ipairs(radioButtonText) do
				local radioButton = AceGUI:Create("EPRadioButton")
				radioButton:SetLabelText(text)
				radioButton:SetToggled(false)
				radioButton:SetCallback("Toggled", function()
					HandleRadioButtonToggled(self, index, radioButton, lineEditLabelText, lineEditText)
				end)
				tinsert(radioButtonGroupChildren, radioButton)
			end
			radioButtonGroupChildren[1]:SetToggled(true)

			local radioButtonGroup = AceGUI:Create("EPContainer")
			radioButtonGroup:SetLayout("EPHorizontalLayout")
			radioButtonGroup:SetSpacing(unpack(k.RadioButtonGroupSpacing))
			radioButtonGroup:AddChildren(unpack(radioButtonGroupChildren))
			self.radioButtonGroup = radioButtonGroup

			self.container:AddChild(radioButtonGroup)
			self.scrollFrame.frame:SetPoint("TOP", self.container.frame, "BOTTOM", 0, -k.OtherPadding)
		end
	else
		if self.container then
			self.container:Release()
		end
		self.container = nil
		self.radioButtonGroup = nil
		self.lineEdit = nil
		self.scrollFrame.frame:SetPoint("TOP", self.windowBar.frame, "TOP", 0, -k.FramePadding)
	end
end

---@param self EPEditBox
local function HighlightTextAndFocus(self)
	self.editBox:SetFocus()
	self.editBox:HighlightText()
end

---@param self EPEditBox
---@param position integer
local function SetFocusAndCursorPosition(self, position)
	self.editBox:SetFocus()
	self.editBox:SetCursorPosition(position)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetResizable(true)
	frame:SetResizeBounds(k.DefaultFrameWidth, k.DefaultFrameHeight, nil, nil)
	frame:EnableMouse(true)

	local editBox = CreateFrame("EditBox", Type .. "EditBox" .. count, frame)
	editBox:SetMultiLine(true)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetMaxLetters(99999)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetTextInsets(5, 5, 5, 5)

	local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	resizer:SetPoint("BOTTOMRIGHT", -1, 1)
	resizer:SetSize(k.ResizerSize, k.ResizerSize)
	resizer:SetNormalTexture(k.ResizerTexture)
	resizer:SetHighlightTexture(k.ResizerTextureHighlight)
	resizer:SetPushedTexture(k.ResizerTexturePushed)

	---@class EPEditBox : AceGUIWidget
	---@field okayButton EPButton
	---@field radioButtonGroup EPContainer
	---@field lineEdit EPLineEdit
	---@field lastLineEditText string
	---@field container EPContainer
	---@field windowBar EPWindowBar
	---@field scrollFrame EPScrollFrame
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		HighlightTextAndFocus = HighlightTextAndFocus,
		ShowOkayButton = ShowOkayButton,
		SetTitle = SetTitle,
		ShowRadioButtonGroup = ShowRadioButtonGroup,
		SetFocusAndCursorPosition = SetFocusAndCursorPosition,
		frame = frame,
		type = Type,
		count = count,
		editBox = editBox,
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
