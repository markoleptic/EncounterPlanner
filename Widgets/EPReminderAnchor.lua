local Type = "EPReminderAnchor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local IsMouseButtonDown = IsMouseButtonDown
local ResetCursor = ResetCursor
local select = select
local SetCursor = SetCursor
local type = type

local defaultFrameHeight = 30
local defaultFrameWidth = 400
local defaultText = "Assignment Text Here"
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local isChoosingFrame = false

---@param left number
---@param top number
---@param width number
---@param height number
---@param point "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"
---@param rLeft number
---@param rTop number
---@param rWidth number
---@param rhHeight number
---@param rPoint "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"
local function calculateNewOffset(left, top, width, height, point, rLeft, rTop, rWidth, rhHeight, rPoint)
	if point == "TOP" then
		left = left + width / 2.0
	elseif point == "TOPRIGHT" then
		left = left + width
	elseif point == "RIGHT" then
		left = left + width
		top = top - height / 2.0
	elseif point == "BOTTOMRIGHT" then
		left = left + width
		top = top - height
	elseif point == "BOTTOM" then
		left = left + width / 2.0
		top = top - height
	elseif point == "LEFT" then
		top = top - height / 2.0
	elseif point == "BOTTOMLEFT" then
		top = top - height
	elseif point == "CENTER" then
		left = left + width / 2.0
		top = top - height / 2.0
	end

	if rPoint == "TOP" then
		rLeft = rLeft + rWidth / 2.0
	elseif rPoint == "TOPRIGHT" then
		rLeft = rLeft + rWidth
	elseif rPoint == "RIGHT" then
		rLeft = rLeft + rWidth
		rTop = rTop - rhHeight / 2.0
	elseif rPoint == "BOTTOMRIGHT" then
		rLeft = rLeft + rWidth
		rTop = rTop - rhHeight
	elseif rPoint == "BOTTOM" then
		rLeft = rLeft + rWidth / 2.0
		rTop = rTop - rhHeight
	elseif rPoint == "LEFT" then
		rTop = rTop - rhHeight / 2.0
	elseif rPoint == "BOTTOMLEFT" then
		rTop = rTop - rhHeight
	elseif rPoint == "CENTER" then
		rLeft = rLeft + rWidth / 2.0
		rTop = rTop - rhHeight / 2.0
	end

	return left - rLeft, top - rTop
end

local function GetName(frame)
	if frame.GetName and frame:GetName() then
		return frame:GetName()
	end
	local parent = frame.GetParent and frame:GetParent()
	if parent then
		return GetName(parent) .. ".UnknownChild"
	end
	return nil
end

local function StopChoosingFrame(frameChooserFrame, frameChooserBox, focusName)
	isChoosingFrame = false
	if frameChooserFrame then
		frameChooserFrame:SetScript("OnUpdate", nil)
		frameChooserBox:Hide()
	end
	ResetCursor()
	if frameChooserFrame and frameChooserFrame.obj and frameChooserFrame.obj.SetAnchorFrame then
		frameChooserFrame.obj:SetAnchorFrame(focusName)
	end
end

local function StartChoosingFrame(frameChooserFrame, frameChooserBox)
	isChoosingFrame = true
	local oldFocus = nil
	local oldFocusName = nil
	local focusName = nil
	SetCursor("CAST_CURSOR")
	frameChooserFrame:SetScript("OnUpdate", function()
		if IsMouseButtonDown("RightButton") then
			StopChoosingFrame(frameChooserFrame, frameChooserBox, nil)
			return
		elseif IsMouseButtonDown("LeftButton") then
			if oldFocusName then
				StopChoosingFrame(frameChooserFrame, frameChooserBox, oldFocusName)
			else
				StopChoosingFrame(frameChooserFrame, frameChooserBox, "UIParent")
			end
		else
			local foci = GetMouseFoci()
			local focus = foci[1] or nil
			if focus then
				focusName = GetName(focus)
				if focusName == "WorldFrame" or not focusName then
					focusName = nil
				end
				if focus ~= oldFocus then
					if focusName then
						frameChooserBox:ClearAllPoints()
						frameChooserBox:SetPoint("BOTTOMLEFT", focus, "BOTTOMLEFT", 4, -4)
						frameChooserBox:SetPoint("TOPRIGHT", focus, "TOPRIGHT", -4, 4)
						frameChooserBox:Show()
					end
					if focusName ~= oldFocusName then
						oldFocusName = focusName
					end
					oldFocus = focus
				end
			end
			if not focusName then
				frameChooserBox:Hide()
			else
				SetCursor("CAST_CURSOR")
			end
		end
	end)
