local Type = "EPRosterEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local ipairs = ipairs
local max = math.max
local min = math.min
local pairs = pairs
local sort = sort
local tinsert = tinsert
local tremove = tremove
local unpack = unpack
local wipe = wipe

local mainFrameWidth = 500
local mainFrameHeight = 500
local minScrollFrameHeight = 400
local maxScrollFrameHeight = 600
local windowBarHeight = 28
local contentFramePadding = { x = 10, y = 10 }
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local scrollBarWidth = 16
local thumbPadding = { x = 2, y = 2 }
local verticalScrollBackgroundColor = { 0.25, 0.25, 0.25, 1 }
local verticalThumbBackgroundColor = { 0.05, 0.05, 0.05, 1 }
local minThumbSize = 20
local scrollMultiplier = 25
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

---@param container EPContainer
local function SetButtonWidths(container)
	local maxWidth = 0
	for _, child in ipairs(container.children) do
		maxWidth = max(maxWidth, child.frame:GetWidth())
	end
	for _, child in ipairs(container.children) do
		child:SetWidth(maxWidth)
	end
end

---@param self EPRosterEditor
local function HandleVerticalThumbUpdate(self)
	if not self.verticalThumbIsDragging then
		return
	end

	local currentOffset = self.verticalThumbOffsetWhenThumbClicked
	local currentHeight = self.verticalThumbHeightWhenThumbClicked
	local currentScrollBarHeight = self.verticalScrollBarHeightWhenThumbClicked
	local _, yPosition = GetCursorPosition()
	local newOffset = self.scrollBar:GetTop() - (yPosition / UIParent:GetEffectiveScale()) - currentOffset

	local minAllowedOffset = thumbPadding.y
	local maxAllowedOffset = currentScrollBarHeight - currentHeight - thumbPadding.y
	newOffset = max(newOffset, minAllowedOffset)
	newOffset = min(newOffset, maxAllowedOffset)
	self.thumb:SetPoint("TOP", 0, -newOffset)

	local scrollFrame = self.scrollFrame
	local scrollFrameHeight = scrollFrame:GetHeight()
	local timelineHeight = self.activeContainer.frame:GetHeight()
	local maxScroll = timelineHeight - scrollFrameHeight

	-- Calculate the scroll frame's vertical scroll based on the thumb's position
	local maxThumbPosition = currentScrollBarHeight - currentHeight - (2 * thumbPadding.y)
	local scrollOffset = ((newOffset - thumbPadding.y) / maxThumbPosition) * maxScroll
	scrollFrame:SetVerticalScroll(max(0, scrollOffset))
end

---@param self EPRosterEditor
local function HandleVerticalThumbMouseDown(self)
	local _, y = GetCursorPosition()
	self.verticalThumbOffsetWhenThumbClicked = self.thumb:GetTop() - (y / UIParent:GetEffectiveScale())
	self.verticalScrollBarHeightWhenThumbClicked = self.scrollBar:GetHeight()
	self.verticalThumbHeightWhenThumbClicked = self.thumb:GetHeight()
	self.verticalThumbIsDragging = true
	self.thumb:SetScript("OnUpdate", function()
		HandleVerticalThumbUpdate(self)
	end)
end

---@param self EPRosterEditor
local function HandleVerticalThumbMouseUp(self)
	self.verticalThumbIsDragging = false
	self.thumb:SetScript("OnUpdate", nil)
end

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
---@param newName string
local function HandleRosterEntryNameChanged(self, rosterEntry, newName)
	local rosterWidgetMap = nil
	if self.activeTab == "Current Plan Roster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif self.activeTab == "Shared Roster" then
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
	if self.activeTab == "Current Plan Roster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif self.activeTab == "Shared Roster" then
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
	if self.activeTab == "Shared Roster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	elseif self.activeTab == "Current Plan Roster" then
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
	if self.activeTab == "Current Plan Roster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif self.activeTab == "Shared Roster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	end

	if rosterWidgetMap then
		for index, rosterWidgetMapping in ipairs(rosterWidgetMap) do
			if rosterWidgetMapping.widgetEntry == rosterEntry then
				tremove(rosterWidgetMap, index)
				break
			end
		end
	end

	for _, child in ipairs(self.activeContainer.children) do
		if child == rosterEntry then
			self.activeContainer:RemoveChildNoDoLayout(child)
			break
		end
	end

	self.activeContainer:DoLayout()
	self:Resize()
