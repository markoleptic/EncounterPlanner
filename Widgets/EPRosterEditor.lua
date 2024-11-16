local Type = "EPRosterEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local sort = sort
local tinsert = tinsert
local tremove = tremove
local wipe = wipe

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

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
---@param newName string
local function HandleRosterEntryNameChanged(self, rosterEntry, newName)
	local rosterWidgetMap = nil
	if self.activeTab == "CurrentBossRoster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif self.activeTab == "SharedRoster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	end

	if rosterWidgetMap then
		local foundEntry = nil
		local conflictsWithExisting = nil
		for _, rosterWidgetMapping in ipairs(rosterWidgetMap) do
			if rosterWidgetMapping.widgetEntry == rosterEntry then
				foundEntry = rosterWidgetMapping
			else
				if newName == rosterWidgetMapping.name then
					conflictsWithExisting = true
				end
			end
		end
		if foundEntry then
			if conflictsWithExisting then
				rosterEntry:SetData(foundEntry.name, foundEntry.dbEntry.class, foundEntry.dbEntry.role)
			else
				foundEntry.name = newName
			end
		end
	end
end

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
---@param newClass string
local function HandleRosterEntryClassChanged(self, rosterEntry, newClass)
	local rosterWidgetMap = nil
	if self.activeTab == "CurrentBossRoster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif self.activeTab == "SharedRoster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	end

	if rosterWidgetMap then
		for _, rosterWidgetMapping in ipairs(rosterWidgetMap) do
			if rosterWidgetMapping.widgetEntry == rosterEntry then
				rosterWidgetMapping.dbEntry.class = newClass
				break
			end
		end
	end
end

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
---@param newRole string
local function HandleRosterEntryRoleChanged(self, rosterEntry, newRole)
	local rosterWidgetMap = nil
	if self.activeTab == "SharedRoster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	elseif self.activeTab == "CurrentBossRoster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	end

	if rosterWidgetMap then
		for _, rosterWidgetMapping in ipairs(rosterWidgetMap) do
			if rosterWidgetMapping.widgetEntry == rosterEntry then
				rosterWidgetMapping.dbEntry.role = newRole
				break
			end
		end
	end
end

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
local function HandleRosterEntryDeleted(self, rosterEntry)
	local rosterWidgetMap = nil
	if self.activeTab == "CurrentBossRoster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif self.activeTab == "SharedRoster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	end

	if rosterWidgetMap then
		for index, rosterWidgetMapping in ipairs(rosterWidgetMap) do
			if rosterWidgetMapping.widgetEntry == rosterEntry then
				print("removed")
				tremove(rosterWidgetMap, index)
				break
			end
		end
	end

	for index, child in ipairs(self.activeContainer.children) do
		if child == rosterEntry then
			AceGUI:Release(child)
			tremove(self.activeContainer.children, index)
			break
		end
	end

	self.activeContainer:DoLayout()
	self:DoLayout()
end