end

---@class EPReminderAnchor : AceGUIWidget
---@field frame table|Frame
---@field textFrame table|Frame
---@field type string
---@field assignmentText FontString
---@field container EPContainer
---@field alignCenterButton EPButton
---@field alignLeftButton EPButton
---@field alignRightButton EPButton
---@field increaseFontSizeButton EPButton
---@field decreaseFontSizeButton EPButton
---@field chooseAnchorFrameButton EPButton
---@field simulateButton EPButton
---@field anchorDropdown EPDropdown
---@field anchorFrameNameLabel EPLabel
---@field relativeAnchorDropdown EPDropdown
---@field xPositionLineEdit EPLineEdit
---@field yPositionLineEdit EPLineEdit
---@field preferences EncounterPlannerPreferences

---@param self EPReminderAnchor
local function OnAcquire(self)
	self.assignmentText:SetText(defaultText)
	self.assignmentText:SetJustifyH("CENTER")

	self.frame:SetHeight(defaultFrameHeight)
	self.frame:SetWidth(defaultFrameWidth)

	self.container = AceGUI:Create("EPContainer")
	self.container.frame:SetParent(self.frame)
	self.container:SetLayout("EPVerticalLayout")
	self.container:SetSpacing(0, 5)
	self.container:SetWidth(70)

	local textAlignLabel = AceGUI:Create("EPLabel")
	textAlignLabel:SetText("Text Align:")
	textAlignLabel:SetHeight(24)
	textAlignLabel:SetFrameWidthFromText()
	local fontSizeLabel = AceGUI:Create("EPLabel")
	fontSizeLabel:SetText("Font Size: ")
	fontSizeLabel:SetHeight(24)
	fontSizeLabel:SetFrameWidthFromText()
	local labelContainer = AceGUI:Create("EPContainer")
	labelContainer:SetLayout("EPVerticalLayout")
	labelContainer:SetFullWidth(true)
	labelContainer:SetSpacing(0, 0)

	local textAlignContainer = AceGUI:Create("EPContainer")
	textAlignContainer:SetLayout("EPHorizontalLayout")
	textAlignContainer:SetFullWidth(true)
	textAlignContainer:SetSpacing(2, 0)
	local leftTextAlignSpacer = AceGUI:Create("EPSpacer")
	leftTextAlignSpacer:SetFillSpace(true)
	local rightTextAlignSpacer = AceGUI:Create("EPSpacer")
	rightTextAlignSpacer:SetFillSpace(true)
	self.alignLeftButton = AceGUI:Create("EPButton")
	self.alignLeftButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-align-text-left-32]])
	self.alignLeftButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignLeftButton:SetHeight(24)
	self.alignLeftButton:SetWidth(24)
	self.alignLeftButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("LEFT")
	end)
	self.alignCenterButton = AceGUI:Create("EPButton")
	self.alignCenterButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-align-text-center-32]])
	self.alignCenterButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignCenterButton:SetHeight(24)
	self.alignCenterButton:SetWidth(24)
	self.alignCenterButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("CENTER")
	end)
	self.alignRightButton = AceGUI:Create("EPButton")
	self.alignRightButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-align-text-right-32]])
	self.alignRightButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignRightButton:SetHeight(24)
	self.alignRightButton:SetWidth(24)
	self.alignRightButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("RIGHT")
	end)

	local fontSizeContainer = AceGUI:Create("EPContainer")
	fontSizeContainer:SetLayout("EPHorizontalLayout")
	fontSizeContainer:SetFullWidth(true)
	fontSizeContainer:SetSpacing(2, 0)
	fontSizeContainer:SetAlignment("center")
	local leftFontSizeSpacer = AceGUI:Create("EPSpacer")
	leftFontSizeSpacer:SetFillSpace(true)
	local rightFontSizeSpacer = AceGUI:Create("EPSpacer")
	rightFontSizeSpacer:SetFillSpace(true)
	self.increaseFontSizeButton = AceGUI:Create("EPButton")
	self.increaseFontSizeButton:SetText("+")
	self.increaseFontSizeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.increaseFontSizeButton:SetWidth(24)
	self.increaseFontSizeButton:SetHeight(24)
	self.increaseFontSizeButton:SetCallback("Clicked", function()
		local font, size, flags = self.assignmentText:GetFont()
		if font then
			self.assignmentText:SetFont(font, math.min(48, size + 2), flags)
			self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
			local x, y = select(4, self.frame:GetPoint())
			self:UpdatePositionLineEdits(x, y)
		end
	end)
	self.decreaseFontSizeButton = AceGUI:Create("EPButton")
	self.decreaseFontSizeButton:SetText("-")
	self.decreaseFontSizeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.decreaseFontSizeButton:SetWidth(24)
	self.decreaseFontSizeButton:SetHeight(24)
	self.decreaseFontSizeButton:SetCallback("Clicked", function()
		local font, size, flags = self.assignmentText:GetFont()
		if font then
			self.assignmentText:SetFont(font, math.max(10, size - 2), flags)
			self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
			local x, y = select(4, self.frame:GetPoint())
			self:UpdatePositionLineEdits(x, y)
		end
	end)

	local textAlignFontSizeContainer = AceGUI:Create("EPContainer")
	textAlignFontSizeContainer:SetLayout("EPVerticalLayout")
	textAlignFontSizeContainer:SetFullWidth(true)
	textAlignFontSizeContainer:SetSpacing(0, 0)

	local textAlignFontSizeLabelContainer = AceGUI:Create("EPContainer")
	textAlignFontSizeLabelContainer:SetLayout("EPHorizontalLayout")
	textAlignFontSizeLabelContainer:SetFullWidth(true)
	textAlignFontSizeLabelContainer:SetSpacing(5, 0)

	labelContainer:AddChildren(textAlignLabel, fontSizeLabel)
	textAlignContainer:AddChildren(
		leftTextAlignSpacer,
		self.alignLeftButton,
		self.alignCenterButton,
		self.alignRightButton,
		rightTextAlignSpacer
	)
	fontSizeContainer:AddChildren(
		leftFontSizeSpacer,
		self.decreaseFontSizeButton,
		self.increaseFontSizeButton,
		rightFontSizeSpacer
	)
	textAlignFontSizeContainer:AddChildren(textAlignContainer, fontSizeContainer)
	textAlignFontSizeLabelContainer:AddChildren(labelContainer, textAlignFontSizeContainer)

	local anchorContainer = AceGUI:Create("EPContainer")
	anchorContainer:SetLayout("EPVerticalLayout")
	anchorContainer:SetFullWidth(true)
	anchorContainer:SetSpacing(0, 0)

	local anchorDropdownLabel = AceGUI:Create("EPLabel")
	anchorDropdownLabel:SetText("Reminder Anchor Point", 0)
	anchorDropdownLabel:SetHeight(24)
	anchorDropdownLabel:SetWidth(anchorDropdownLabel.text:GetStringWidth())

	self.anchorDropdown = AceGUI:Create("EPDropdown")
	self.anchorDropdown:AddItems({
		{ itemValue = "TOPLEFT", text = "Top Left" },
		{ itemValue = "TOP", text = "Top" },
		{ itemValue = "TOPRIGHT", text = "Top Right" },
		{ itemValue = "RIGHT", text = "Right" },
		{ itemValue = "BOTTOMRIGHT", text = "Bottom Right" },
		{ itemValue = "BOTTOM", text = "Bottom" },
		{ itemValue = "LEFT", text = "Left" },
		{ itemValue = "BOTTOMLEFT", text = "Bottom Left" },
		{ itemValue = "CENTER", text = "Center" },
	}, "EPDropdownItemToggle")
	self.anchorDropdown:SetHeight(24)
	self.anchorDropdown:SetWidth(100)
	self.anchorDropdown:SetFullWidth(true)
	self.anchorDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:SetFrameAnchorPoint(value)
	end)

	anchorContainer:AddChildren(anchorDropdownLabel, self.anchorDropdown)

	local relativeAnchorContainer = AceGUI:Create("EPContainer")
	relativeAnchorContainer:SetLayout("EPVerticalLayout")
	relativeAnchorContainer:SetFullWidth(true)
	relativeAnchorContainer:SetSpacing(0, 0)

	local relativeAnchorDropdownLabel = AceGUI:Create("EPLabel")
	relativeAnchorDropdownLabel:SetText("Relative Anchor Frame Point:", 0)
	relativeAnchorDropdownLabel:SetHeight(24)
	relativeAnchorDropdownLabel:SetWidth(relativeAnchorDropdownLabel.text:GetStringWidth())

	self.relativeAnchorDropdown = AceGUI:Create("EPDropdown")
	self.relativeAnchorDropdown:AddItems({
		{ itemValue = "TOPLEFT", text = "Top Left" },
		{ itemValue = "TOP", text = "Top" },
		{ itemValue = "TOPRIGHT", text = "Top Right" },
		{ itemValue = "RIGHT", text = "Right" },
		{ itemValue = "BOTTOMRIGHT", text = "Bottom Right" },
		{ itemValue = "BOTTOM", text = "Bottom" },
		{ itemValue = "LEFT", text = "Left" },
		{ itemValue = "BOTTOMLEFT", text = "Bottom Left" },
		{ itemValue = "CENTER", text = "Center" },
	}, "EPDropdownItemToggle")
	self.relativeAnchorDropdown:SetHeight(24)
	self.relativeAnchorDropdown:SetWidth(100)
	self.relativeAnchorDropdown:SetFullWidth(true)
	self.relativeAnchorDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:SetRelativeFrameAnchorPoint(value)
	end)

	relativeAnchorContainer:AddChildren(relativeAnchorDropdownLabel, self.relativeAnchorDropdown)

	local anchorFrameContainer = AceGUI:Create("EPContainer")
	anchorFrameContainer:SetLayout("EPHorizontalLayout")
	anchorFrameContainer:SetFullWidth(true)
	anchorFrameContainer:SetSpacing(5, 0)

	local anchorFrameLabel = AceGUI:Create("EPLabel")
	anchorFrameLabel:SetText("Anchor Frame:", 0)
	anchorFrameLabel:SetHeight(24)
	anchorFrameLabel:SetWidth(anchorFrameLabel.text:GetStringWidth())

	self.anchorFrameNameLabel = AceGUI:Create("EPLabel")
	self.anchorFrameNameLabel:SetText("", 0)
	self.anchorFrameNameLabel:SetHeight(24)
	self.anchorFrameNameLabel:SetWidth(10)
	self.anchorFrameNameLabel:SetFullWidth(true)

	self.chooseAnchorFrameButton = AceGUI:Create("EPButton")
	self.chooseAnchorFrameButton:SetText("Choose Anchor Frame")
	self.chooseAnchorFrameButton:SetHeight(24)
	self.chooseAnchorFrameButton:SetWidthFromText()
	self.chooseAnchorFrameButton:SetFullWidth(true)
	self.chooseAnchorFrameButton:SetBackdropColor(0, 0, 0, 0.9)
	self.chooseAnchorFrameButton:SetCallback("Clicked", function()
		if isChoosingFrame then
			StopChoosingFrame(self.frameChooserFrame, self.frameChooserBox, nil)
			self.frameChooserFrame:Hide()
		else
			self.frameChooserFrame:Show()
			StartChoosingFrame(self.frameChooserFrame, self.frameChooserBox)
		end
	end)

	anchorFrameContainer:AddChildren(anchorFrameLabel, self.anchorFrameNameLabel)

	local xPositionContainer = AceGUI:Create("EPContainer")
	xPositionContainer:SetLayout("EPHorizontalLayout")
	xPositionContainer:SetFullWidth(true)
	xPositionContainer:SetSpacing(5, 0)
	local xPositionLabel = AceGUI:Create("EPLabel")
	xPositionLabel:SetText("X:", 0)
	xPositionLabel:SetHeight(24)
	xPositionLabel:SetWidth(xPositionLabel.text:GetStringWidth())
	self.xPositionLineEdit = AceGUI:Create("EPLineEdit")
	self.xPositionLineEdit:SetHeight(24)
	self.xPositionLineEdit:SetFullWidth(true)
	self.xPositionLineEdit:SetCallback("OnTextSubmitted", function(_, _, text)
		local numericValue = tonumber(text)
		if numericValue then
			local y = select(5, self.frame:GetPoint())
			self:SetFramePosition(numericValue, y)
		end
	end)
	xPositionContainer:AddChildren(xPositionLabel, self.xPositionLineEdit)

	local yPositionContainer = AceGUI:Create("EPContainer")
	yPositionContainer:SetLayout("EPHorizontalLayout")
	yPositionContainer:SetFullWidth(true)
	yPositionContainer:SetSpacing(5, 0)
	local yPositionLabel = AceGUI:Create("EPLabel")
	yPositionLabel:SetText("Y:", 0)
	yPositionLabel:SetHeight(24)
	yPositionLabel.frame:SetWidth(yPositionLabel.text:GetStringWidth())
	self.yPositionLineEdit = AceGUI:Create("EPLineEdit")
	self.yPositionLineEdit:SetHeight(24)
	self.yPositionLineEdit:SetFullWidth(true)
	self.yPositionLineEdit:SetCallback("OnTextSubmitted", function(_, _, text)
		local numericValue = tonumber(text)
		if numericValue then
			local x, _ = select(4, self.frame:GetPoint())
			self:SetFramePosition(x, numericValue)
		end
	end)
	yPositionContainer:AddChildren(yPositionLabel, self.yPositionLineEdit)

	self.simulateButton = AceGUI:Create("EPButton")
	self.simulateButton:SetText("Simulate")
	self.simulateButton:SetHeight(24)
	self.simulateButton:SetWidth(100)
	self.simulateButton:SetFullWidth(true)
	self.simulateButton:SetBackdropColor(0, 0, 0, 0.9)
	self.simulateButton:SetCallback("Clicked", function() end)

	self.container:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 10, -10)
	self.container:AddChildren(
		textAlignFontSizeLabelContainer,
		anchorContainer,
		anchorFrameContainer,
		self.chooseAnchorFrameButton,
		relativeAnchorContainer,
		xPositionContainer,
		yPositionContainer,
		self.simulateButton
	)

	self.container:DoLayout()
	self.container:DoLayout()

	self.optionsFrame:SetPoint("TOPLEFT", self.container.frame, "TOPLEFT", -10, 10)
	self.optionsFrame:SetPoint("BOTTOMRIGHT", self.container.frame, "BOTTOMRIGHT", 10, -10)
	self.optionsFrame:SetFrameLevel(self.container.frame:GetFrameLevel() - 1)
	self.optionsFrame:Show()

	self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
	self.frame:Show()
