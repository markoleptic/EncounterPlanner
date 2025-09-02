local AddOnName, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPMainFrame"
local Version = 1
local addOnVersion = Private.version

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local format = string.format
local GetTime = GetTime
local IsControlKeyDown = IsControlKeyDown
local unpack = unpack

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 0.9 },
	BackdropColor = { 0, 0, 0, 0.9 },
	ButtonWidth = 200,
	CloseIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]],
	CollapseIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-collapse-64]],
	DefaultPadding = 10,
	DiscordIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-discord-new-48]],
	DiscordUrl = [[discord.gg/9bmH43JSzy]],
	EditBoxFrameBackdropBorderColor = { 0.15, 0.15, 0.15, 1.0 },
	EditBoxFrameBackdropColor = { 0, 0, 0, 1.0 },
	ExpandIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-expand-64]],
	FrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 27, bottom = 0 },
	},
	MainFrameHeight = 600,
	MainFrameWidth = 1200,
	MaximizeIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-maximize-button-32]],
	MinimizeIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-minus-32]],
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	StatusBarHeight = Private.constants.kStatusBarHeight,
	StatusBarPadding = Private.constants.kStatusBarPadding,
	ThrottleInterval = 0.015, -- Minimum time between executions, in seconds
	MinimizeFrameTitle = L["Encounter Planner"],
	TitleBarBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
	},
	TutorialIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-learning-30]],
	UserGuideIcon = [[Interface\AddOns\EncounterPlanner\Media\icons8-user-manual-32]],
	UserGuideUrl = [[github.com/markoleptic/EncounterPlanner/wiki/User-Guide]],
	WindowBarHeight = Private.constants.kMainFrameWindowBarHeight,
}

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

