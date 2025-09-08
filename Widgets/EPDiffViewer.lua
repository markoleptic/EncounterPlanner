local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

local Type = "EPDiffViewer"
local Version = 1

---@class BossUtilities
local bossUtilities = Private.bossUtilities

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local format = string.format
local max = math.max
local tinsert = table.insert
local unpack = unpack

local PlanDiffType = Private.classes.PlanDiffType
local DifficultyType = Private.classes.DifficultyType

local k = {
	BackdropBorderColor = { 0.25, 0.25, 0.25, 1 },
	BackdropColor = { 0, 0, 0, 1 },
	ContentFramePadding = { x = 15, y = 15 },
	DefaultButtonHeight = 24,
	DefaultFontSize = 14,
	DefaultHeight = 400,
	DefaultWidth = 600,
	FrameBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		tile = true,
		tileSize = 16,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 27, bottom = 0 },
	},
	LineColor = { 0.25, 0.25, 0.25, 1.0 },
	NeutralButtonColor = Private.constants.colors.kNeutralButtonActionColor,
	OtherPadding = { x = 10, y = 10 },
	Title = L["Plan Change Request"],
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

---@param self EPDiffViewer
---@param text string
---@param dividerLineIndex integer
local function AddSectionLabel(self, text, dividerLineIndex)
	local sectionLabel = AceGUI:Create("EPMultiLineText")
	sectionLabel:SetFullWidth(true)
	sectionLabel:SetText(text)
	sectionLabel:SetFontSize(16)
	sectionLabel:SetTextColor(1, 0.82, 0, 1)
	sectionLabel.frame:SetHeight(28)
	self.mainContainer:AddChild(sectionLabel)
	if not self.dividerLines[dividerLineIndex] then
		local dividerLine = self.frame:CreateTexture(nil, "OVERLAY")
		dividerLine:SetColorTexture(unpack(k.LineColor))
		dividerLine:SetHeight(2)
		self.dividerLines[dividerLineIndex] = dividerLine
	end
	self.dividerLines[dividerLineIndex]:SetParent(self.mainContainer.frame)
	self.dividerLines[dividerLineIndex]:SetPoint("LEFT", self.mainContainer.frame, "LEFT")
	self.dividerLines[dividerLineIndex]:SetPoint("RIGHT", self.mainContainer.frame, "RIGHT")
	self.dividerLines[dividerLineIndex]:SetPoint("TOP", sectionLabel.frame, "BOTTOM")
	self.dividerLines[dividerLineIndex]:Show()
	return dividerLineIndex + 1
end