end

---@param self EPReminderAnchor
local function OnRelease(self)
	self.optionsFrame:ClearAllPoints()
	self.optionsFrame:Hide()
	if self.container then
		self.container:Release()
	end
	self.anchorFrameNameLabel = nil
	self.alignCenterButton = nil
	self.alignLeftButton = nil
	self.alignRightButton = nil
	self.increaseFontSizeButton = nil
	self.decreaseFontSizeButton = nil
	self.anchorDropdown = nil
	self.relativeAnchorDropdown = nil
	self.chooseAnchorFrameButton = nil
	self.xPositionLineEdit = nil
	self.yPositionLineEdit = nil
	self.simulateButton = nil
	self.preferences = nil
end

---@param self EPReminderAnchor
---@param text string
local function SetText(self, text)
	self.assignmentText:SetText(text)
end

---@param self EPReminderAnchor
---@param point "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"|nil
---@param relativeFrame Frame|ScriptRegion|nil
---@param relativePoint "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"|nil
local function ApplyPoint(self, point, relativeFrame, relativePoint)
	local p, rF, rP, _, _ = self.frame:GetPoint()
	point = point or p
	relativeFrame = relativeFrame or rF
	relativePoint = relativePoint or rP
	local x, y = calculateNewOffset(
		self.frame:GetLeft(),
		self.frame:GetTop(),
		self.frame:GetWidth(),
		self.frame:GetHeight(),
		point,
		relativeFrame:GetLeft(),
		relativeFrame:GetTop(),
		relativeFrame:GetWidth(),
		relativeFrame:GetHeight(),
		relativePoint
	)
	local relativeTo = relativeFrame:GetName()
	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, relativeTo, relativePoint, x, y)

	self.preferences.reminder.point = point
	self.preferences.reminder.relativeTo = relativeTo
	self.preferences.reminder.relativePoint = relativePoint
	self.preferences.reminder.x = x
	self.preferences.reminder.y = y

	self.anchorFrameNameLabel:SetText(relativeTo)
	self.anchorDropdown:SetValue(point)
	self.relativeAnchorDropdown:SetValue(relativePoint)
	self:UpdatePositionLineEdits(x, y)