---@param self EPMainFrame
local function OnAcquire(self)
	self.padding =
		{ left = k.DefaultPadding, top = k.DefaultPadding, right = k.DefaultPadding, bottom = k.DefaultPadding }
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("DIALOG")
	self.frame:Show()

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle("")
	windowBar.frame:SetHeight(k.WindowBarHeight)
	local windowBarButtonSize = k.WindowBarHeight - 2 * k.FrameBackdrop.edgeSize
	windowBar.buttons[1]:SetWidth(windowBarButtonSize)
	windowBar.buttons[1]:SetHeight(windowBarButtonSize)
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
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, -(UIParent:GetHeight() - y))
	end)
	windowBar:AddButton(k.MinimizeIcon, "MinimizeButtonClicked")
	windowBar:SetCallback("Clicked", function()
		self:Minimize()
		self:Fire("MinimizeButtonClicked")
	end)
	self.windowBar = windowBar

	local edgeSize = k.FrameBackdrop.edgeSize
	local buttonSize = k.WindowBarHeight - 2 * edgeSize

	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.padding.left, -(k.WindowBarHeight + self.padding.top))
	self.content:SetPoint(
		"TOPRIGHT",
		self.frame,
		"TOPRIGHT",
		-self.padding.right,
		-(k.WindowBarHeight + self.padding.bottom)
	)

	local nameAndVersionContainer = AceGUI:Create("EPContainer")
	nameAndVersionContainer.frame:SetParent(self.windowBar.frame)
	nameAndVersionContainer.frame:SetPoint("CENTER", self.windowBar.frame, "CENTER")
	nameAndVersionContainer:SetLayout("EPHorizontalLayout")
	nameAndVersionContainer:SetSpacing(2, 0)

	local nameLabel = AceGUI:Create("EPLabel")
	nameLabel.text:SetTextColor(1, 0.82, 0, 1)
	nameLabel:SetText(L["Encounter Planner"], 0)
	nameLabel:SetFontSize(16)
	nameLabel:SetFrameWidthFromText()
	nameLabel:SetFrameHeightFromText(0)

	local versionButton = AceGUI:Create("EPButton")
	versionButton:SetText(addOnVersion)
	versionButton:SetFontSize(16)
	versionButton:SetWidthFromText(0)
	versionButton:SetColor(unpack(k.NeutralButtonColor))
	versionButton.button:GetFontString():SetTextColor(1, 0.82, 0, 1)
	versionButton:SetHeight(nameLabel.frame:GetHeight())
	versionButton:SetBackdropColor(0, 0, 0, 0)
	versionButton:SetCallback("Clicked", function()
		self:Fire("VersionButtonClicked")
	end)

	nameAndVersionContainer:AddChildren(nameLabel, versionButton)
	self.nameAndVersionContainer = nameAndVersionContainer

	self.collapseAllButton = AceGUI:Create("EPButton")
	self.collapseAllButton:SetIcon(k.CollapseIcon)
	self.collapseAllButton:SetIconPadding(2, 2)
	self.collapseAllButton:SetWidth(buttonSize)
	self.collapseAllButton:SetHeight(buttonSize)
	self.collapseAllButton:SetBackdropColor(unpack(k.BackdropColor))
	self.collapseAllButton:SetColor(unpack(k.NeutralButtonColor))
	self.collapseAllButton.frame:SetParent(self.frame)
	self.collapseAllButton:SetCallback("Clicked", function()
		self:Fire("CollapseAllButtonClicked")
	end)

	self.expandAllButton = AceGUI:Create("EPButton")
	self.expandAllButton:SetIcon(k.ExpandIcon)
	self.expandAllButton:SetIconPadding(2, 2)
	self.expandAllButton:SetWidth(buttonSize)
	self.expandAllButton:SetHeight(buttonSize)
	self.expandAllButton:SetBackdropColor(unpack(k.BackdropColor))
	self.expandAllButton:SetColor(unpack(k.NeutralButtonColor))
	self.expandAllButton.frame:SetParent(self.frame)
	self.expandAllButton:SetCallback("Clicked", function()
		self:Fire("ExpandAllButtonClicked")
	end)

	self.menuButtonContainer = AceGUI:Create("EPContainer")
	self.menuButtonContainer:SetLayout("EPHorizontalLayout")
	self.menuButtonContainer:SetSpacing(0, 0)
	self.menuButtonContainer.frame:SetParent(self.windowBar.frame)
	self.menuButtonContainer.frame:SetPoint("TOPLEFT", self.windowBar.frame, "TOPLEFT", 1, -1)
	self.menuButtonContainer.frame:SetPoint("BOTTOMLEFT", self.windowBar.frame, "BOTTOMLEFT", 1, 1)

	local buttonSpacing = 4
	local buttonHeight = (k.StatusBarHeight / 2.0) - buttonSpacing

	local clearLogButton = AceGUI:Create("EPButton")
	clearLogButton:SetText(format("|T%s:%d|t %s", k.CloseIcon, 0, L["Clear Status Bar"]))
	clearLogButton:SetWidth(k.ButtonWidth)
	clearLogButton:SetHeight(buttonHeight)
	clearLogButton:SetCallback("Clicked", function()
		Private.interfaceUpdater.ClearMessageLog()
	end)

	local tutorialButton = AceGUI:Create("EPButton")
	tutorialButton:SetText(format("|T%s:%d|t %s", k.TutorialIcon, 0, L["Tutorial"]))
	tutorialButton:SetWidthFromText(0)
	tutorialButton:SetHeight(buttonHeight)
	tutorialButton:SetColor(unpack(k.NeutralButtonColor))
	tutorialButton:SetCallback("Clicked", function()
		self:Fire("TutorialButtonClicked")
	end)
	self.tutorialButton = tutorialButton

	local userGuideButton = AceGUI:Create("EPButton")
	userGuideButton:SetText(format("|T%s:%d|t %s", k.UserGuideIcon, 0, L["User Guide"]))
	userGuideButton:SetWidthFromText(0)
	userGuideButton:SetHeight(buttonHeight)
	userGuideButton:SetColor(unpack(k.NeutralButtonColor))
	userGuideButton:SetCallback("Clicked", function()
		HandleButtonClicked(self, userGuideButton.frame, "BOTTOMLEFT", "TOPLEFT", k.UserGuideUrl)
	end)

	local discordButton = AceGUI:Create("EPButton")
	discordButton:SetText(format("|T%s:%d|t", k.DiscordIcon, 0))
	discordButton:SetWidthFromText(0)
	discordButton:SetHeight(buttonHeight)
	discordButton:SetColor(unpack(k.NeutralButtonColor))
	discordButton:SetCallback("Clicked", function()
		HandleButtonClicked(self, discordButton.frame, "BOTTOM", "TOP", k.DiscordUrl)
	end)

	local remainingWidthAvailable = k.ButtonWidth
		- tutorialButton.frame:GetWidth()
		- userGuideButton.frame:GetWidth()
		- discordButton.frame:GetWidth()
		- (2 * buttonSpacing)

	local additionalTextPadding = remainingWidthAvailable / 3.0
	tutorialButton:SetWidthFromText(additionalTextPadding)
	userGuideButton:SetWidthFromText(additionalTextPadding)
	discordButton:SetWidthFromText(additionalTextPadding)

	local userGuideAndDiscordContainer = AceGUI:Create("EPContainer")
	userGuideAndDiscordContainer:SetLayout("EPHorizontalLayout")
	userGuideAndDiscordContainer:SetSpacing(buttonSpacing, 0)
	userGuideAndDiscordContainer:SetFullWidth(true)
	userGuideAndDiscordContainer:AddChildren(tutorialButton, userGuideButton, discordButton)

	local lowerLeftContainer = AceGUI:Create("EPContainer")
	lowerLeftContainer:SetLayout("EPVerticalLayout")
	lowerLeftContainer:SetSpacing(0, buttonSpacing)
	lowerLeftContainer:AddChildren(clearLogButton, userGuideAndDiscordContainer)

	self.statusBar = AceGUI:Create("EPStatusBar")
	self.statusBar:SetHeight(k.StatusBarHeight)
	self.statusBar:SetFullWidth(true)

	self.lowerContainer = AceGUI:Create("EPContainer")
	self.lowerContainer:SetLayout("EPHorizontalLayout")
	self.lowerContainer:SetSpacing(self.padding.right, 0)
	self.lowerContainer.frame:SetParent(self.frame)
	self.lowerContainer.frame:SetPoint("LEFT", self.frame, "LEFT", self.padding.left, 0)
	self.lowerContainer.frame:SetPoint("RIGHT", self.frame, "RIGHT", -self.padding.right, 0)
	self.lowerContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, self.padding.bottom)
	self.lowerContainer:AddChildren(lowerLeftContainer, self.statusBar)

	local verticalOffset = k.StatusBarHeight + k.StatusBarPadding + self.padding.bottom
	self.collapseAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.padding.right, verticalOffset)
	local expandHorizontalOffset = self.padding.right + 2 + self.collapseAllButton.frame:GetWidth()
	self.expandAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", expandHorizontalOffset, verticalOffset)
