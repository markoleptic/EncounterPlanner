local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPMainFrame"
local Version = 1
local addOnVersion = C_AddOns.GetAddOnMetadata(AddOnName, "Version")

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local mainFrameWidth = 1200
local mainFrameHeight = 600
local windowBarHeight = 30
local defaultPadding = 10
local statusBarHeight = 48
local statusBarPadding = 5
local buttonWidth = 200
local padding = { top = 10, right = 10, bottom = 10, left = 10 }
local backdropColor = { 0, 0, 0, 0.9 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
local editBoxFrameBackdropColor = { 0, 0, 0, 1.0 }
local editBoxFrameBackdropBorderColor = { 0.15, 0.15, 0.15, 1.0 }
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 27, bottom = 0 },
}
local titleBarBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
}
local closeIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]]
local discordIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-discord-24]]
local helpIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-help-32]]
local userGuideUrl = [[github.com/markoleptic/EncounterPlanner/wiki/User-Guide]]
local discordUrl = [[discord.gg/9bmH43JSzy]]
local throttleInterval = 0.015 -- Minimum time between executions, in seconds
local lastExecutionTime = 0

---@param self EPMainFrame
---@param buttonFrame Frame
---@param point "BOTTOM"|"BOTTOMLEFT"
---@param relativePoint "TOP"|"TOPLEFT"
---@param text string
local function HandleButtonClicked(self, buttonFrame, point, relativePoint, text)
	self.editBoxFrame:SetPoint(point, buttonFrame, relativePoint, 0, 2)
	self.editBox:SetText(text)
	self.testFontString:SetText(text)
	self.editBoxFrame:SetSize(
		self.testFontString:GetUnboundedStringWidth() + 20,
		self.testFontString:GetStringHeight() + 20
	)
	self.editBoxFrame:Show()
	self.editBox:SetFocus()
	self.editBox:HighlightText(0, self.editBox:GetText():len())
end

---@class EPMainFrame : AceGUIContainer
---@field frame table|Frame
---@field type string
---@field content table|Frame
---@field windowBar table|Frame
---@field closeButton EPButton
---@field minimizeButton EPButton
---@field maximizeButton EPButton
---@field closeButtonMinimizeFrame EPButton
---@field collapseAllButton EPButton
---@field expandAllButton EPButton
---@field simulateRemindersButton EPButton
---@field lowerContainer EPContainer
---@field statusBar EPStatusBar
---@field instanceLabel EPLabel
---@field bossLabel EPLabel
---@field bossMenuButton EPDropdown
---@field planDropdown EPDropdown
---@field timeline EPTimeline
---@field planReminderEnableCheckBox EPCheckBox
---@field sendPlanButton EPButton
---@field primaryPlanCheckBox EPCheckBox
---@field menuButtonContainer EPContainer
---@field children table<integer, EPContainer>