end

---@param self EPRosterEditor
---@param rosterWidgetMapping RosterWidgetMapping|nil
local function CreateRosterEntry(self, rosterWidgetMapping)
	local newRosterEntry = AceGUI:Create("EPRosterEntry")
	newRosterEntry:PopulateClassDropdown(self.classDropdownData)
	if rosterWidgetMapping then
		rosterWidgetMapping.widgetEntry = newRosterEntry
		newRosterEntry:SetData(
			rosterWidgetMapping.name,
			rosterWidgetMapping.dbEntry.class,
			rosterWidgetMapping.dbEntry.role
		)
	else
		if self.activeTab == "Current Plan Roster" then
			tinsert(self.currentRosterWidgetMap, {
				name = "",
				dbEntry = { class = "", role = "", classColoredName = "" },
				widgetEntry = newRosterEntry,
			})
		elseif self.activeTab == "Shared Roster" then
			tinsert(self.sharedRosterWidgetMap, {
				name = "",
				dbEntry = { class = "", role = "", classColoredName = "" },
				widgetEntry = newRosterEntry,
			})
		end
	end
	newRosterEntry:SetLayout("EPHorizontalLayout")
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
	return newRosterEntry
end

---@param self EPRosterEditor
---@param rosterWidgetMapping RosterWidgetMapping
---@param index integer
local function EditRosterEntry(self, rosterWidgetMapping, index)
	local rosterEntry = self.activeContainer.children[index]
	if rosterEntry then
		rosterEntry:SetData(
			rosterWidgetMapping.name,
			rosterWidgetMapping.dbEntry.class,
			rosterWidgetMapping.dbEntry.role
		)
		rosterWidgetMapping.widgetEntry = rosterEntry
	end
end

