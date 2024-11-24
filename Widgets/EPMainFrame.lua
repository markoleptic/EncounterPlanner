local Type = "EPMainFrame"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame

local mainFrameWidth = 1125
local mainFrameHeight = 600
local windowBarHeight = 30
local defaultPadding = 10
local padding = { top = 10, right = 10, bottom = 10, left = 10 }
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
---@field children table<integer, EPWidgetType|EPContainerType>
---@field anchorLastChild boolean

---@param self EPMainFrame
local function OnAcquire(self)
	padding.top = defaultPadding
	padding.right = defaultPadding
	padding.bottom = defaultPadding
	padding.left = defaultPadding
	self.anchorLastChild = true
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.frame:Show()

	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding.left, -(windowBarHeight + padding.top))
	self.content:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -padding.right, -(windowBarHeight + padding.bottom))

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

local function OnHeightSet(self, height) end

local function OnWidthSet(self, width) end

---@param self EPMainFrame
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	-- if not self.frame.isResizing then
	if height then
		self:SetHeight(height + windowBarHeight + padding.top + padding.bottom)
	end
	-- end
end

---@param self EPMainFrame
---@return EPContainer|nil
local function GetAssignmentContainer(self)
	local bottomContainer = self.children[2]
	if bottomContainer then
		---@diagnostic disable-next-line: undefined-field
		local bottomLeftContainer = bottomContainer.children[1]
		if bottomLeftContainer then
			---@diagnostic disable-next-line: undefined-field
			local assignmentContainer = bottomLeftContainer.children[3]
			if assignmentContainer then
				return assignmentContainer
			end
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPContainer|nil
local function GetBossAbilityContainer(self)
	local bottomContainer = self.children[2]
	if bottomContainer then
		---@diagnostic disable-next-line: undefined-field
		local bottomLeftContainer = bottomContainer.children[1]
		if bottomLeftContainer then
			---@diagnostic disable-next-line: undefined-field
			local bossAbilityContainer = bottomLeftContainer.children[1]
			if bossAbilityContainer then
				return bossAbilityContainer
			end
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPDropdown|nil
local function GetAddAssigneeDropdown(self)
	local bottomContainer = self.children[2]
	if bottomContainer then
		---@diagnostic disable-next-line: undefined-field
		local bottomLeftContainer = bottomContainer.children[1]
		if bottomLeftContainer then
			---@diagnostic disable-next-line: undefined-field
			local assigneeDropdown = bottomLeftContainer.children[2]
			if assigneeDropdown then
				return assigneeDropdown
			end
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPDropdown|nil
local function GetBossSelectDropdown(self)
	local topContainer = self.children[1]
	if topContainer then
		---@diagnostic disable-next-line: undefined-field
		local bossContainer = topContainer.children[1]
		if bossContainer then
			---@diagnostic disable-next-line: undefined-field
			local bossSelectContainer = bossContainer.children[1]
			if bossSelectContainer then
				---@diagnostic disable-next-line: undefined-field
				return bossSelectContainer.children[1]
			end
		end
	end
	return nil
end

---@param self EPMainFrame
---@return EPDropdown|nil
local function GetBossAbilitySelectDropdown(self)
	local topContainer = self.children[1]
	if topContainer then
		---@diagnostic disable-next-line: undefined-field
		local bossContainer = topContainer.children[1]
		if bossContainer then
			---@diagnostic disable-next-line: undefined-field
			local bossAbilitySelectContainer = bossContainer.children[2]
			if bossAbilitySelectContainer then
				---@diagnostic disable-next-line: undefined-field
				return bossAbilitySelectContainer.children[1]
			end
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
	local bottomContainer = self.children[2]
	if bottomContainer then
		---@diagnostic disable-next-line: undefined-field
		local timeline = bottomContainer.children[2]
		if timeline then
			return timeline
		end
	end
	return nil
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
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
	frame:SetSize(mainFrameWidth, mainFrameHeight)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", padding.left, -(windowBarHeight + padding.top))
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding.right, padding.bottom)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
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
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
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
		OnHeightSet = OnHeightSet,
		OnWidthSet = OnWidthSet,
		LayoutFinished = LayoutFinished,
		GetAssignmentContainer = GetAssignmentContainer,
		GetBossAbilityContainer = GetBossAbilityContainer,
		GetAddAssigneeDropdown = GetAddAssigneeDropdown,
		GetBossSelectDropdown = GetBossSelectDropdown,
		GetBossAbilitySelectDropdown = GetBossAbilitySelectDropdown,
		GetNoteDropdown = GetNoteDropdown,
		GetNoteLineEdit = GetNoteLineEdit,
		GetTimeline = GetTimeline,
		SetPadding = SetPadding,
		frame = frame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
	}

	resizer:SetScript("OnMouseDown", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			if not frame.isResizing then
				frame:StartSizing("BOTTOMRIGHT")
				AceGUI:ClearFocus()
				frame.isResizing = true
			end
		end
	end)

	resizer:SetScript("OnMouseUp", function(_, mouseButton)
		if mouseButton == "LeftButton" then
			if frame.isResizing == true then
				frame.isResizing = nil
				local point, rel, relP, x, y = frame:GetPointByName("TOPLEFT")
				local width = frame:GetWidth()
				local height = frame:GetHeight()
				--Unfortunately this is necessary so that the layout does not get totally borked
				C_Timer.After(0.05, function()
					if not frame.isResizing then
						frame:StopMovingOrSizing()
						AceGUI:ClearFocus()
						frame:SetPoint(point, rel, relP, x, y)
						frame:SetSize(width, height)
						widget:DoLayout()
						-- widget.children[2]:DoLayout()
					end
				end)
			end
		end
	end)

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