---@param self EPMainFrame
local function OnAcquire(self)
	padding.top = defaultPadding
	padding.right = defaultPadding
	padding.bottom = defaultPadding
	padding.left = defaultPadding
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("DIALOG")
	self.frame:Show()

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding.left, -(windowBarHeight + padding.top))
	self.content:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -padding.right, -(windowBarHeight + padding.bottom))

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(backdropColor))
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.minimizeButton = AceGUI:Create("EPButton")
	self.minimizeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-minus-32]])
	self.minimizeButton:SetIconPadding(2, 2)
	self.minimizeButton:SetWidth(buttonSize)
	self.minimizeButton:SetHeight(buttonSize)
	self.minimizeButton:SetBackdropColor(unpack(backdropColor))
	self.minimizeButton.frame:SetParent(self.windowBar)
	self.minimizeButton.frame:SetPoint("RIGHT", self.closeButton.frame, "LEFT")
	self.minimizeButton:SetCallback("Clicked", function()
		self.frame:Hide()
		self.minimizeFrame:Show()
		self:Fire("MinimizeButtonClicked")
	end)

	self.closeButtonMinimizeFrame = AceGUI:Create("EPButton")
	self.closeButtonMinimizeFrame:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButtonMinimizeFrame:SetIconPadding(2, 2)
	self.closeButtonMinimizeFrame:SetWidth(buttonSize)
	self.closeButtonMinimizeFrame:SetHeight(buttonSize)
	self.closeButtonMinimizeFrame:SetBackdropColor(unpack(backdropColor))
	self.closeButtonMinimizeFrame.frame:SetParent(self.minimizeFrame --[[@as Frame]])
	self.closeButtonMinimizeFrame.frame:SetPoint("RIGHT", self.minimizeFrame, "RIGHT", -edgeSize, 0)
	self.closeButtonMinimizeFrame:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.maximizeButton = AceGUI:Create("EPButton")
	self.maximizeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-maximize-button-32]])
	self.maximizeButton:SetIconPadding(2, 2)
	self.maximizeButton:SetWidth(buttonSize)
	self.maximizeButton:SetHeight(buttonSize)
	self.maximizeButton:SetBackdropColor(unpack(backdropColor))
	self.maximizeButton.frame:SetParent(self.minimizeFrame --[[@as Frame]])
	self.maximizeButton.frame:SetPoint("RIGHT", self.closeButtonMinimizeFrame.frame, "LEFT", -edgeSize, 0)
	self.maximizeButton:SetCallback("Clicked", function()
		self.minimizeFrame:Hide()
		self.frame:Show()
	end)

	local minimizeFrameButtonWidths = self.maximizeButton.frame:GetWidth()
		+ self.closeButtonMinimizeFrame.frame:GetWidth()
		+ 2 * edgeSize
	self.minimizeFrame:SetWidth(
		2 * (minimizeFrameButtonWidths + (self.minimizeFrameText:GetStringWidth() / 2.0) + padding.right)
	)

	self.collapseAllButton = AceGUI:Create("EPButton")
	self.collapseAllButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-collapse-64]])
	self.collapseAllButton:SetIconPadding(2, 2)
	self.collapseAllButton:SetWidth(buttonSize)
	self.collapseAllButton:SetHeight(buttonSize)
	self.collapseAllButton:SetBackdropColor(unpack(backdropColor))
	self.collapseAllButton.frame:SetParent(self.frame)
	self.collapseAllButton:SetCallback("Clicked", function()
		self:Fire("CollapseAllButtonClicked")
	end)

	self.expandAllButton = AceGUI:Create("EPButton")
	self.expandAllButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-expand-64]])
	self.expandAllButton:SetIconPadding(2, 2)
	self.expandAllButton:SetWidth(buttonSize)
	self.expandAllButton:SetHeight(buttonSize)
	self.expandAllButton:SetBackdropColor(unpack(backdropColor))
	self.expandAllButton.frame:SetParent(self.frame)
	self.expandAllButton:SetCallback("Clicked", function()
		self:Fire("ExpandAllButtonClicked")
	end)

	self.menuButtonContainer = AceGUI:Create("EPContainer")
	self.menuButtonContainer:SetLayout("EPHorizontalLayout")
	self.menuButtonContainer:SetSpacing(0, 0)
	self.menuButtonContainer.frame:SetParent(self.windowBar)
	self.menuButtonContainer.frame:SetPoint("TOPLEFT", self.windowBar, "TOPLEFT", 1, -1)
	self.menuButtonContainer.frame:SetPoint("BOTTOMLEFT", self.windowBar, "BOTTOMLEFT", 1, 1)

	local buttonSpacing = 4
	local buttonHeight = (statusBarHeight - buttonSpacing) / 2.0
	local halfButtonWidth = (buttonWidth - buttonSpacing) / 2.0

	local clearLogButton = AceGUI:Create("EPButton")
	clearLogButton:SetText(format("|T%s:%d|t %s", closeIcon, 0, L["Clear Status Bar"]))
	clearLogButton:SetWidth(buttonWidth)
	clearLogButton:SetHeight(buttonHeight)
	clearLogButton:SetCallback("Clicked", function()
		Private.interfaceUpdater.ClearMessageLog()
	end)

	local userGuideButton = AceGUI:Create("EPButton")
	userGuideButton:SetText(format("|T%s:%d|t %s", helpIcon, 0, L["User Guide"]))
	userGuideButton:SetWidth(halfButtonWidth)
	userGuideButton:SetHeight(buttonHeight)
	userGuideButton:SetCallback("Clicked", function()
		HandleButtonClicked(self, userGuideButton.frame, "BOTTOMLEFT", "TOPLEFT", userGuideUrl)
	end)

	local discordButton = AceGUI:Create("EPButton")
	discordButton:SetText(format("|T%s:%d|t %s", discordIcon, 0, L["Discord"]))
	discordButton:SetWidth(halfButtonWidth)
	discordButton:SetHeight(buttonHeight)
	discordButton:SetCallback("Clicked", function()
		HandleButtonClicked(self, discordButton.frame, "BOTTOM", "TOP", discordUrl)
	end)

	local userGuideAndDiscordContainer = AceGUI:Create("EPContainer")
	userGuideAndDiscordContainer:SetLayout("EPHorizontalLayout")
	userGuideAndDiscordContainer:SetSpacing(buttonSpacing, 0)
	userGuideAndDiscordContainer:SetFullWidth(true)
	userGuideAndDiscordContainer:AddChildren(userGuideButton, discordButton)

	local lowerLeftContainer = AceGUI:Create("EPContainer")
	lowerLeftContainer:SetLayout("EPVerticalLayout")
	lowerLeftContainer:SetSpacing(0, buttonSpacing)
	lowerLeftContainer:AddChildren(clearLogButton, userGuideAndDiscordContainer)

	self.statusBar = AceGUI:Create("EPStatusBar")
	self.statusBar:SetHeight(statusBarHeight)
	self.statusBar:SetFullWidth(true)

	self.lowerContainer = AceGUI:Create("EPContainer")
	self.lowerContainer:SetLayout("EPHorizontalLayout")
	self.lowerContainer:SetSpacing(padding.right, 0)
	self.lowerContainer.frame:SetParent(self.frame)
	self.lowerContainer.frame:SetPoint("LEFT", self.frame, "LEFT", padding.left, 0)
	self.lowerContainer.frame:SetPoint("RIGHT", self.frame, "RIGHT", -padding.right, 0)
	self.lowerContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, padding.bottom)
	self.lowerContainer:AddChildren(lowerLeftContainer, self.statusBar)

	local verticalOffset = statusBarHeight + statusBarPadding + padding.bottom
	self.collapseAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", padding.right, verticalOffset)
	local expandHorizontalOffset = padding.right + 2 + self.collapseAllButton.frame:GetWidth()
	self.expandAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", expandHorizontalOffset, verticalOffset)
