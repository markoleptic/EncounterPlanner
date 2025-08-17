local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPRosterEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local ipairs = ipairs
local max = math.max
local min = math.min
local pairs = pairs
local sort = table.sort
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack
local wipe = table.wipe

local k = {
	DefaultFrameWidth = 500,
	DefaultFrameHeight = 500,
	PreferredHeight = 600,
	WindowBarHeight = 28,
	ContentFramePadding = { x = 15, y = 15 },
	OtherPadding = { x = 10, y = 10 },
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	BackdropColor = { 0, 0, 0, 1 },
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	CloseButtonBackdropColor = { 0, 0, 0, 0.9 },
	ActiveContainerPadding = { 10, 10, 10, 10 },
	FrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 27, bottom = 0 },
	},
	TitleBarBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
	},
	ClassRoles = {
		["class:DeathKnight"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = true,
		},
		["class:DemonHunter"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = true,
		},
		["class:Druid"] = {
			["role:damager"] = true,
			["role:healer"] = true,
			["role:tank"] = true,
		},
		["class:Evoker"] = {
			["role:damager"] = true,
			["role:healer"] = true,
			["role:tank"] = false,
		},
		["class:Hunter"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = false,
		},
		["class:Mage"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = false,
		},
		["class:Monk"] = {
			["role:damager"] = true,
			["role:healer"] = true,
			["role:tank"] = true,
		},
		["class:Paladin"] = {
			["role:damager"] = true,
			["role:healer"] = true,
			["role:tank"] = true,
		},
		["class:Priest"] = {
			["role:damager"] = true,
			["role:healer"] = true,
			["role:tank"] = false,
		},
		["class:Rogue"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = false,
		},
		["class:Shaman"] = {
			["role:damager"] = true,
			["role:healer"] = true,
			["role:tank"] = false,
		},
		["class:Warlock"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = false,
		},
		["class:Warrior"] = {
			["role:damager"] = true,
			["role:healer"] = false,
			["role:tank"] = true,
		},
	},
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
---@param tab EPRosterEditorTab
local function GetRosterWidgetMap(self, tab)
	if tab == "Current Plan Roster" then
		return self.currentRosterWidgetMap
	elseif tab == "Shared Roster" then
		return self.sharedRosterWidgetMap
	end
	return nil
end

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
---@param newName string
local function HandleRosterEntryNameChanged(self, rosterEntry, newName)
	local rosterWidgetMap = GetRosterWidgetMap(self, self.activeTab)
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
	local rosterWidgetMap = GetRosterWidgetMap(self, self.activeTab)
	if rosterWidgetMap then
		for _, rosterWidgetMapping in ipairs(rosterWidgetMap) do
			if rosterWidgetMapping.widgetEntry == rosterEntry then
				rosterWidgetMapping.dbEntry.class = newClass
				if k.ClassRoles[newClass] then
					rosterEntry:PopulateRoleDropdown(k.ClassRoles[newClass])
					local hasHealerRole = k.ClassRoles[newClass]["role:healer"]
					local hasTankRole = k.ClassRoles[newClass]["role:tank"]
					local roleValid = k.ClassRoles[newClass][rosterWidgetMapping.dbEntry.role]
					if (not hasHealerRole and not hasTankRole) or not roleValid then
						rosterWidgetMapping.dbEntry.role = "role:damager"
					end
					rosterEntry:SetData(
						rosterWidgetMapping.name,
						rosterWidgetMapping.dbEntry.class,
						rosterWidgetMapping.dbEntry.role
					)
				end
				break
			end
		end
	end
end

---@param self EPRosterEditor
---@param rosterEntry EPRosterEntry
---@param newRole string
local function HandleRosterEntryRoleChanged(self, rosterEntry, newRole)
	local rosterWidgetMap = GetRosterWidgetMap(self, self.activeTab)
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
	local rosterWidgetMap = GetRosterWidgetMap(self, self.activeTab)
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
	newRosterEntry:SetFullWidth(true)
	newRosterEntry:PopulateClassDropdown(self.classDropdownData)
	if rosterWidgetMapping then
		rosterWidgetMapping.widgetEntry = newRosterEntry
		if k.ClassRoles[rosterWidgetMapping.dbEntry.class] then
			newRosterEntry:PopulateRoleDropdown(k.ClassRoles[rosterWidgetMapping.dbEntry.class])
		else
			newRosterEntry:PopulateRoleDropdown({})
		end
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
		if k.ClassRoles[rosterWidgetMapping.dbEntry.class] then
			rosterEntry:PopulateRoleDropdown(k.ClassRoles[rosterWidgetMapping.dbEntry.class])
		else
			rosterEntry:PopulateRoleDropdown({})
		end
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
	self.activeTab = tab
	local rosterWidgetMap = GetRosterWidgetMap(self, tab)
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
		self.buttonContainer.children[1]:SetText(L["Update from Shared Roster"])
		self.buttonContainer.children[1]:SetWidthFromText()
		self.buttonContainer.children[2]:SetText(L["Fill from Shared Roster"])
		self.buttonContainer.children[2]:SetWidthFromText()
	elseif tab == "Shared Roster" and #self.buttonContainer.children >= 2 then
		self.buttonContainer.children[1]:SetText(L["Update from Current Plan Roster"])
		self.buttonContainer.children[1]:SetWidthFromText()
		self.buttonContainer.children[2]:SetText(L["Fill from Current Plan Roster"])
		self.buttonContainer.children[2]:SetWidthFromText()
	end

	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
	self:Resize()
	self.scrollFrame:UpdateVerticalScroll()
	for _, child in ipairs(self.activeContainer.children) do
		if child.SetRelativeWidths then
			child:SetRelativeWidths(self.activeContainer.content:GetWidth())
			child:DoLayout()
		end
	end
	self.scrollFrame:UpdateThumbPositionAndSize()
