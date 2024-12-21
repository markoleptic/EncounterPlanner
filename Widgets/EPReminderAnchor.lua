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
---@field alignCenterButton EPButton
---@field alignLeftButton EPButton
---@field alignRightButton EPButton
---@field increaseFontSizeButton EPButton
---@field decreaseFontSizeButton EPButton
---@field chooseAnchorFrameButton EPButton
---@field simulateButton EPButton
---@field anchorDropdown EPDropdown
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

	self.alignLeftButton = AceGUI:Create("EPButton")
	self.alignLeftButton.frame:SetParent(self.frame)
	self.alignLeftButton.frame:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT")
	self.alignLeftButton:SetText("Align Left")
	self.alignLeftButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignLeftButton:SetHeight(20)
	self.alignLeftButton:SetWidthFromText()
	self.alignLeftButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("LEFT")
	end)

	self.alignCenterButton = AceGUI:Create("EPButton")
	self.alignCenterButton.frame:SetParent(self.frame)
	self.alignCenterButton.frame:SetPoint("LEFT", self.alignLeftButton.frame, "RIGHT")
	self.alignCenterButton:SetText("Align Center")
	self.alignCenterButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignCenterButton:SetHeight(20)
	self.alignCenterButton:SetWidthFromText()
	self.alignCenterButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("CENTER")
	end)

	self.alignRightButton = AceGUI:Create("EPButton")
	self.alignRightButton.frame:SetParent(self.frame)
	self.alignRightButton.frame:SetPoint("LEFT", self.alignCenterButton.frame, "RIGHT")
	self.alignRightButton:SetText("Align Right")
	self.alignRightButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignRightButton:SetHeight(20)
	self.alignRightButton:SetWidthFromText()
	self.alignRightButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("RIGHT")
	end)

	self.increaseFontSizeButton = AceGUI:Create("EPButton")
	self.increaseFontSizeButton.frame:SetParent(self.frame)
	self.increaseFontSizeButton.frame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT")
	self.increaseFontSizeButton.frame:SetPoint("BOTTOMLEFT", self.frame, "RIGHT")
	self.increaseFontSizeButton:SetText("+")
	self.increaseFontSizeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.increaseFontSizeButton:SetWidth(self.frame:GetHeight() / 2.0)
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
	self.decreaseFontSizeButton.frame:SetParent(self.frame)
	self.decreaseFontSizeButton.frame:SetPoint("TOPRIGHT", self.increaseFontSizeButton.frame, "BOTTOMRIGHT")
	self.decreaseFontSizeButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT")
	self.decreaseFontSizeButton:SetText("-")
	self.decreaseFontSizeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.decreaseFontSizeButton:SetCallback("Clicked", function()
		local font, size, flags = self.assignmentText:GetFont()
		if font then
			self.assignmentText:SetFont(font, math.max(10, size - 2), flags)
			self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
			local x, y = select(4, self.frame:GetPoint())
			self:UpdatePositionLineEdits(x, y)
		end
	end)

	self.anchorDropdown = AceGUI:Create("EPDropdown")
	self.anchorDropdown.frame:SetParent(self.frame)
	self.anchorDropdown.frame:SetPoint("LEFT", self.alignRightButton.frame, "RIGHT")
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
	self.anchorDropdown:SetHeight(20)
	self.anchorDropdown:SetWidth(100)
	self.anchorDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:SetFrameAnchorPoint(value)
	end)

	self.relativeAnchorDropdown = AceGUI:Create("EPDropdown")
	self.relativeAnchorDropdown.frame:SetParent(self.frame)
	self.relativeAnchorDropdown.frame:SetPoint("LEFT", self.anchorDropdown.frame, "RIGHT")
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
	self.relativeAnchorDropdown:SetHeight(20)
	self.relativeAnchorDropdown:SetWidth(100)
	self.relativeAnchorDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:SetRelativeFrameAnchorPoint(value)
	end)

	self.chooseAnchorFrameButton = AceGUI:Create("EPButton")
	self.chooseAnchorFrameButton.frame:SetParent(self.frame)
	self.chooseAnchorFrameButton.frame:SetPoint("LEFT", self.relativeAnchorDropdown.frame, "RIGHT")
	self.chooseAnchorFrameButton:SetText("Choose Anchor Frame")
	self.chooseAnchorFrameButton:SetHeight(20)
	self.chooseAnchorFrameButton:SetWidthFromText()
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

	self.xPositionLineEdit = AceGUI:Create("EPLineEdit")
	self.xPositionLineEdit.frame:SetParent(self.frame)
	self.xPositionLineEdit.frame:SetPoint("LEFT", self.chooseAnchorFrameButton.frame, "RIGHT")
	self.xPositionLineEdit:SetHeight(20)
	self.xPositionLineEdit:SetWidth(50)
	self.xPositionLineEdit:SetCallback("OnTextSubmitted", function(_, _, text)
		local numericValue = tonumber(text)
		if numericValue then
			local y = select(5, self.frame:GetPoint())
			self:SetFramePosition(numericValue, y)
		end
	end)

	self.yPositionLineEdit = AceGUI:Create("EPLineEdit")
	self.yPositionLineEdit.frame:SetParent(self.frame)
	self.yPositionLineEdit.frame:SetPoint("LEFT", self.xPositionLineEdit.frame, "RIGHT")
	self.yPositionLineEdit:SetHeight(20)
	self.yPositionLineEdit:SetWidth(50)
	self.yPositionLineEdit:SetCallback("OnTextSubmitted", function(_, _, text)
		local numericValue = tonumber(text)
		if numericValue then
			local x, _ = select(4, self.frame:GetPoint())
			self:SetFramePosition(x, numericValue)
		end
	end)

	self.simulateButton = AceGUI:Create("EPButton")
	self.simulateButton.frame:SetParent(self.frame)
	self.simulateButton.frame:SetPoint("LEFT", self.yPositionLineEdit.frame, "RIGHT")
	self.simulateButton:SetText("Simulate")
	self.simulateButton:SetHeight(20)
	self.simulateButton:SetWidthFromText()
	self.simulateButton:SetBackdropColor(0, 0, 0, 0.9)
	self.simulateButton:SetCallback("Clicked", function() end)

	self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
	self.frame:Show()
end

---@param self EPReminderAnchor
local function OnRelease(self)
	if self.alignCenterButton then
		self.alignCenterButton:Release()
	end
	if self.alignLeftButton then
		self.alignLeftButton:Release()
	end
	if self.alignRightButton then
		self.alignRightButton:Release()
	end
	if self.increaseFontSizeButton then
		self.increaseFontSizeButton:Release()
	end
	if self.decreaseFontSizeButton then
		self.decreaseFontSizeButton:Release()
	end
	if self.anchorDropdown then
		self.anchorDropdown:Release()
	end
	if self.relativeAnchorDropdown then
		self.relativeAnchorDropdown:Release()
	end
	if self.chooseAnchorFrameButton then
		self.chooseAnchorFrameButton:Release()
	end
	if self.xPositionLineEdit then
		self.xPositionLineEdit:Release()
	end
	if self.yPositionLineEdit then
		self.yPositionLineEdit:Release()
	end
	if self.simulateButton then
		self.simulateButton:Release()
	end
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
	self.frame:ClearAllPoints()
	self.frame:SetPoint(point, relativeFrame:GetName(), relativePoint, x, y)
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