end

---@param self EPMainFrame
local function OnRelease(self)
	if self.menuButtonContainer then
		self.menuButtonContainer:Release()
	end
	self.menuButtonContainer = nil

	if self.closeButton then
		self.closeButton:Release()
	end
	self.closeButton = nil

	if self.minimizeButton then
		self.minimizeButton:Release()
	end
	self.minimizeButton = nil

	if self.maximizeButton then
		self.maximizeButton:Release()
	end
	self.maximizeButton = nil
	if self.closeButtonMinimizeFrame then
		self.closeButtonMinimizeFrame:Release()
	end
	self.closeButtonMinimizeFrame = nil
	if self.collapseAllButton then
		self.collapseAllButton:Release()
	end
	self.collapseAllButton = nil
	if self.expandAllButton then
		self.expandAllButton:Release()
	end
	self.expandAllButton = nil

	self.lowerContainer:Release()
	self.lowerContainer = nil
	self.statusBar = nil

	self.minimizeFrame:Hide()

	self.instanceLabel = nil
	self.bossLabel = nil
	self.bossMenuButton = nil
	self.planDropdown = nil
	self.timeline = nil
	self.planReminderEnableCheckBox = nil
	self.sendPlanButton = nil
	self.primaryPlanCheckBox = nil
	self.simulateRemindersButton = nil
end

---@param self EPMainFrame
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if not self.frame.isResizing then
		if height then
			self:SetHeight(
				height
					+ windowBarHeight
					+ padding.top
					+ padding.bottom
					+ self.lowerContainer.frame:GetHeight()
					+ statusBarPadding
			)
		end
	end
end

---@param self EPMainFrame
---@param top number
---@param right number
---@param bottom number
---@param left number
local function SetPadding(self, top, right, bottom, left)
	padding.top = top
	padding.right = right
	padding.bottom = bottom
	padding.left = left

	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding.left, -(windowBarHeight + padding.top))
	local verticalOffset = self.statusBar.frame:GetHeight() + statusBarPadding + padding.bottom
	self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -padding.right, verticalOffset)
	self.collapseAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", padding.right, verticalOffset)
	local expandHorizontalOffset = padding.right + 2 + self.collapseAllButton.frame:GetWidth()
	self.expandAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", expandHorizontalOffset, verticalOffset)