end

---@class RosterWidgetMapping
---@field name string
---@field dbEntry RosterEntry
---@field widgetEntry EPRosterEntry

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
---@field scrollFrame EPScrollFrame

---@param self EPRosterEditor
local function OnAcquire(self)
	self.activeTab = ""
	self.currentRosterWidgetMap = {}
	self.sharedRosterWidgetMap = {}

	self.frame:SetSize(800, 800)

	local edgeSize = k.FrameBackdrop.edgeSize
	local buttonSize = k.WindowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(k.CloseButtonBackdropColor))
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
	self.tabContainer.frame:SetPoint("TOP", self.windowBar, "BOTTOM", 0, -k.ContentFramePadding.y)

	local currentRosterTab = AceGUI:Create("EPButton")
	currentRosterTab:SetIsToggleable(true)
	currentRosterTab:SetText(L["Current Plan Roster"], "Current Plan Roster")
	currentRosterTab:SetWidthFromText()
	currentRosterTab:SetColor(unpack(k.NeutralButtonColor))
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
	sharedRosterTab:SetText(L["Shared Roster"], "Shared Roster")
	sharedRosterTab:SetWidthFromText()
	sharedRosterTab:SetColor(unpack(k.NeutralButtonColor))
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
	self.activeContainer:SetPadding(unpack(k.ActiveContainerPadding))
	self.activeContainer.frame:EnableMouse(true)

	local addEntryButton = AceGUI:Create("EPButton")
	addEntryButton:SetText("+")
	addEntryButton:SetHeight(20)
	addEntryButton:SetWidth(20)
	addEntryButton:SetColor(unpack(k.NeutralButtonColor))
	addEntryButton:SetCallback("Clicked", function()
		self.activeContainer:AddChild(CreateRosterEntry(self), addEntryButton)
		for _, child in ipairs(self.activeContainer.children) do
			if child.SetRelativeWidths then
				child:SetRelativeWidths(self.activeContainer.content:GetWidth())
				child:DoLayout()
			end
		end
		self:Resize()
	end)

	self.activeContainer:AddChild(addEntryButton)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(k.OtherPadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.ContentFramePadding.y)

	local updateRosterButton = AceGUI:Create("EPButton")
	updateRosterButton:SetText(L["Update from Shared Roster"])
	updateRosterButton:SetWidthFromText()
	updateRosterButton:SetColor(unpack(k.NeutralButtonColor))
	updateRosterButton:SetCallback("Clicked", function()
		self:Fire("UpdateRosterButtonClicked", self.activeTab)
	end)
	local fillRosterButton = AceGUI:Create("EPButton")
	fillRosterButton:SetText(L["Fill from Shared Roster"])
	fillRosterButton:SetWidthFromText()
	fillRosterButton:SetColor(unpack(k.NeutralButtonColor))
	fillRosterButton:SetCallback("Clicked", function()
		self:Fire("FillRosterButtonClicked", self.activeTab)
	end)
	local importCurrentGroupButton = AceGUI:Create("EPButton")
	importCurrentGroupButton:SetText(L["Import Current Party/Raid Group"])
	importCurrentGroupButton:SetWidthFromText()
	importCurrentGroupButton:SetColor(unpack(k.NeutralButtonColor))
	importCurrentGroupButton:SetCallback("Clicked", function()
		self:Fire("ImportCurrentGroupButtonClicked", self.activeTab)
	end)

	self.tabContainer:AddChildren(currentRosterTab, sharedRosterTab)
	SetButtonWidths(self.tabContainer)
	self.tabContainer:DoLayout()

	self.buttonContainer:AddChildren(updateRosterButton, fillRosterButton, importCurrentGroupButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame)
	self.scrollFrame.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.tabContainer.frame, "BOTTOM", 0, -k.ContentFramePadding.y)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("BOTTOM", self.buttonContainer.frame, "TOP", 0, k.ContentFramePadding.y)
	self.scrollFrame:SetScrollChild(self.activeContainer.frame --[[@as Frame]], true, false)

	self.frame:Show()
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

	self.scrollFrame:Release()
	self.scrollFrame = nil

	self.currentRosterWidgetMap = nil
	self.sharedRosterWidgetMap = nil
	self.activeTab = nil
end

---@param self EPRosterEditor
local function Resize(self)
	local width = k.ContentFramePadding.x * 2 + self.buttonContainer.frame:GetWidth()

	self.frame:SetSize(width, k.PreferredHeight)
	self.activeContainer:DoLayout()
end

---@param self EPRosterEditor
---@param tab EPRosterEditorTab
local function SetCurrentTab(self, tab)
	self.activeTab = ""
	for _, child in ipairs(self.tabContainer.children) do
		if child:GetValue() == tab then
			if not child:IsToggled() then
				child:Toggle()
			end
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
---@param currentRoster table<string, RosterEntry>
---@param sharedRoster table<string, RosterEntry>
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
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(k.WindowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(k.TitleBarBackdrop)
	windowBar:SetBackdropColor(unpack(k.BackdropColor))
	windowBar:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	windowBar:EnableMouse(true)
	local windowBarText = windowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(L["Roster Editor"])
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
		frame:StopMovingOrSizing()
		frame:ClearAllPoints()
		frame:SetPoint("TOP", x - UIParent:GetWidth() / 2.0 + frame:GetWidth() / 2.0, -(UIParent:GetHeight() - y))
	end)

	---@class EPRosterEditor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetCurrentTab = SetCurrentTab,
		SetClassDropdownData = SetClassDropdownData,
		SetRosters = SetRosters,
		Resize = Resize,
		frame = frame,
		type = Type,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
