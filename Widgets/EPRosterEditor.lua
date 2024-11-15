local Type = "EPRosterEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame

local mainFrameWidth = 500
local mainFrameHeight = 500
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

local function HandleAddMemberClassDropdownValueChanged() end

local function HandleImportCurrentRosterButtonClicked(button, _)
	local self = button.obj
	self:Fire("ImportCurrentRosterButtonClicked")
end

local function HandleImportSharedRosterButtonClicked(button, _)
	local self = button.obj
	self:Fire("ImportSharedRosterButtonClicked")
end

---@param self EPRosterEditor
---@param tabIndex integer
local function PopulateActiveTab(self, tabIndex)
	if not self.activeContainer then
		self.activeContainer = AceGUI:Create("EPContainer")
		self.activeContainer:SetLayout("EPVerticalLayout")
		self.activeContainer:SetSpacing(0, 4)
		local addEntryButton = AceGUI:Create("EPButton")
		addEntryButton:SetText("+")
		addEntryButton:SetHeight(20)
		addEntryButton:SetWidth(20)
		addEntryButton:SetCallback("Clicked", function()
			local newRosterEntry = AceGUI:Create("EPRosterEntry")
			newRosterEntry:SetLayout("EPHorizontalLayout")
			newRosterEntry:PopulateClassDropdown(self.classDropdownData)
			newRosterEntry:SetCallback("NameChanged", function() end)
			newRosterEntry:SetCallback("ClassChanged", function() end)
			newRosterEntry:SetCallback("RoleChanged", function() end)
			newRosterEntry:SetCallback("DeleteButtonClicked", function() end)
			self.activeContainer:AddChild(newRosterEntry, self.activeContainer.children[#self.activeContainer.children])
			self:DoLayout()
		end)
		self.activeContainer:AddChild(addEntryButton)
		self:AddChild(self.activeContainer, self.buttonContainer)
	end

	if tabIndex == self.activeContainer.tabIndex then
		return
	end

	if tabIndex == 1 and #self.buttonContainer.children == 2 then
		AceGUI:Release(self.buttonContainer.children[2])
		self.buttonContainer.children[2] = nil
		self.buttonContainer:DoLayout()
	elseif tabIndex == 2 and #self.buttonContainer.children == 1 then
		local importSharedRosterButton = AceGUI:Create("EPButton")
		importSharedRosterButton:SetText("Fill From Shared Roster")
		importSharedRosterButton:SetWidth(150)
		importSharedRosterButton.obj = self
		importSharedRosterButton:SetCallback("Clicked", HandleImportSharedRosterButtonClicked)
		self.buttonContainer:AddChild(importSharedRosterButton)
		self.buttonContainer:DoLayout()
	end

	--self.activeContainer:ReleaseChildren()
	self.activeContainer.tabIndex = tabIndex
	self:DoLayout()
end

---@class EPRosterEditor : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field type string
---@field content table|Frame
---@field windowBar table|Frame
---@field closeButton EPButton
---@field children table<integer, AceGUIWidget>
---@field tabContainer EPContainer
---@field activeContainer EPContainer
---@field buttonContainer EPContainer
---@field classDropdownData DropdownItemData

---@param self EPRosterEditor
local function OnAcquire(self)
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.frame:Show()

	self.content.alignment = "center"
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

	self.tabContainer = AceGUI:Create("EPContainer")
	self.tabContainer:SetLayout("EPHorizontalLayout")
	self.tabContainer:SetAlignment("center")
	self.tabContainer:SetSpacing(0, 0)

	local firstTab = AceGUI:Create("EPButton")
	firstTab:SetText("Shared Roster")
	firstTab:SetWidth(150)
	firstTab:SetCallback("Clicked", function()
		PopulateActiveTab(self, 1)
	end)

	local secondTab = AceGUI:Create("EPButton")
	secondTab:SetText("Current Boss Roster")
	secondTab:SetWidth(150)
	secondTab:SetCallback("Clicked", function()
		PopulateActiveTab(self, 2)
	end)

	self.tabContainer:AddChild(firstTab)
	self.tabContainer:AddChild(secondTab)

	self:AddChild(self.tabContainer)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")

	local importCurrentRosterButton = AceGUI:Create("EPButton")
	importCurrentRosterButton:SetText("Import Current Raid Roster")
	importCurrentRosterButton:SetWidth(150)
	importCurrentRosterButton.obj = self
	importCurrentRosterButton:SetCallback("Clicked", HandleImportCurrentRosterButtonClicked)

	local importSharedRosterButton = AceGUI:Create("EPButton")
	importSharedRosterButton:SetText("Fill From Shared Roster")
	importSharedRosterButton:SetWidth(150)
	importSharedRosterButton.obj = self
	importSharedRosterButton:SetCallback("Clicked", HandleImportSharedRosterButtonClicked)

	self.buttonContainer:AddChild(importCurrentRosterButton)
	self.buttonContainer:AddChild(importSharedRosterButton)
	self:AddChild(self.buttonContainer)
end

---@param self EPRosterEditor
local function OnRelease(self)
	if self.closeButton then
		self.closeButton:Release()
	end
	self.closeButton = nil
	self.tabContainer = nil
	self.activeContainer = nil
	self.buttonContainer = nil
	self.classDropdownData = nil
end

---@param self EPRosterEditor
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetSize(width + contentFramePadding.x * 2, height + windowBarHeight + contentFramePadding.y * 2)
	end
end

---@param self EPRosterEditor
---@param index integer
local function SetCurrentTab(self, index)
	PopulateActiveTab(self, index)
end

---@param self EPRosterEditor
---@param dropdownData DropdownItemData
local function SetClassDropdownData(self, dropdownData)
	self.classDropdownData = dropdownData
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	frame:SetSize(mainFrameWidth, mainFrameHeight)

	local contentFrame = CreateFrame("Frame", Type .. "ContentFrame" .. count, frame)
	contentFrame:SetPoint(
		"TOPLEFT",
		frame,
		"TOPLEFT",
		contentFramePadding.x,
		-(windowBarHeight + contentFramePadding.y)
	)
	contentFrame:SetPoint(
		"TOPRIGHT",
		frame,
		"TOPRIGHT",
		-contentFramePadding.x,
		-(windowBarHeight + contentFramePadding.y)
	)
	contentFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentFramePadding.x, contentFramePadding.y)
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentFramePadding.x, contentFramePadding.y)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 1)
	windowBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	windowBar:EnableMouse(true)
	local windowBarText = windowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText("Roster Editor")
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

	---@class EPRosterEditor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		SetCurrentTab = SetCurrentTab,
		SetClassDropdownData = SetClassDropdownData,
		frame = frame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
