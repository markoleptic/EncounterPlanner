local Type = "EPMainFrame"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local unpack = unpack

local mainFrameWidth = 1125
local mainFrameHeight = 600
local windowBarHeight = 30
local defaultPadding = 10
local padding = { top = 10, right = 10, bottom = 10, left = 10 }
local backdropColor = { 0, 0, 0, 0.9 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 0.9 }
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

---@class EPMainFrame : AceGUIContainer
---@field frame table|Frame
---@field type string
---@field content table|Frame
---@field windowBar table|Frame
---@field closeButton EPButton
---@field settingsButton EPButton
---@field collapseAllButton EPButton
---@field expandAllButton EPButton
---@field bossSelectDropdown EPDropdown
---@field bossAbilitySelectDropdown EPDropdown
---@field noteDropdown EPDropdown
---@field noteLineEdit EPLineEdit
---@field timeline EPTimeline
---@field planReminderEnableCheckBox EPCheckBox
---@field children table<integer, EPContainer>

---@param self EPMainFrame
local function OnAcquire(self)
	padding.top = defaultPadding
	padding.right = defaultPadding
	padding.bottom = defaultPadding
	padding.left = defaultPadding
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.frame:Show()

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding.left, -(windowBarHeight + padding.top))
	self.content:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -padding.right, -(windowBarHeight + padding.bottom))

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-96]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(backdropColor))
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.settingsButton = AceGUI:Create("EPButton")
	self.settingsButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-settings-96]])
	self.settingsButton:SetIconPadding(2, 2)
	self.settingsButton:SetWidth(buttonSize)
	self.settingsButton:SetHeight(buttonSize)
	self.settingsButton:SetBackdropColor(unpack(backdropColor))
	self.settingsButton.frame:SetParent(self.frame)
	self.settingsButton.frame:SetPoint("RIGHT", self.closeButton.frame, "LEFT", -edgeSize, 0)
	self.settingsButton:SetCallback("Clicked", function()
		self:Fire("SettingsButtonClicked")
	end)

	self.collapseAllButton = AceGUI:Create("EPButton")
	self.collapseAllButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-collapse-64]])
	self.collapseAllButton:SetIconPadding(2, 2)
	self.collapseAllButton:SetWidth(buttonSize)
	self.collapseAllButton:SetHeight(buttonSize)
	self.collapseAllButton:SetBackdropColor(unpack(backdropColor))
	self.collapseAllButton.frame:SetParent(self.frame)
	self.collapseAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", padding.right, padding.bottom)
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
	self.expandAllButton.frame:SetPoint("LEFT", self.collapseAllButton.frame, "RIGHT", edgeSize, 0)
	self.expandAllButton:SetCallback("Clicked", function()
		self:Fire("ExpandAllButtonClicked")
	end)
end

---@param self EPMainFrame
local function OnRelease(self)
	if self.closeButton then
		self.closeButton:Release()
	end
	if self.settingsButton then
		self.settingsButton:Release()
	end
	if self.collapseAllButton then
		self.collapseAllButton:Release()
	end
	if self.expandAllButton then
		self.expandAllButton:Release()
	end
	self.closeButton = nil
	self.settingsButton = nil
	self.collapseAllButton = nil
	self.expandAllButton = nil
	self.bossSelectDropdown = nil
	self.bossAbilitySelectDropdown = nil
	self.noteDropdown = nil
	self.noteLineEdit = nil
	self.timeline = nil
	self.planReminderEnableCheckBox = nil
end

---@param self EPMainFrame
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if not self.frame.isResizing then
		if height then
			self:SetHeight(height + windowBarHeight + padding.top + padding.bottom)
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
	self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -padding.right, padding.bottom)
	self.collapseAllButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", padding.right, padding.bottom)
	self.expandAllButton.frame:SetPoint(
		"BOTTOMLEFT",
		self.frame,
		"BOTTOMLEFT",
		padding.right + 2 + self.collapseAllButton.frame:GetWidth(),
		padding.bottom
	)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
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
	windowBarText:SetText("Encounter Planner")
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

	local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	resizer:SetPoint("BOTTOMRIGHT", -1, 1)
	resizer:SetSize(16, 16)
	resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	---@class EPMainFrame
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetPadding = SetPadding,
		frame = frame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
	}

	resizer:SetScript("OnMouseDown", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			if not frame.isResizing then
				AceGUI:ClearFocus()
				frame.isResizing = true
				frame:StartSizing("BOTTOMRIGHT")
				widget.timeline:SetFullHeight(true)
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
				widget.timeline:SetFullHeight(false)
				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", x, -(UIParent:GetHeight() - y))
				widget:DoLayout()
			end
		end
	end)

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