end

---@param self EPMainFrame
---@param horizontal number
---@param vertical number
local function SetSpacing(self, horizontal, vertical)
	self.content.spacing = { x = horizontal, y = vertical }
end

---@param self EPMainFrame
---@param x number
---@param y number
local function SetMinimizeFramePosition(self, x, y)
	if type(x) == "number" and type(y) == "number" then
		self.minimizeFrame:ClearAllPoints()
		self.minimizeFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
	end
end

---@param self EPMainFrame
---@return number
local function CalculateMinWidth(self)
	local topContainer = self.children[1]
	topContainer:DoLayout()
	local topContainerSpacing = topContainer.content.spacing
	local minWidth = 0.0
	for _, child in ipairs(topContainer.children) do
		if child.type ~= "EPSpacer" then
			minWidth = minWidth + child.frame:GetWidth() + topContainerSpacing.x
		end
	end
	minWidth = minWidth + padding.left + padding.right - topContainerSpacing.x
	minWidth = minWidth + topContainer.padding.left + topContainer.padding.right
	return minWidth
end

---@param self EPMainFrame
---@param timelineFrameHeight number
---@param minHeight number
---@param maxHeight number
local function HandleResizeBoundsCalculated(self, timelineFrameHeight, minHeight, maxHeight)
	local heightDiff = self.frame:GetHeight() - timelineFrameHeight
	local minWidth = CalculateMinWidth(self)
	minHeight = minHeight + heightDiff
	maxHeight = maxHeight + heightDiff
	self.frame:SetResizeBounds(minWidth, minHeight, nil, maxHeight)
	if self.frame:GetWidth() < minWidth then
		self:SetWidth(minWidth)
	end
	if self.frame:GetHeight() < minHeight then
		self:SetHeight(minHeight)
	end
end

---@param self EPMainFrame
local function UpdateHorizontalResizeBounds(self)
	local minWidth = CalculateMinWidth(self)
	local _, minHeight, maxWidth, maxHeight = self.frame:GetResizeBounds()
	self.frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
	if self.frame:GetWidth() < minWidth then
		self:SetWidth(minWidth)
	end
end

---@return {left:number, top:number, right:number, bottom:number}
local function GetPadding()
	return padding
end