---@param self EPRosterEditor
---@param tab EPRosterEditorTab
local function PopulateActiveTab(self, tab)
	if tab == self.activeTab then
		return
	end

	local rosterWidgetMap = nil
	if tab == "Current Plan Roster" then
		rosterWidgetMap = self.currentRosterWidgetMap
	elseif tab == "Shared Roster" then
		rosterWidgetMap = self.sharedRosterWidgetMap
	end
	if rosterWidgetMap then
		local currentCount = #self.activeContainer.children - 1
		local requiredCount = #rosterWidgetMap
		for index = 1, min(currentCount, requiredCount) do
			EditRosterEntry(self, rosterWidgetMap[index], index)
		end
		local children = {}
		for index = currentCount + 1, requiredCount do
			tinsert(children, CreateRosterEntry(self, rosterWidgetMap[index]))
		end
		if #children > 0 then
			self.activeContainer:InsertChildren(
				self.activeContainer.children[#self.activeContainer.children],
				unpack(children)
			)
		end
		if requiredCount < currentCount then
			for i = currentCount, requiredCount + 1, -1 do
				self.activeContainer:RemoveChildNoDoLayout(self.activeContainer.children[i])
			end
			self.activeContainer:DoLayout()
		end
	end

	if tab == "Current Plan Roster" and #self.buttonContainer.children >= 2 then
		self.buttonContainer.children[1]:SetText("Update from Shared Roster")
		self.buttonContainer.children[1]:SetWidthFromText()
		self.buttonContainer.children[2]:SetText("Fill from Shared Roster")
		self.buttonContainer.children[2]:SetWidthFromText()
	elseif tab == "Shared Roster" and #self.buttonContainer.children >= 2 then
		self.buttonContainer.children[1]:SetText("Update from Current Plan Roster")
		self.buttonContainer.children[1]:SetWidthFromText()
		self.buttonContainer.children[2]:SetText("Fill from Current Plan Roster")
		self.buttonContainer.children[2]:SetWidthFromText()
	end

	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
	self:Resize()
	self.activeTab = tab
end

---@class RosterWidgetMapping
---@field name string
---@field dbEntry EncounterPlannerDbRosterEntry
---@field widgetEntry EPRosterEntry

---@alias EPRosterEditorTab
---| "Shared Roster"
---| "Current Plan Roster"
---| ""

---@class EPRosterEditor : AceGUIWidget
---@field frame Frame|table
---@field type string
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
	self.activeTab = ""
	self.currentRosterWidgetMap = {}
	self.sharedRosterWidgetMap = {}
	self.frame:Show()

	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-96]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("EditingFinished", self.currentRosterWidgetMap, self.sharedRosterWidgetMap)
	end)

	self.tabContainer = AceGUI:Create("EPContainer")
	self.tabContainer:SetLayout("EPHorizontalLayout")
	self.tabContainer:SetSpacing(0, 0)
	self.tabContainer:SetAlignment("center")
	self.tabContainer:SetSelfAlignment("center")
	self.tabContainer.frame:SetParent(self.frame)
	self.tabContainer.frame:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -contentFramePadding.y)

	local currentRosterTab = AceGUI:Create("EPButton")
	currentRosterTab:SetIsToggleable(true)
	currentRosterTab:SetText("Current Plan Roster")
	currentRosterTab:SetWidthFromText()
	currentRosterTab:SetCallback("Clicked", function(button, _)
		if not button:IsToggled() then
			for _, child in ipairs(self.tabContainer.children) do
				if child:IsToggled() then
					child:Toggle()
				end
			end
			button:Toggle()
			PopulateActiveTab(self, button.button:GetText())
		end
	end)

	local sharedRosterTab = AceGUI:Create("EPButton")
	sharedRosterTab:SetIsToggleable(true)
	sharedRosterTab:SetText("Shared Roster")
	sharedRosterTab:SetWidthFromText()
	sharedRosterTab:SetCallback("Clicked", function(button, _)
		if not button:IsToggled() then
			for _, child in ipairs(self.tabContainer.children) do
				if child:IsToggled() then
					child:Toggle()
				end
			end
			button:Toggle()
			PopulateActiveTab(self, button.button:GetText())
		end
	end)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 4)
	self.activeContainer.frame:EnableMouse(true)
	self.activeContainer.frame:SetScript("OnMouseWheel", function(_, delta)
		local scrollFrameHeight = self.scrollFrame:GetHeight()
		local timelineFrameHeight = self.activeContainer.frame:GetHeight()
		local maxVerticalScroll = timelineFrameHeight - scrollFrameHeight
		local currentVerticalScroll = self.scrollFrame:GetVerticalScroll()
		local newVerticalScroll = max(min(currentVerticalScroll - (delta * scrollMultiplier), maxVerticalScroll), 0)
		self.scrollFrame:SetVerticalScroll(newVerticalScroll)
		self:UpdateVerticalScroll()
	end)
	local addEntryButton = AceGUI:Create("EPButton")
	addEntryButton:SetText("+")
	addEntryButton:SetHeight(20)
	addEntryButton:SetWidth(20)
	addEntryButton:SetCallback("Clicked", function()
		self.activeContainer:AddChild(CreateRosterEntry(self), addEntryButton)
		self:Resize()
	end)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(contentFramePadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, contentFramePadding.y)

	local updateRosterButton = AceGUI:Create("EPButton")
	updateRosterButton:SetText("Update from Shared Roster")
	updateRosterButton:SetWidthFromText()
	updateRosterButton.obj = self
	updateRosterButton:SetCallback("Clicked", function()
		self:Fire("UpdateRosterButtonClicked", self.activeTab)
	end)
	local fillRosterButton = AceGUI:Create("EPButton")
	fillRosterButton:SetText("Fill from Shared Roster")
	fillRosterButton:SetWidthFromText()
	fillRosterButton.obj = self
	fillRosterButton:SetCallback("Clicked", function()
		self:Fire("FillRosterButtonClicked", self.activeTab)
	end)
	local importCurrentGroupButton = AceGUI:Create("EPButton")
	importCurrentGroupButton:SetText("Import Current Party/Raid Group")
	importCurrentGroupButton:SetWidthFromText()
	importCurrentGroupButton.obj = self
	importCurrentGroupButton:SetCallback("Clicked", function()
		self:Fire("ImportCurrentGroupButtonClicked", self.activeTab)
	end)

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(self.frame)
	self.scrollBar:SetPoint("RIGHT", -contentFramePadding.x, 0)
	self.scrollBar:SetPoint("TOP", self.tabContainer.frame, "BOTTOM", 0, -contentFramePadding.y)
	self.scrollBar:SetPoint("BOTTOM", self.buttonContainer.frame, "TOP", 0, contentFramePadding.y)
	self.scrollBar:Show()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(self.scrollBar)
	self.thumb:SetPoint("TOP", 0, -thumbPadding.y)
	self.thumb:SetScript("OnMouseDown", function()
		HandleVerticalThumbMouseDown(self)
	end)
	self.thumb:SetScript("OnMouseUp", function()
		HandleVerticalThumbMouseUp(self)
	end)
	self.thumb:Show()

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(self.frame)
	self.scrollFrame:SetPoint("LEFT", contentFramePadding.x, 0)
	self.scrollFrame:SetPoint("TOP", self.tabContainer.frame, "BOTTOM", 0, -contentFramePadding.y)
	self.scrollFrame:SetPoint("BOTTOM", self.buttonContainer.frame, "TOP", 0, contentFramePadding.y)
	self.scrollFrame:SetPoint("RIGHT", self.scrollBar, "LEFT", -contentFramePadding.x / 2.0, 0)
	self.scrollFrame:Show()

	self.activeContainer.frame:SetParent(self.scrollFrame)
	self.scrollFrame:SetScrollChild(self.activeContainer.frame --[[@as Frame]])
	self.activeContainer.frame:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT")

	self.tabContainer:AddChildren(currentRosterTab, sharedRosterTab)
	SetButtonWidths(self.tabContainer)
	self.tabContainer:DoLayout()

	self.buttonContainer:AddChildren(updateRosterButton, fillRosterButton, importCurrentGroupButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	self.activeContainer:AddChild(addEntryButton)
end

---@param self EPRosterEditor
local function OnRelease(self)
	self.closeButton:Release()
	self.closeButton = nil

	self.tabContainer:Release()
	self.tabContainer = nil

	self.activeContainer.frame:EnableMouse(false)
	self.activeContainer.frame:SetScript("OnMouseWheel", nil)
	self.activeContainer:Release()
	self.activeContainer = nil

	self.buttonContainer:Release()
	self.buttonContainer = nil

	self.scrollFrame:ClearAllPoints()
	self.scrollFrame:SetParent(UIParent)
	self.scrollFrame:Hide()

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetParent(UIParent)
	self.scrollBar:Hide()

	self.thumb:ClearAllPoints()
	self.thumb:SetParent(UIParent)
	self.thumb:Hide()

	self.thumb:SetScript("OnMouseDown", nil)
	self.thumb:SetScript("OnMouseUp", nil)
	self.thumb:SetScript("OnUpdate", nil)

	self.currentRosterWidgetMap = nil
	self.sharedRosterWidgetMap = nil
	self.activeTab = nil
end

---@param self EPRosterEditor
local function OnHeightSet(self, height)
	self:UpdateVerticalScroll()
end

---@param self EPRosterEditor
local function UpdateVerticalScroll(self)
	local scrollBarHeight = self.scrollBar:GetHeight()
	local scrollFrameHeight = self.scrollFrame:GetHeight()
	local containerHeight = self.activeContainer.frame:GetHeight()
	local verticalScroll = self.scrollFrame:GetVerticalScroll()

	local thumbHeight = (scrollFrameHeight / containerHeight) * (scrollBarHeight - (2 * thumbPadding.y))
	thumbHeight = max(thumbHeight, minThumbSize) -- Minimum size so it's always visible
	thumbHeight = min(thumbHeight, scrollFrameHeight - (2 * thumbPadding.y))
	self.thumb:SetHeight(thumbHeight)

	local maxScroll = containerHeight - scrollFrameHeight
	local maxThumbPosition = scrollBarHeight - thumbHeight - (2 * thumbPadding.y)
	local verticalThumbPosition = 0
	if maxScroll > 0 then
		verticalThumbPosition = (verticalScroll / maxScroll) * maxThumbPosition
		verticalThumbPosition = verticalThumbPosition + thumbPadding.x
	else
		verticalThumbPosition = thumbPadding.y -- If no scrolling is possible, reset the thumb to the start
	end
	self.thumb:SetPoint("TOP", 0, -verticalThumbPosition)

	if verticalScroll > maxScroll then
		self.scrollFrame:SetVerticalScroll(max(0, maxScroll))
	end
end

---@param self EPRosterEditor
local function Resize(self)
	local tableTitleContainerHeight = self.tabContainer.frame:GetHeight()
	local containerHeight = self.activeContainer.frame:GetHeight()
	local scrollAreaHeight = min(max(containerHeight, minScrollFrameHeight), maxScrollFrameHeight)
	local buttonContainerHeight = self.buttonContainer.frame:GetHeight()
	local paddingHeight = contentFramePadding.y * 4

	local width = contentFramePadding.x * 2
	if containerHeight < self.scrollFrame:GetHeight() then
		self.scrollFrame:SetPoint("RIGHT", self.frame, "RIGHT", -contentFramePadding.x, 0)
		self.scrollBar:SetWidth(0)
		self.scrollBar:Hide()
	else
		self.scrollBar:Show()
		self.scrollBar:SetWidth(scrollBarWidth)
		self.scrollFrame:SetPoint("RIGHT", self.scrollBar, "LEFT", -contentFramePadding.x / 2.0, 0)
		width = width + self.scrollBar:GetWidth() + contentFramePadding.x / 2.0
	end

	local tabWidth = self.tabContainer.frame:GetWidth()
	local activeWidth = self.activeContainer.frame:GetWidth()
	local buttonWidth = self.buttonContainer.frame:GetWidth()
	width = width + max(tabWidth, max(activeWidth, buttonWidth))

	local height = windowBarHeight
		+ tableTitleContainerHeight
		+ scrollAreaHeight
		+ buttonContainerHeight
		+ paddingHeight
	self.frame:SetSize(width, height)
	self.activeContainer:DoLayout()
	self:UpdateVerticalScroll()
end

---@param self EPRosterEditor
---@param tab EPRosterEditorTab
local function SetCurrentTab(self, tab)
	self.activeTab = ""
	for _, child in ipairs(self.tabContainer.children) do
		if child.button:GetText() == tab and not child:IsToggled() then
			child:Toggle()
		elseif child:IsToggled() then
			child:Toggle()
		end
	end
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
		tinsert(self.currentRosterWidgetMap, {
			name = name,
			dbEntry = { class = data.class, classColoredName = data.classColoredName, role = data.role },
			widgetEntry = nil,
		})
	end
	for name, data in pairs(sharedRoster) do
		tinsert(self.sharedRosterWidgetMap, {
			name = name,
			dbEntry = { class = data.class, classColoredName = data.classColoredName, role = data.role },
			widgetEntry = nil,
		})
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
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(mainFrameWidth, mainFrameHeight)

	local scrollFrame = CreateFrame("ScrollFrame", Type .. "ScrollFrame" .. count, frame)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
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

	local verticalScrollBar = CreateFrame("Frame", Type .. "VerticalScrollBar" .. count, frame)
	verticalScrollBar:SetWidth(scrollBarWidth)
	verticalScrollBar:SetPoint("TOPRIGHT")
	verticalScrollBar:SetPoint("BOTTOMRIGHT")

	local verticalScrollBarBackground =
		verticalScrollBar:CreateTexture(Type .. "VerticalScrollBarBackground" .. count, "BACKGROUND")
	verticalScrollBarBackground:SetAllPoints()
	verticalScrollBarBackground:SetColorTexture(unpack(verticalScrollBackgroundColor))

	local verticalThumb = CreateFrame("Button", Type .. "VerticalScrollBarThumb" .. count, verticalScrollBar)
	verticalThumb:SetPoint("TOP", 0, thumbPadding.y)
	verticalThumb:SetSize(scrollBarWidth - (2 * thumbPadding.x), verticalScrollBar:GetHeight() - 2 * thumbPadding.y)
	verticalThumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

	local verticalThumbBackground =
		verticalThumb:CreateTexture(Type .. "VerticalScrollBarThumbBackground" .. count, "BACKGROUND")
	verticalThumbBackground:SetAllPoints()
	verticalThumbBackground:SetColorTexture(unpack(verticalThumbBackgroundColor))

	---@class EPRosterEditor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		UpdateVerticalScroll = UpdateVerticalScroll,
		SetCurrentTab = SetCurrentTab,
		SetClassDropdownData = SetClassDropdownData,
		SetRosters = SetRosters,
		Resize = Resize,
		OnHeightSet = OnHeightSet,
		frame = frame,
		scrollFrame = scrollFrame,
		type = Type,
		windowBar = windowBar,
		scrollBar = verticalScrollBar,
		thumb = verticalThumb,
		verticalThumbOffsetWhenThumbClicked = 0,
		verticalScrollBarHeightWhenThumbClicked = 0,
		verticalThumbHeightWhenThumbClicked = 0,
		verticalThumbIsDragging = false,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