end

---@param self EPMainFrame
local function OnRelease(self)
	if self.nameAndVersionContainer then
		local versionButton = self.nameAndVersionContainer.children[2]
		if versionButton then
			versionButton.button:GetFontString():SetTextColor(1, 1, 1, 1)
		end
		self.nameAndVersionContainer:Release()
	end

	if self.windowBar then
		self.windowBar:Release()
	end

	if self.minimizedWindowBar then
		self.minimizedWindowBar:Release()
	end

	if self.menuButtonContainer then
		self.menuButtonContainer:Release()
	end

	if self.collapseAllButton then
		self.collapseAllButton:Release()
	end

	if self.expandAllButton then
		self.expandAllButton:Release()
	end

	self.lowerContainer:Release()

	self.bossLabel = nil
	self.bossMenuButton = nil
	self.collapseAllButton = nil
	self.currentPlanWidget = nil
	self.difficultyLabel = nil
	self.expandAllButton = nil
	self.externalTextButton = nil
	self.instanceLabel = nil
	self.lowerContainer = nil
	self.menuButtonContainer = nil
	self.minimizedWindowBar = nil
	self.minimizedWindowBarFramePosition = nil
	self.nameAndVersionContainer = nil
	self.planDropdown = nil
	self.planMenuButton = nil
	self.planReminderEnableCheckBox = nil
	self.preferencesMenuButton = nil
	self.primaryPlanCheckBox = nil
	self.proposeChangesButton = nil
	self.rosterMenuButton = nil
	self.sendPlanButton = nil
	self.simulateRemindersButton = nil
	self.statusBar = nil
	self.timeline = nil
	self.tutorialButton = nil
	self.windowBar = nil