end

---@param self EPReminderAnchor
---@param point "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"
local function SetFrameAnchorPoint(self, point)
	if point then
		self:ApplyPoint(point, nil, nil)
	end
end

---@param self EPReminderAnchor
---@param relativePoint "TOPLEFT"|"TOP"|"TOPRIGHT"|"RIGHT"|"BOTTOMRIGHT"|"BOTTOM"|"LEFT"|"BOTTOMLEFT"|"CENTER"
local function SetRelativeFrameAnchorPoint(self, relativePoint)
	if relativePoint then
		self:ApplyPoint(nil, nil, relativePoint)
	end
end

---@param self EPReminderAnchor
---@param x number|nil
---@param y number|nil
local function SetFramePosition(self, x, y)
	if type(x) == "number" and type(y) == "number" then
		local currentPoint, relativeTo, relativePoint, _, _ = self.frame:GetPoint()
		self.frame:SetPoint(currentPoint, relativeTo, relativePoint, x, y)
		self:UpdatePositionLineEdits(x, y)
	end
end

---@param self EPReminderAnchor
---@param frameName string
local function SetAnchorFrame(self, frameName)
	if frameName then
		if _G[frameName] and _G[frameName]:GetName() == frameName then
			self:ApplyPoint(nil, _G[frameName], nil)
		end
	end