---@param self EPDiffViewer
local function OnAcquire(self)
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local windowBar = AceGUI:Create("EPWindowBar")
	windowBar:SetTitle(k.Title)
	windowBar:RemoveButtons()
	windowBar.frame:SetParent(self.frame)
	windowBar.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	windowBar.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
	windowBar:SetCallback("OnMouseDown", function()
		self.frame:StartMoving()
	end)
	windowBar:SetCallback("OnMouseUp", function()
		self.frame:StopMovingOrSizing()
	end)
	self.windowBar = windowBar

	self.text:SetPoint("TOP", self.windowBar.frame, "BOTTOM", 0, -k.ContentFramePadding.y)
	self.text:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
	self.text:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)

	self.mainContainer = AceGUI:Create("EPContainer")
	self.mainContainer:SetLayout("EPVerticalLayout")
	self.mainContainer:SetSpacing(0, 0)
	self.mainContainer:SetFullWidth(true)

	self.buttonContainer = AceGUI:Create("EPContainer")
	self.buttonContainer:SetLayout("EPHorizontalLayout")
	self.buttonContainer:SetSpacing(k.OtherPadding.x, 0)
	self.buttonContainer:SetAlignment("center")
	self.buttonContainer:SetSelfAlignment("center")
	self.buttonContainer.frame:SetParent(self.frame)
	self.buttonContainer.frame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, k.ContentFramePadding.y)

	local acceptButton = AceGUI:Create("EPButton")
	acceptButton:SetText(L["Accept"])
	acceptButton:SetWidthFromText()
	acceptButton:SetHeight(k.DefaultButtonHeight)
	acceptButton:SetColor(unpack(k.NeutralButtonColor))
	acceptButton:SetCallback("Clicked", function()
		self:Fire("Accepted")
	end)

	local rejectButton = AceGUI:Create("EPButton")
	rejectButton:SetText(L["Reject"])
	rejectButton:SetWidthFromText()
	rejectButton:SetHeight(k.DefaultButtonHeight)
	rejectButton:SetColor(unpack(k.NeutralButtonColor))
	rejectButton:SetCallback("Clicked", function()
		self:Fire("Rejected")
	end)

	self.buttonContainer:AddChildren(acceptButton, rejectButton)
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()

	local selectAllButton = AceGUI:Create("EPButton")
	selectAllButton:SetText(L["Toggle Select All"])
	selectAllButton:SetWidthFromText()
	selectAllButton:SetColor(unpack(k.NeutralButtonColor))
	local sChecked = false
	selectAllButton:SetCallback("Clicked", function()
		for _, child in ipairs(self.mainContainer.children) do
			if child.type == "EPDiffViewerEntry" then
				---@cast child EPDiffViewerEntry
				child.checkBox:SetChecked(sChecked)
			end
		end

		if self.planDiff.metaData.instanceID then
			self.planDiff.metaData.instanceID.result = sChecked
		end
		if self.planDiff.metaData.dungeonEncounterID then
			self.planDiff.metaData.dungeonEncounterID.result = sChecked
		end
		if self.planDiff.metaData.difficulty then
			self.planDiff.metaData.difficulty.result = sChecked
		end
		for _, diff in ipairs(self.planDiff.assignments) do
			diff.result = sChecked
		end
		for _, diff in ipairs(self.planDiff.roster) do
			diff.result = sChecked
		end
		for _, diff in ipairs(self.planDiff.content) do
			diff.result = sChecked
		end

		sChecked = not sChecked
	end)
	selectAllButton.frame:SetParent(self.frame)
	selectAllButton.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)
	self.selectAllButton = selectAllButton

	self.scrollFrame = AceGUI:Create("EPScrollFrame")
	self.scrollFrame.frame:SetParent(self.frame)
	self.scrollFrame.frame:SetSize(k.DefaultWidth, k.DefaultHeight)
	self.scrollFrame.frame:SetPoint("LEFT", self.frame, "LEFT", k.ContentFramePadding.x, 0)
	self.scrollFrame.frame:SetPoint("TOP", self.text, "BOTTOM", 0, -k.OtherPadding.y)
	self.scrollFrame.frame:SetPoint("RIGHT", self.frame, "RIGHT", -k.ContentFramePadding.x, 0)
	self.scrollFrame:SetScrollChild(self.mainContainer.frame, true, false)

	selectAllButton.frame:SetPoint("BOTTOM", self.buttonContainer.frame, "TOP", 0, k.OtherPadding.y)
	self.scrollFrame.frame:SetPoint("BOTTOM", selectAllButton.frame, "TOP", 0, k.OtherPadding.y)

	self.frame:Show()
end

---@param self EPDiffViewer
local function OnRelease(self)
	self.windowBar:Release()
	self.windowBar = nil

	self.planDiff = nil
	self.mainContainer.frame:EnableMouse(false)
	self.mainContainer.frame:SetScript("OnMouseWheel", nil)
	self.mainContainer:Release()
	self.mainContainer = nil

	self.buttonContainer:Release()
	self.buttonContainer = nil

	self.scrollFrame:Release()
	self.scrollFrame = nil

	self.selectAllButton:Release()
	self.selectAllButton = nil

	for _, dividerLine in ipairs(self.dividerLines) do
		dividerLine:SetParent(self.frame)
		dividerLine:ClearAllPoints()
		dividerLine:Hide()
	end

	self.text:ClearAllPoints()
	self.text:SetText("")