end

---@param self EPMainFrame
---@param _ number|nil
---@param height number|nil
local function LayoutFinished(self, _, height)
	if not self.frame.isResizing then
		if height then
			self:SetHeight(
				height
					+ self.windowBar.frame:GetHeight()
					+ self.padding.top
					+ self.padding.bottom
					+ self.lowerContainer.frame:GetHeight()
					+ k.StatusBarPadding
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
	self.padding.top = top
	self.padding.right = right
	self.padding.bottom = bottom
	self.padding.left = left

	local windowBarHeight = self.windowBar.frame:GetHeight()
	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.padding.left, -(windowBarHeight + self.padding.top))
	local verticalOffset = self.statusBar.frame:GetHeight() + k.StatusBarPadding + self.padding.bottom
	self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -self.padding.right, verticalOffset)
	self.collapseAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", self.padding.right, verticalOffset)
	local expandHorizontalOffset = self.padding.right + 2 + self.collapseAllButton.frame:GetWidth()
	self.expandAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", expandHorizontalOffset, verticalOffset)

	self.lowerContainer.frame:SetPoint("LEFT", self.frame, "LEFT", self.padding.left, 0)
	self.lowerContainer.frame:SetPoint("RIGHT", self.frame, "RIGHT", -self.padding.right, 0)
	self.lowerContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, self.padding.bottom)
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
		self.minimizedWindowBarFramePosition = { x = x, y = y }
		if self.minimizedWindowBar then
			self.minimizedWindowBar.frame:ClearAllPoints()
			self.minimizedWindowBar.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
		end
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
	minWidth = minWidth + self.padding.left + self.padding.right - topContainerSpacing.x
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

---@param self EPMainFrame
local function Maximize(self)
	if self.minimizedWindowBar then
		self.minimizedWindowBar:Release()
		self.minimizedWindowBar = nil
	end
	self.frame:Show()
end

