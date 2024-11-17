local Type = "EPMainFrame"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame

local mainFrameWidth = 1125
local mainFrameHeight = 600
local windowBarHeight = 30
local contentFramePadding = { x = 10, y = 10 }
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
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame
---@field windowBar table|Frame
---@field closeButton EPButton
---@field children table<integer, AceGUIWidget>

---@param self EPMainFrame
local function OnAcquire(self)
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.frame:Show()

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetText("X")
	self.closeButton:SetWidth(windowBarHeight - 2 * frameBackdrop.edgeSize)
	self.closeButton:SetHeight(windowBarHeight - 2 * frameBackdrop.edgeSize)
	self.closeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton.frame:SetPoint(
		"TOPRIGHT",
		self.windowBar,
		"TOPRIGHT",
		-frameBackdrop.edgeSize,
		-frameBackdrop.edgeSize
	)
	self.closeButton:SetCallback("Clicked", function()
		self:Release()
	end)
end

---@param self EPMainFrame
local function OnRelease(self)
	if self.closeButton then
		self.closeButton:Release()
	end
	self.closeButton = nil
end

---@param self EPMainFrame
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	self.frame:SetHeight((height and height + windowBarHeight + (2 * contentFramePadding.y)) or 100)
end

---@param self EPMainFrame
---@return EPContainer|nil
local function GetAssignmentContainer(self)
	local bottomLeftContainer = self.children[2]
	if bottomLeftContainer then
		---@diagnostic disable-next-line: undefined-field
		local assignmentContainer = bottomLeftContainer.children[3]
		if assignmentContainer then
			return assignmentContainer
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPContainer|nil
local function GetBossAbilityContainer(self)
	local bottomLeftContainer = self.children[2]
	if bottomLeftContainer then
		---@diagnostic disable-next-line: undefined-field
		local bossAbilityContainer = bottomLeftContainer.children[1]
		if bossAbilityContainer then
			return bossAbilityContainer
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPDropdown|nil
local function GetAddAssigneeDropdown(self)
	local bottomLeftContainer = self.children[2]
	if bottomLeftContainer then
		---@diagnostic disable-next-line: undefined-field
		local assigneeDropdown = bottomLeftContainer.children[2]
		if assigneeDropdown then
			return assigneeDropdown
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPDropdown|nil
local function GetBossDropdown(self)
	local topContainer = self.children[1]
	if topContainer then
		---@diagnostic disable-next-line: undefined-field
		local bossContainer = topContainer.children[1]
		if bossContainer then
			---@diagnostic disable-next-line: undefined-field
			return bossContainer.children[3]
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPDropdown|nil
local function GetNoteDropdown(self)
	local topContainer = self.children[1]
	if topContainer then
		---@diagnostic disable-next-line: undefined-field
		local outerNoteContainer = topContainer.children[5]
		if outerNoteContainer then
			---@diagnostic disable-next-line: undefined-field
			local noteContainer = outerNoteContainer.children[1]
			if noteContainer then
				---@diagnostic disable-next-line: undefined-field
				return noteContainer.children[2]
			end
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPLineEdit|nil
local function GetNoteLineEdit(self)
	local topContainer = self.children[1]
	if topContainer then
		---@diagnostic disable-next-line: undefined-field
		local outerNoteContainer = topContainer.children[5]
		if outerNoteContainer then
			---@diagnostic disable-next-line: undefined-field
			local renameNoteContainer = outerNoteContainer.children[2]
			if renameNoteContainer then
				---@diagnostic disable-next-line: undefined-field
				return renameNoteContainer.children[2]
			end
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPTimeline|nil
local function GetTimeline(self)
	local timeline = self.children[3] --[[@as EPTimeline]]
	if timeline then
		return timeline
	end
	return nil
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local mainFrame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	mainFrame:EnableMouse(true)
	mainFrame:SetMovable(true)
	mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	mainFrame:SetBackdrop(frameBackdrop)
	mainFrame:SetBackdropColor(0, 0, 0, 0.9)
	mainFrame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	mainFrame:SetSize(mainFrameWidth, mainFrameHeight)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, mainFrame)
	contentFrame:SetPoint(
		"TOPLEFT",
		mainFrame,
		"TOPLEFT",
		contentFramePadding.x,
		-(windowBarHeight + contentFramePadding.y)
	)
	contentFrame:SetPoint(
		"TOPRIGHT",
		mainFrame,
		"TOPRIGHT",
		-contentFramePadding.x,
		-(windowBarHeight + contentFramePadding.y)
	)
	contentFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", contentFramePadding.x, contentFramePadding.y)
	contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -contentFramePadding.x, contentFramePadding.y)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, mainFrame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 0.9)
	windowBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
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
		mainFrame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		mainFrame:StopMovingOrSizing()
	end)

	---@class EPMainFrame
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		GetAssignmentContainer = GetAssignmentContainer,
		GetBossAbilityContainer = GetBossAbilityContainer,
		GetAddAssigneeDropdown = GetAddAssigneeDropdown,
		GetBossDropdown = GetBossDropdown,
		GetNoteDropdown = GetNoteDropdown,
		GetNoteLineEdit = GetNoteLineEdit,
		GetTimeline = GetTimeline,
		frame = mainFrame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