---@param self EPRosterEditor
---@param rosterWidgetMapping RosterWidgetMapping|nil
local function AddRosterEntry(self, rosterWidgetMapping)
	local newRosterEntry = AceGUI:Create("EPRosterEntry")
	if rosterWidgetMapping then
		rosterWidgetMapping.widgetEntry = newRosterEntry
		newRosterEntry:SetData(
			rosterWidgetMapping.name,
			rosterWidgetMapping.dbEntry.class,
			rosterWidgetMapping.dbEntry.role
		)
	else
		if self.activeTab == "CurrentBossRoster" then
			tinsert(self.currentRosterWidgetMap, {
				name = "",
				dbEntry = { class = "", role = "", classColoredName = "" },
				widgetEntry = newRosterEntry,
			})
		elseif self.activeTab == "SharedRoster" then
			tinsert(self.sharedRosterWidgetMap, {
				name = "",
				dbEntry = { class = "", role = "", classColoredName = "" },
				widgetEntry = newRosterEntry,
			})
		end
	end
	newRosterEntry:SetLayout("EPHorizontalLayout")
	newRosterEntry:PopulateClassDropdown(self.classDropdownData)
	newRosterEntry:SetCallback("NameChanged", function(entry, _, newName)
		HandleRosterEntryNameChanged(self, entry, newName)
	end)
	newRosterEntry:SetCallback("ClassChanged", function(entry, _, newClass)
		HandleRosterEntryClassChanged(self, entry, newClass)
	end)
	newRosterEntry:SetCallback("RoleChanged", function(entry, _, newRole)
		HandleRosterEntryRoleChanged(self, entry, newRole)
	end)
	newRosterEntry:SetCallback("DeleteButtonClicked", function(entry, _)
		HandleRosterEntryDeleted(self, entry)
	end)
	self.activeContainer:AddChild(newRosterEntry, self.activeContainer.children[#self.activeContainer.children])
	self:DoLayout()
end

local function HandleImportCurrentRosterButtonClicked(button, _)
	local self = button.obj
	self:Fire("ImportCurrentRosterButtonClicked")
end

local function HandleImportSharedRosterButtonClicked(button, _)
	local self = button.obj
	self:Fire("ImportSharedRosterButtonClicked")
end

---@param self EPRosterEditor
---@param tab EPRosterEditorTab
local function PopulateActiveTab(self, tab)
	if tab == self.activeTab then
		return
	end

	self.activeContainer:ReleaseChildren()
	if tab == "CurrentBossRoster" then
		for _, rosterWidgetMapping in ipairs(self.currentRosterWidgetMap) do
			AddRosterEntry(self, rosterWidgetMapping)
		end
	elseif tab == "SharedRoster" then
		for _, rosterWidgetMapping in ipairs(self.sharedRosterWidgetMap) do
			AddRosterEntry(self, rosterWidgetMapping)
		end
	end
	local addEntryButton = AceGUI:Create("EPButton")
	addEntryButton:SetText("+")
	addEntryButton:SetHeight(20)
	addEntryButton:SetWidth(20)
	addEntryButton:SetCallback("Clicked", function()
		AddRosterEntry(self)
	end)
	self.activeContainer:AddChild(addEntryButton)
	self.activeContainer:DoLayout()

	if tab == "CurrentBossRoster" and #self.buttonContainer.children == 1 then
		local importSharedRosterButton = AceGUI:Create("EPButton")
		importSharedRosterButton:SetText("Fill From Shared Roster")
		importSharedRosterButton:SetWidth(150)
		importSharedRosterButton.obj = self
		importSharedRosterButton:SetCallback("Clicked", HandleImportSharedRosterButtonClicked)
		self.buttonContainer:AddChild(importSharedRosterButton)
	elseif tab == "SharedRoster" and #self.buttonContainer.children == 2 then
		AceGUI:Release(self.buttonContainer.children[2])
		tremove(self.buttonContainer.children, 2)
	end

	self:DoLayout()
	self.activeTab = tab
end

---@class RosterWidgetMapping
---@field name string
---@field dbEntry EncounterPlannerDbRosterEntry
---@field widgetEntry EPRosterEntry

---@alias EPRosterEditorTab
---| "SharedRoster"
---| "CurrentBossRoster"

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
---@field currentRosterWidgetMap table<integer, RosterWidgetMapping>
---@field sharedRosterWidgetMap table<integer, RosterWidgetMapping>
---@field activeTab EPRosterEditorTab

---@param self EPRosterEditor
local function OnAcquire(self)
	self.activeTab = nil
	self.currentRosterWidgetMap = {}
	self.sharedRosterWidgetMap = {}

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
		self:Fire("EditingFinished", self.currentRosterWidgetMap, self.sharedRosterWidgetMap)
	end)

	self.tabContainer = AceGUI:Create("EPContainer")
	self.tabContainer:SetLayout("EPHorizontalLayout")
	self.tabContainer:SetAlignment("center")
	self.tabContainer:SetSpacing(0, 0)

	local currentRosterTab = AceGUI:Create("EPButton")
	local sharedRosterTab = AceGUI:Create("EPButton")

	currentRosterTab:SetIsToggleable(true)
	currentRosterTab:SetText("Current Boss Roster")
	currentRosterTab:SetWidth(150)
	currentRosterTab:SetCallback("Clicked", function()
		if not currentRosterTab:IsToggled() then
			currentRosterTab:Toggle()
			sharedRosterTab:Toggle()
			PopulateActiveTab(self, "CurrentBossRoster")
		end
	end)

	sharedRosterTab:SetIsToggleable(true)
	sharedRosterTab:SetText("Shared Roster")
	sharedRosterTab:SetWidth(150)
	sharedRosterTab:SetCallback("Clicked", function()
		if not sharedRosterTab:IsToggled() then
			sharedRosterTab:Toggle()
			currentRosterTab:Toggle()
		end
		PopulateActiveTab(self, "SharedRoster")
	end)

	self.tabContainer:AddChild(currentRosterTab)
	self.tabContainer:AddChild(sharedRosterTab)

	self:AddChild(self.tabContainer)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 4)

	self:AddChild(self.activeContainer)

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
	self.currentRosterWidgetMap = nil
	self.sharedRosterWidgetMap = nil
	self.activeTab = nil
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
---@param tab EPRosterEditorTab
local function SetCurrentTab(self, tab)
	for _, child in ipairs(self.tabContainer.children) do
		if child:IsToggled() then
			child:Toggle()
		end
	end
	self.tabContainer.children[1]:Toggle()
	PopulateActiveTab(self, tab)
end

---@param self EPRosterEditor
---@param dropdownData DropdownItemData
local function SetClassDropdownData(self, dropdownData)
	self.classDropdownData = dropdownData
end

---@param self EPRosterEditor
---@param currentRoster table<string, EncounterPlannerDbRosterEntry>
---@param sharedRoster table<string, EncounterPlannerDbRosterEntry>
local function SetRosters(self, currentRoster, sharedRoster)
	if self.currentRosterWidgetMap then
		wipe(self.currentRosterWidgetMap)
	end
	if self.sharedRosterWidgetMap then
		wipe(self.sharedRosterWidgetMap)
	end

	for name, data in pairs(currentRoster) do
		tinsert(self.currentRosterWidgetMap, { name = name, dbEntry = data, widgetEntry = nil })
	end
	for name, data in pairs(sharedRoster) do
		tinsert(self.sharedRosterWidgetMap, { name = name, dbEntry = data, widgetEntry = nil })
	end

	sort(self.currentRosterWidgetMap, function(a, b)
		return a.name < b.name
	end)
	sort(self.sharedRosterWidgetMap, function(a, b)
		return a.name < b.name
	end)
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
		SetRosters = SetRosters,
		frame = frame,
		type = Type,
		content = contentFrame,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