end

---@param self EPDiffViewer
---@param diffs PlanDiff
---@param oldPlan Plan
---@param newPlan Plan
local function AddDiffs(self, diffs, oldPlan, newPlan)
	self.planDiff = diffs
	local addedMetaDataSection, addedAssignmentSection, addedRosterSection = nil, nil, nil
	local addedAssigneeSpellSetsSection, addedContentSection = nil, nil
	local dividerLineIndex = 1

	if diffs.metaData.instanceID then
		if not addedMetaDataSection then
			dividerLineIndex = AddSectionLabel(self, L["Metadata"], dividerLineIndex)
			addedMetaDataSection = true
		end
		local oldDungeonInstance = bossUtilities.FindDungeonInstance(diffs.metaData.instanceID.oldValue)
		local newDungeonInstance = bossUtilities.FindDungeonInstance(diffs.metaData.instanceID.newValue)
		if oldDungeonInstance and newDungeonInstance then
			local oldText = format("%s: %s", L["Instance"], oldDungeonInstance.name)
			local newText = format("%s: %s", L["Instance"], newDungeonInstance.name)
			local entry = AceGUI:Create("EPDiffViewerEntry")
			entry:SetFullWidth(true)
			entry:SetMetaDataEntryData(oldText, newText)
			entry:SetCallback("OnValueChanged", function(_, _, checked)
				self.planDiff.metaData.instanceID.result = checked
			end)
			self.mainContainer:AddChild(entry)

			if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
			elseif entry.valueLabelTwo then
				if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
					entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
				end
			end
		end
	end
	if diffs.metaData.dungeonEncounterID then
		if not addedMetaDataSection then
			dividerLineIndex = AddSectionLabel(self, L["Metadata"], dividerLineIndex)
			addedMetaDataSection = true
		end
		local oldBoss = bossUtilities.GetBoss(diffs.metaData.dungeonEncounterID.oldValue)
		local newBoss = bossUtilities.GetBoss(diffs.metaData.dungeonEncounterID.newValue)
		local oldText = format("%s: %s", L["Boss"], oldBoss.name)
		local newText = format("%s: %s", L["Boss"], newBoss.name)
		local entry = AceGUI:Create("EPDiffViewerEntry")
		entry:SetFullWidth(true)
		entry:SetMetaDataEntryData(oldText, newText)
		entry:SetCallback("OnValueChanged", function(_, _, checked)
			self.planDiff.metaData.dungeonEncounterID.result = checked
		end)
		self.mainContainer:AddChild(entry)

		if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
			entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
		elseif entry.valueLabelTwo then
			if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
			end
		end
	end
	if diffs.metaData.difficulty then
		if not addedMetaDataSection then
			dividerLineIndex = AddSectionLabel(self, L["Metadata"], dividerLineIndex)
			addedMetaDataSection = true
		end
		local oldText = format(
			"%s: %s",
			L["Difficulty"],
			diffs.metaData.difficulty.oldValue == DifficultyType.Heroic and L["Heroic"] or L["Mythic"]
		)
		local newText = format(
			"%s: %s",
			L["Difficulty"],
			diffs.metaData.difficulty.newValue == DifficultyType.Heroic and L["Heroic"] or L["Mythic"]
		)
		local entry = AceGUI:Create("EPDiffViewerEntry")
		entry:SetFullWidth(true)
		entry:SetMetaDataEntryData(oldText, newText)
		entry:SetCallback("OnValueChanged", function(_, _, checked)
			self.planDiff.metaData.difficulty.result = checked
		end)
		self.mainContainer:AddChild(entry)

		if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
			entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
		elseif entry.valueLabelTwo then
			if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
			end
		end
	end

	for index, diff in ipairs(diffs.assignments) do
		if diff.type ~= PlanDiffType.Equal then
			if not addedAssignmentSection then
				dividerLineIndex = AddSectionLabel(self, L["Assignments"], dividerLineIndex)
				addedAssignmentSection = true
			end

			local oldValue, newValue
			if diff.type == PlanDiffType.Insert then
				oldValue = diff.value
			elseif diff.type == PlanDiffType.Delete then
				oldValue = diff.value
			elseif diff.type == PlanDiffType.Change then
				oldValue = diff.oldValue
				newValue = diff.newValue
			end
			local entry = AceGUI:Create("EPDiffViewerEntry")
			entry:SetFullWidth(true)
			entry:SetAssignmentEntryData(oldValue, newValue, oldPlan.roster, newPlan.roster, diff.type)
			entry:SetCallback("OnValueChanged", function(_, _, checked)
				self.planDiff.assignments[index].result = checked
			end)

			self.mainContainer:AddChild(entry)

			if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
			elseif entry.valueLabelTwo then
				if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
					entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
				end
			end
		end
	end

	for index, planTemplateDiff in ipairs(diffs.assigneesAndSpells) do
		if planTemplateDiff.type ~= PlanDiffType.Equal then
			if not addedAssigneeSpellSetsSection then
				dividerLineIndex = AddSectionLabel(self, L["Templates"], dividerLineIndex)
				addedAssigneeSpellSetsSection = true
			end

			local oldValue, newValue
			if planTemplateDiff.type == PlanDiffType.Insert then
				oldValue = planTemplateDiff.value
			elseif planTemplateDiff.type == PlanDiffType.Delete then
				oldValue = planTemplateDiff.value
			elseif planTemplateDiff.type == PlanDiffType.Change then
				oldValue = planTemplateDiff.oldValue
				newValue = planTemplateDiff.newValue
			end
			local entry = AceGUI:Create("EPDiffViewerEntry")
			entry:SetFullWidth(true)
			entry:SetAssigneeSpellSetEntryData(
				oldValue,
				newValue,
				oldPlan.roster,
				newPlan.roster,
				planTemplateDiff.type
			)
			entry:SetCallback("OnValueChanged", function(_, _, checked)
				self.planDiff.assigneesAndSpells[index].result = checked
			end)

			self.mainContainer:AddChild(entry)

			if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
			elseif entry.valueLabelTwo then
				if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
					entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
				end
			end
		end
	end

	for index, planRosterDiff in ipairs(diffs.roster) do
		if not addedRosterSection then
			dividerLineIndex = AddSectionLabel(self, L["Roster"], dividerLineIndex)
			addedRosterSection = true
		end
		local entry = AceGUI:Create("EPDiffViewerEntry")
		entry:SetFullWidth(true)
		entry:SetRosterEntryData(planRosterDiff, oldPlan.roster, newPlan.roster)
		entry:SetCallback("OnValueChanged", function(_, _, checked)
			self.planDiff.roster[index].result = checked
		end)
		self.mainContainer:AddChild(entry)

		if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
			entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
		elseif entry.valueLabelTwo then
			if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
			end
		end
	end

	for index, contentDiffEntry in ipairs(diffs.content) do
		if contentDiffEntry.type ~= PlanDiffType.Equal then
			if not addedContentSection then
				dividerLineIndex = AddSectionLabel(self, L["External Text"], dividerLineIndex)
				addedContentSection = true
			end

			local entry = AceGUI:Create("EPDiffViewerEntry")
			entry:SetFullWidth(true)
			if contentDiffEntry.type == PlanDiffType.Insert then
				entry:SetContentEntryData(PlanDiffType.Insert, contentDiffEntry.value)
			elseif contentDiffEntry.type == PlanDiffType.Delete then
				entry:SetContentEntryData(PlanDiffType.Delete, contentDiffEntry.value)
			elseif contentDiffEntry.type == PlanDiffType.Change then
				entry:SetContentEntryData(PlanDiffType.Change, contentDiffEntry.oldValue, contentDiffEntry.newValue)
			end
			entry:SetCallback("OnValueChanged", function(_, _, checked)
				self.planDiff.content[index].result = checked
			end)
			self.mainContainer:AddChild(entry)

			if entry.valueLabel.text:GetStringHeight() > entry.valueLabel.frame:GetHeight() then
				entry.frame:SetHeight(entry.valueLabel.text:GetStringHeight() + 10)
			elseif entry.valueLabelTwo then
				if entry.valueLabelTwo.text:GetStringHeight() > entry.valueLabelTwo.frame:GetHeight() then
					entry.frame:SetHeight(entry.valueLabelTwo.text:GetStringHeight() + 10)
				end
			end
		end
	end

	self.mainContainer:DoLayout()
	self.buttonContainer:DoLayout()
	self.scrollFrame:UpdateVerticalScroll()
	self.scrollFrame:UpdateThumbPositionAndSize()

	local maxTypeWidth = 0
	for _, child in ipairs(self.mainContainer.children) do
		if child.type == "EPDiffViewerEntry" then
			---@cast child EPDiffViewerEntry
			maxTypeWidth = max(maxTypeWidth, child.typeLabel.frame:GetWidth())
		end
	end
	for _, child in ipairs(self.mainContainer.children) do
		if child.type == "EPDiffViewerEntry" then
			---@cast child EPDiffViewerEntry
			child.typeLabel.frame:SetWidth(maxTypeWidth)
		end
	end

	while self.dividerLines[dividerLineIndex] do
		self.dividerLines[dividerLineIndex]:ClearAllPoints()
		self.dividerLines[dividerLineIndex]:Hide()
		dividerLineIndex = dividerLineIndex + 1
	end