---@param self EPMainFrame
local function Maximize(self)
	self.minimizeFrame:Hide()
	self.frame:Show()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(mainFrameWidth, mainFrameHeight)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", padding.left, -(windowBarHeight + padding.top))
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding.right, padding.bottom)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)
	local windowBarText = windowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(L["Encounter Planner"] .. " " .. addOnVersion)
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
		local x, y = frame:GetLeft(), frame:GetTop()
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, -(UIParent:GetHeight() - y))
	end)

	local minimizeFrame = CreateFrame("Frame", Type .. "MinimizeFrame" .. count, UIParent, "BackdropTemplate")
	minimizeFrame:SetMovable(true)
	minimizeFrame:SetResizable(true)
	minimizeFrame:SetFrameStrata("DIALOG")
	minimizeFrame:SetHeight(windowBarHeight)
	minimizeFrame:SetPoint("TOP")
	minimizeFrame:SetBackdrop(titleBarBackdrop)
	minimizeFrame:SetBackdropColor(unpack(backdropColor))
	minimizeFrame:SetBackdropBorderColor(unpack(backdropBorderColor))
	minimizeFrame:EnableMouse(true)
	minimizeFrame:SetClampedToScreen(true)
	local minimizeFrameText = minimizeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	minimizeFrameText:SetText(L["Encounter Planner"])
	minimizeFrameText:SetPoint("CENTER", minimizeFrame, "CENTER")
	if fPath then
		minimizeFrameText:SetFont(fPath, h)
	end
	minimizeFrame:Hide()

	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		local x, y = frame:GetLeft(), frame:GetTop()
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, -(UIParent:GetHeight() - y))
	end)

	local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	resizer:SetPoint("BOTTOMRIGHT", -1, 1)
	resizer:SetSize(16, 16)
	resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	local editBoxFrame = CreateFrame("Frame", Type .. "EditBoxFrame" .. count, frame, "BackdropTemplate")
	editBoxFrame:SetFrameStrata("TOOLTIP")
	editBoxFrame:SetBackdrop(titleBarBackdrop)
	editBoxFrame:SetBackdropColor(unpack(editBoxFrameBackdropColor))
	editBoxFrame:SetBackdropBorderColor(unpack(editBoxFrameBackdropBorderColor))
	editBoxFrame:EnableMouseMotion(true)

	local testFontString = editBoxFrame:CreateFontString(nil, "BACKGROUND")
	if fPath then
		testFontString:SetFont(fPath, 12)
	end

	local editBox = CreateFrame("EditBox", Type .. "EditBox" .. count, editBoxFrame)
	editBox:SetPoint("TOPLEFT")
	editBox:SetPoint("BOTTOMRIGHT")
	editBox:SetAutoFocus(false)
	editBox:EnableKeyboard(true)
	editBox:SetMultiLine(false)
	editBox:SetJustifyH("CENTER")
	editBox:SetJustifyV("MIDDLE")
	if fPath then
		editBox:SetFont(fPath, 12, "")
	end

	editBoxFrame:Hide()

	local function HideEditBoxAndClearFocus()
		editBox:ClearFocus()
		editBoxFrame:ClearAllPoints()
		editBoxFrame:Hide()
	end

	editBox:SetScript("OnKeyDown", function(_, key)
		if key == "ESCAPE" or (key == "C" and IsControlKeyDown()) then
			HideEditBoxAndClearFocus()
		end
	end)
	editBox:SetScript("OnEditFocusLost", HideEditBoxAndClearFocus)
	editBoxFrame:SetScript("OnLeave", HideEditBoxAndClearFocus)

	---@class EPMainFrame
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetPadding = SetPadding,
		SetSpacing = SetSpacing,
		SetMinimizeFramePosition = SetMinimizeFramePosition,
		GetPadding = GetPadding,
		HandleResizeBoundsCalculated = HandleResizeBoundsCalculated,
		UpdateHorizontalResizeBounds = UpdateHorizontalResizeBounds,
		Maximize = Maximize,
		frame = frame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
		minimizeFrame = minimizeFrame,
		minimizeFrameText = minimizeFrameText,
		editBox = editBox,
		editBoxFrame = editBoxFrame,
		userGuideStringLength = 0,
		discordStringLength = 0,
		testFontString = testFontString,
	}

	resizer:SetScript("OnMouseDown", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			if not frame.isResizing then
				AceGUI:ClearFocus()
				frame.isResizing = true
				frame:StartSizing("BOTTOMRIGHT")
				widget.timeline.frame:SetPoint("BOTTOMRIGHT", widget.content, "BOTTOMRIGHT")
				widget.timeline:SetAllowHeightResizing(true)
			end
		end
	end)

	resizer:SetScript("OnMouseUp", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			if frame.isResizing == true then
				frame.isResizing = nil
				local x, y = frame:GetLeft(), frame:GetTop()
				frame:StopMovingOrSizing()
				widget.timeline:SetAllowHeightResizing(false)
				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
				widget:DoLayout()
			end
		end
	end)

	minimizeFrame:SetScript("OnMouseDown", function()
		minimizeFrame:StartMoving()
	end)
	minimizeFrame:SetScript("OnMouseUp", function()
		minimizeFrame:StopMovingOrSizing()
		local x, y = minimizeFrame:GetLeft(), minimizeFrame:GetTop()
		minimizeFrame:ClearAllPoints()
		local newX, newY = x, -(UIParent:GetHeight() - y)
		minimizeFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, -(UIParent:GetHeight() - y))
		widget:Fire("MinimizeFramePointChanged", newX, newY)
	end)

	local registered = AceGUI:RegisterAsContainer(widget)

	widget.frame:SetScript("OnSizeChanged", nil)
	widget.content:SetScript("OnSizeChanged", function()
		if widget.frame.isResizing then
			return
		end
		local currentTime = GetTime()
		if currentTime - lastExecutionTime < throttleInterval then
			return
		end
		lastExecutionTime = currentTime
		if widget.DoLayout then
			widget:DoLayout()
		end
	end)

	return registered
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