end

---@param self EPReminderAnchor
---@param x number|nil
---@param y number|nil
local function UpdatePositionLineEdits(self, x, y)
	if type(x) == "number" and type(y) == "number" then
		self.xPositionLineEdit:SetText(format("%.2f", x))
		self.yPositionLineEdit:SetText(format("%.2f", y))
	end
end

---@param self EPReminderAnchor
---@param preferences EncounterPlannerPreferences
local function SetPreferences(self, preferences)
	self.preferences = preferences
	local relativeFrame = UIParent
	if _G[self.preferences.reminder.relativeTo] and _G[self.preferences.reminder.relativeTo]:GetName() then
		relativeFrame = _G[self.preferences.reminder.relativeTo]
	end
	self.frame:ClearAllPoints()
	self.frame:SetPoint(
		self.preferences.reminder.point,
		relativeFrame:GetName(),
		self.preferences.reminder.relativePoint,
		self.preferences.reminder.x,
		self.preferences.reminder.y
	)
	self:UpdatePositionLineEdits(self.preferences.reminder.x, self.preferences.reminder.y)
	self.anchorFrameNameLabel:SetText(relativeFrame:GetName())
	self.anchorDropdown:SetValue(self.preferences.reminder.point)
	self.relativeAnchorDropdown:SetValue(self.preferences.reminder.relativePoint)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.5)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.5)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetResizable(true)
	frame:SetResizeBounds(defaultFrameWidth, defaultFrameHeight, nil, nil)
	frame:EnableMouse(true)

	local optionsFrame = CreateFrame("Frame", Type .. "OptionsFrame" .. count, frame, "BackdropTemplate")
	optionsFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	optionsFrame:SetBackdrop(frameBackdrop)
	optionsFrame:SetBackdropColor(0, 0, 0, 0.75)
	optionsFrame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.75)
	optionsFrame:Hide()

	local textFrame = CreateFrame("Frame", "TextFrame", frame)
	textFrame:SetPoint("TOPLEFT", 2, -2)
	textFrame:SetPoint("BOTTOMRIGHT", 2, -2)

	local assignmentText = textFrame:CreateFontString(Type .. "Text", "OVERLAY", "GameFontNormalLarge")
	assignmentText:SetPoint("TOPLEFT")
	assignmentText:SetPoint("BOTTOMRIGHT")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		assignmentText:SetFont(fPath, 24)
	end
	assignmentText:SetJustifyH("CENTER")

	local frameChooserFrame = CreateFrame("Frame", nil, frame)
	frameChooserFrame:Hide()
	local frameChooserBox = CreateFrame("Frame", nil, frameChooserFrame, "BackdropTemplate")
	frameChooserBox:SetFrameStrata("TOOLTIP")
	frameChooserBox:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frameChooserBox:SetBackdropBorderColor(0, 1, 0)
	frameChooserBox:Hide()

	---@class EPReminderAnchor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		UpdatePositionLineEdits = UpdatePositionLineEdits,
		SetFrameAnchorPoint = SetFrameAnchorPoint,
		SetRelativeFrameAnchorPoint = SetRelativeFrameAnchorPoint,
		SetAnchorFrame = SetAnchorFrame,
		SetPreferences = SetPreferences,
		SetFramePosition = SetFramePosition,
		ApplyPoint = ApplyPoint,
		frame = frame,
		optionsFrame = optionsFrame,
		textFrame = textFrame,
		type = Type,
		assignmentText = assignmentText,
		frameChooserFrame = frameChooserFrame,
		frameChooserBox = frameChooserBox,
	}
	frameChooserFrame.obj = widget

	local previousPointDetails = {}
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			local point, relativeTo, relativePoint, _, _ = frame:GetPoint()
			previousPointDetails = {
				point = point,
				relativeTo = relativeTo,
				relativePoint = relativePoint,
			}
			frame:StartMoving()
		end
	end)

	frame:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" then
			frame:StopMovingOrSizing()
			local point = previousPointDetails.point
			local relativeFrame = previousPointDetails.relativeTo or UIParent
			local relativePoint = previousPointDetails.relativePoint
			widget:ApplyPoint(point, relativeFrame, relativePoint)
		end
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