---@param self EPMainFrame
local function Minimize(self)
	if not self.minimizedWindowBar then
		local minimizedWindowBar = AceGUI:Create("EPWindowBar")
		minimizedWindowBar.frame:SetParent(UIParent)
		minimizedWindowBar.frame:SetMovable(true)
		minimizedWindowBar.frame:SetClampedToScreen(true)
		minimizedWindowBar.frame:SetFrameStrata("DIALOG")
		minimizedWindowBar.frame:SetHeight(k.WindowBarHeight)
		local windowBarButtonSize = k.WindowBarHeight - 2 * k.FrameBackdrop.edgeSize
		minimizedWindowBar.buttons[1]:SetWidth(windowBarButtonSize)
		minimizedWindowBar.buttons[1]:SetHeight(windowBarButtonSize)
		minimizedWindowBar:SetPoint("TOP")
		minimizedWindowBar:SetTitle(k.MinimizeFrameTitle)
		minimizedWindowBar:SetCallback("OnMouseDown", function()
			self.minimizedWindowBar.frame:StartMoving()
		end)
		minimizedWindowBar:SetCallback("OnMouseUp", function()
			self.minimizedWindowBar.frame:StopMovingOrSizing()
			local x, y = self.minimizedWindowBar.frame:GetLeft(), self.minimizedWindowBar.frame:GetTop()
			self.minimizedWindowBar.frame:ClearAllPoints()
			local newX, newY = x, -(UIParent:GetHeight() - y)
			self.minimizedWindowBar.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, -(UIParent:GetHeight() - y))
			self:Fire("MinimizeFramePointChanged", newX, newY)
		end)
		minimizedWindowBar:SetCallback("CloseButtonClicked", function()
			self:Fire("CloseButtonClicked")
		end)
		minimizedWindowBar:AddButton(k.MaximizeIcon, "MaximizeButtonClicked")
		minimizedWindowBar:SetCallback("MaximizeButtonClicked", function()
			self:Maximize()
			self:Fire("MaximizeButtonClicked")
		end)
		local minimizeFrameButtonWidths = 2 * k.FrameBackdrop.edgeSize
		for _, button in ipairs(minimizedWindowBar.buttons) do
			minimizeFrameButtonWidths = minimizeFrameButtonWidths + button.frame:GetWidth()
		end
		minimizedWindowBar:SetWidth(
			2 * (minimizeFrameButtonWidths + (minimizedWindowBar.title:GetStringWidth() / 2.0) + self.padding.right)
		)
		if self.minimizedWindowBarFramePosition then
			minimizedWindowBar.frame:ClearAllPoints()
			minimizedWindowBar.frame:SetPoint(
				"TOPLEFT",
				UIParent,
				"TOPLEFT",
				self.minimizedWindowBarFramePosition.x,
				self.minimizedWindowBarFramePosition.y
			)
		end
		self.frame:Hide()
		self.minimizedWindowBar.frame:Show()
		self.minimizedWindowBar = minimizedWindowBar
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.MainFrameWidth, k.MainFrameHeight)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", k.DefaultPadding, -(k.WindowBarHeight + k.DefaultPadding))
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -k.DefaultPadding, k.DefaultPadding)

	local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	resizer:SetPoint("BOTTOMRIGHT", -1, 1)
	resizer:SetSize(16, 16)
	resizer:SetNormalTexture(Private.constants.resizer.kIcon)
	resizer:SetHighlightTexture(Private.constants.resizer.kIconHighlight)
	resizer:SetPushedTexture(Private.constants.resizer.kIconPushed)

	local editBoxFrame = CreateFrame("Frame", Type .. "EditBoxFrame" .. count, frame, "BackdropTemplate")
	editBoxFrame:SetFrameStrata("TOOLTIP")
	editBoxFrame:SetBackdrop(k.TitleBarBackdrop)
	editBoxFrame:SetBackdropColor(unpack(k.EditBoxFrameBackdropColor))
	editBoxFrame:SetBackdropBorderColor(unpack(k.EditBoxFrameBackdropBorderColor))
	editBoxFrame:EnableMouseMotion(true)

	local testFontString = editBoxFrame:CreateFontString(nil, "BACKGROUND")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
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

	---@class EPMainFrame : AceGUIContainer
	---@field bossLabel EPLabel
	---@field bossMenuButton EPDropdown
	---@field children table<integer, EPContainer>
	---@field collapseAllButton EPButton
	---@field currentPlanWidget EPContainer
	---@field difficultyLabel EPLabel
	---@field expandAllButton EPButton
	---@field externalTextButton EPButton
	---@field instanceLabel EPLabel
	---@field lowerContainer EPContainer
	---@field menuButtonContainer EPContainer
	---@field minimizedWindowBar EPWindowBar
	---@field minimizedWindowBarFramePosition {x:number, y:number}|nil
	---@field nameAndVersionContainer EPContainer
	---@field padding {left: number, top: number, right: number, bottom: number}
	---@field planDropdown EPDropdown
	---@field planMenuButton EPDropdown
	---@field planReminderEnableCheckBox EPCheckBox
	---@field preferencesMenuButton EPDropdown
	---@field primaryPlanCheckBox EPCheckBox
	---@field proposeChangesButton EPButton
	---@field rosterMenuButton EPDropdown
	---@field sendPlanButton EPButton
	---@field simulateRemindersButton EPButton
	---@field statusBar EPStatusBar
	---@field timeline EPTimeline
	---@field tutorialButton EPButton
	---@field windowBar EPWindowBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetPadding = SetPadding,
		SetSpacing = SetSpacing,
		SetMinimizeFramePosition = SetMinimizeFramePosition,
		HandleResizeBoundsCalculated = HandleResizeBoundsCalculated,
		UpdateHorizontalResizeBounds = UpdateHorizontalResizeBounds,
		Maximize = Maximize,
		Minimize = Minimize,
		frame = frame,
		type = Type,
		content = contentFrame,
		editBox = editBox,
		editBoxFrame = editBoxFrame,
		testFontString = testFontString,
		resizer = resizer,
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
				widget:Fire("Resized")
			end
		end
	end)

	local registered = AceGUI:RegisterAsContainer(widget)

	widget.frame:SetScript("OnSizeChanged", nil)
	widget.content:SetScript("OnSizeChanged", function()
		if widget.frame.isResizing then
			return
		end
		local currentTime = GetTime()
		if currentTime - lastExecutionTime < k.ThrottleInterval then
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