end

---@param self EPDiffViewer
---@param text string
local function SetText(self, text)
	self.text:SetText(text)
end

---@param self EPDiffViewer
---@param text string
---@param beforeWidget AceGUIWidget|nil
local function AddButton(self, text, beforeWidget)
	local button = AceGUI:Create("EPButton")
	button:SetText(text)
	button:SetWidthFromText()
	button:SetHeight(k.DefaultButtonHeight)
	button:SetColor(unpack(k.NeutralButtonColor))
	button:SetCallback("Clicked", function()
		self:Fire(text .. "Clicked")
	end)
	if beforeWidget then
		self.buttonContainer:InsertChildren(beforeWidget, button)
	else
		self.buttonContainer:AddChild(button)
	end
	SetButtonWidths(self.buttonContainer)
	self.buttonContainer:DoLayout()
	local currentContentWidth = self.frame:GetWidth() - 2 * k.ContentFramePadding.x
	if self.buttonContainer.frame:GetWidth() > currentContentWidth then
		self.frame:SetWidth(self.buttonContainer.frame:GetWidth() + 2 * k.ContentFramePadding.x)
		self.text:SetWidth(self.frame:GetWidth() - 2 * k.ContentFramePadding.x)
		self.mainContainer:DoLayout()
		self.scrollFrame:UpdateVerticalScroll()
		self.scrollFrame:UpdateThumbPositionAndSize()
	end
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(k.FrameBackdrop)
	frame:SetBackdropColor(unpack(k.BackdropColor))
	frame:SetBackdropBorderColor(unpack(k.BackdropBorderColor))
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetWordWrap(true)
	text:SetSpacing(4)
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		text:SetFont(fPath, k.DefaultFontSize)
	end

	---@class EPDiffViewer : AceGUIWidget
	---@field frame table|Frame|BackdropTemplate
	---@field mainContainer EPContainer
	---@field scrollFrame EPScrollFrame
	---@field buttonContainer EPContainer
	---@field selectAllButton EPButton
	---@field type string
	---@field planDiff PlanDiff
	---@field windowBar EPWindowBar
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		AddDiffs = AddDiffs,
		AddButton = AddButton,
		SetText = SetText,
		frame = frame,
		type = Type,
		dividerLines = {},
		text = text,
		isCommunicationsMessage = true,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
