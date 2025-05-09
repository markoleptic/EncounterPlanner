local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPTutorial"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent

local CreateFrame = CreateFrame
local ipairs = ipairs
local max = math.max
local unpack = unpack

local defaultHeight = 200
local defaultWidth = 350
local defaultButtonHeight = 20
local defaultFontSize = 14
local contentFramePadding = { x = 10, y = 10 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local otherPadding = { x = 10, y = 10 }
local windowBarHeight = 28
local buttonColor = Private.constants.colors.kNeutralButtonActionColor
local backdropColor = { 0, 0, 0, 0.9 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local title = L["Tutorial"]
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

---@param container EPContainer
local function SetButtonWidths(container)
	local maxWidth = 0
	for _, child in ipairs(container.children) do
		if child.type == "EPButton" then
			maxWidth = max(maxWidth, child.frame:GetWidth())
		end
	end
	for _, child in ipairs(container.children) do
		if child.type == "EPButton" then
			child:SetWidth(maxWidth)
		end
	end
end

---@param self EPTutorial
local function OnAcquire(self)
	self.previousText = ""
	self.currentStep = 0
	self.totalSteps = 0
	self.frame:SetSize(defaultWidth, defaultHeight)

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton.frame:SetParent(self.windowBar --[[@as Frame]])
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.container = AceGUI:Create("EPContainer")
	self.container:SetLayout("EPVerticalLayout")
	self.container.frame:SetParent(self.frame --[[@as Frame]])
	self.container.frame:EnableMouse(true)
	self.container.frame:SetPoint(
		"TOPLEFT",
		self.windowBar,
		"BOTTOMLEFT",
		contentFramePadding.x,
		-contentFramePadding.y
	)

	self.text:SetPoint("TOPLEFT", self.container.frame, "TOPLEFT")
	self.text:SetPoint("BOTTOMRIGHT", self.container.frame, "BOTTOMRIGHT")
	self.text:SetScript("OnTextChanged", function()
		self.text:SetText(self.previousText)
	end)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(otherPadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame --[[@as Frame]])
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, contentFramePadding.y)

	self.progressBar = AceGUI:Create("EPProgressBar")
	self.progressBar.frame:SetParent(self.frame --[[@as Frame]])
	self.progressBar:SetPoint("BOTTOM", self.buttonContainer.frame --[[@as Frame]], "TOP", 0, contentFramePadding.y)

	local previousButton = AceGUI:Create("EPButton")
	previousButton:SetText(L["Previous"])
	previousButton:SetWidthFromText()
	previousButton:SetHeight(defaultButtonHeight)
	previousButton:SetColor(unpack(buttonColor))
	previousButton:SetCallback("Clicked", function()
		self:Fire("PreviousButtonClicked")
	end)
	self.previousButton = previousButton

	local nextButton = AceGUI:Create("EPButton")
	nextButton:SetText(L["Start"])
	nextButton:SetWidthFromText()
	nextButton:SetHeight(defaultButtonHeight)
	nextButton:SetColor(unpack(buttonColor))
	nextButton:SetCallback("Clicked", function()
		self:Fire("NextButtonClicked")
	end)
	self.nextButton = nextButton

	self.buttonContainer:AddChildNoDoLayout(previousButton)
	self.buttonContainer:AddChildNoDoLayout(nextButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	self.frame:Show()
end

---@param self EPTutorial
local function OnRelease(self)
	self.container:Release()
	self.container = nil
	self.buttonContainer:Release()
	self.buttonContainer = nil
	self.progressBar:Release()
	self.progressBar = nil

	self.previousButton = nil
	self.nextButton = nil

	self.currentStep = nil
	self.totalSteps = nil
end

---@param self EPTutorial
local function InitProgressBar(self, totalSteps, barTexture)
	self.totalSteps = totalSteps
	local preferences = {
		enabled = true,
		font = "Interface\\Addons\\EncounterPlanner\\Media\\Fonts\\PTSansNarrow-Bold.ttf",
		fontSize = 12,
		fontOutline = "",
		alpha = 1.0,
		texture = barTexture,
		iconPosition = "LEFT",
		height = 12,
		width = 200,
		durationAlignment = "CENTER",
		fill = false,
		showBorder = false,
		showIconBorder = false,
		color = buttonColor,
		backgroundColor = Private.constants.colors.kDefaultButtonBackdropColor,
	}
	self.progressBar:Set(preferences, "", 0, nil)
	self.progressBar.statusBar:SetValue(0)
	self.progressBar.statusBar:SetMinMaxValues(0, totalSteps - 1)
	self.progressBar.duration:SetFormattedText("%0d%%", 0)
	self.progressBar:RestyleBar()
end

---@param self EPTutorial
---@param step integer
---@param text string
---@param enableNext boolean
local function SetCurrentStep(self, step, text, enableNext)
	self.currentStep = step
	self.previousButton:SetEnabled(step > 1)
	self.nextButton:SetEnabled(enableNext)
	if step == 1 then
		self.buttonContainer.children[2]:SetText(L["Start"])
	elseif step == self.totalSteps then
		self.buttonContainer.children[2]:SetText(L["Finish"])
	else
		self.buttonContainer.children[2]:SetText(L["Next"])
	end
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	self.text:SetText(text)
	self.previousText = text

	self.progressBar.statusBar:SetValue(step - 1)
	self.progressBar.duration:SetFormattedText("%0d%%", ((step - 1) / (self.totalSteps - 1)) * 100)
	self:Resize()
end

---@param self EPTutorial
local function Resize(self)
	self.progressBar.frame:SetWidth(defaultWidth - contentFramePadding.x * 2)
	self.progressBar:RestyleBar()
	self.container.frame:SetWidth(defaultWidth - contentFramePadding.x * 2)
	self.text:ClearAllPoints()
	self.measureText:SetWidth(defaultWidth - contentFramePadding.x * 2)
	self.measureText:SetText(self.text:GetText())
	self.text:SetWidth(defaultWidth - contentFramePadding.x * 2)
	self.container.frame:SetHeight(self.measureText:GetHeight())
	self.text:SetPoint("CENTER", self.container.frame)

	local containerHeight = self.container.frame:GetHeight()
	local buttonContainerHeight = self.buttonContainer.frame:GetHeight()
	local progressBarHeight = self.progressBar.frame:GetHeight()
	local paddingHeight = contentFramePadding.y * 4

	local height = windowBarHeight + buttonContainerHeight + paddingHeight + containerHeight + progressBarHeight
	self.frame:SetSize(defaultWidth, height)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultWidth, defaultHeight)
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")

	local measureText = frame:CreateFontString(nil, "OVERLAY")
	measureText:SetWordWrap(true)
	measureText:SetSpacing(4)
	measureText:SetJustifyH("CENTER")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		measureText:SetFont(fPath, defaultFontSize, "")
	end

	local text = CreateFrame("EditBox", Type .. "EditBox" .. count, frame)
	text:SetSpacing(4)
	text:SetMultiLine(true)
	text:EnableMouse(true)
	text:SetAutoFocus(false)
	text:SetFontObject("ChatFontNormal")
	text:SetJustifyH("CENTER")
	if fPath then
		text:SetFont(fPath, defaultFontSize, "")
	end

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)

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

	---@class EPTutorial : AceGUIWidget
	---@field closeButton EPButton
	---@field container EPContainer
	---@field buttonContainer EPContainer
	---@field progressBar EPProgressBar
	---@field currentStep integer
	---@field totalSteps integer
	---@field previousButton EPButton
	---@field nextButton EPButton
	---@field previousText string
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		Resize = Resize,
		SetCurrentStep = SetCurrentStep,
		InitProgressBar = InitProgressBar,
		frame = frame,
		type = Type,
		windowBar = windowBar,
		text = text,
		measureText = measureText,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
