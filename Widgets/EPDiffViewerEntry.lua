local Type = "EPDiffViewerEntry"
local Version = 1

local _, Namespace = ...

---@class Private
local Private = Namespace
local L = Private.L

---@class Utilities
local utilities = Private.utilities

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame
local format = string.format
local getmetatable = getmetatable
local GetSpellName = C_Spell.GetSpellName
local max = math.max
local unpack = unpack

local PlanDiffType = Private.classes.PlanDiffType
local CombatLogEventAssignment = Private.classes.CombatLogEventAssignment

local k = {
	DefaultHeight = 10,
	DefaultWidth = 10,
	LineColor = { 0.25, 0.25, 0.25, 1.0 },
}

---@param eventType CombatLogEventType
---@return string
local function GetCombatLogEventString(eventType)
	local returnString
	if eventType == "SCC" then
		returnString = L["Spell Cast Success"]
	elseif eventType == "SCS" then
		returnString = L["Spell Cast Start"]
	elseif eventType == "SAA" then
		returnString = L["Spell Aura Applied"]
	elseif eventType == "SAR" then
		returnString = L["Spell Aura Removed"]
	elseif eventType == "UD" then
		returnString = L["Unit Died"]
	end
	return returnString
end

---@param value Assignment|CombatLogEventAssignment|TimedAssignment
---@param roster table<string, RosterEntry>
---@param diffType? PlanDiffType
---@return string
local function CreateAssignmentDiffText(value, roster, diffType)
	local text = ""
	if diffType then
		if diffType == PlanDiffType.Delete then
			return L["Removed"]
		elseif diffType == PlanDiffType.Change then
			text = L["Changed"] .. "\n"
		end
	end
	local assignee = utilities.ConvertAssigneeToLegibleString(value.assignee, roster)
	text = text .. format("%s: %s", L["Assignee"], assignee)
	if value.spellID > Private.constants.kTextAssignmentSpellID then
		local spellName = GetSpellName(value.spellID)
		if spellName then
			text = text .. format("\n%s: %s", L["Spell"], spellName)
		else
			text = text .. format("\n%s: %s", L["Spell"], value.spellID)
		end
	end
	text = text .. format("\n%s: %s", L["Time"], value.time)
	text = text .. format("\n%s: %s", L["Text"], value.text)
	if value.targetName ~= "" then
		local targetName = utilities.ConvertAssigneeToLegibleString(value.targetName, roster)
		text = text .. format("\n%s: %s", L["Target"], targetName)
	end
	if getmetatable(value) == CombatLogEventAssignment then
		text = text .. format("\n%s: %s", L["Trigger"], GetCombatLogEventString(value.combatLogEventType))
		text = text .. format("\n%s %s: %s", L["Trigger"], L["Spell"], GetSpellName(value.combatLogEventSpellID))
		text = text .. format("\n%s %s: %s", L["Trigger"], L["Spell Count"], value.spellCount)
	end
	return text
end

---@param value FlatAssigneeSpellSet
---@param roster table<string, RosterEntry>
---@return string
local function CreateFlatAssigneeSpellSetDiffText(value, roster)
	local assignee = utilities.ConvertAssigneeToLegibleString(value.assignee, roster)
	local text = format("%s: %s", L["Assignee"], assignee)
	local spellName = tostring(value.spellID)
	if value.spellID == Private.constants.kInvalidAssignmentSpellID then
		spellName = L["Unknown"]
	elseif value.spellID == Private.constants.kTextAssignmentSpellID then
		spellName = L["Text"]
	else
		local maybeSpellName = GetSpellName(value.spellID)
		if maybeSpellName then
			spellName = maybeSpellName
		end
	end
	text = text .. format("\n%s: %s", L["Spell"], spellName)
	return text
end

---@param assignee string
---@param class string
---@param role RaidGroupRole
---@param roster table<string, RosterEntry>
---@return string
local function CreateRosterDiffText(assignee, class, role, roster)
	local assigneeLegible = utilities.ConvertAssigneeToLegibleString(assignee, roster)
	local text = format("%s: %s", L["Assignee"], assigneeLegible)
	local className = class:match("class:%s*(%a+)")
	if className then
		className = utilities.GetLocalizedPrettyClassName(className)
		text = text .. format("\n%s: %s", L["Class"], className)
	end
	local roleName = role:match("role:%s*(%a+)")
	if roleName then
		roleName = utilities.GetLocalizedRole(roleName)
		text = text .. format("\n%s: %s", L["Role"], roleName)
	end
	return text
end

---@param self EPDiffViewerEntry
local function OnAcquire(self)
	self.frame:SetParent(UIParent)
	self.frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local typeLabel = AceGUI:Create("EPMultiLineText")
	typeLabel:SetText("Type")
	typeLabel.frame:SetParent(self.frame)
	typeLabel.frame:SetPoint("LEFT", 0, -1)
	self.typeLabel = typeLabel

	self.typeDividerLine:SetPoint("LEFT", typeLabel.frame, "RIGHT")
	self.typeDividerLine:SetPoint("TOP", self.frame, "TOP")
	self.typeDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")

	local checkBox = AceGUI:Create("EPCheckBox")
	checkBox:SetText("")
	checkBox:SetFrameWidthFromText()
	checkBox.frame:SetParent(self.frame)
	checkBox.frame:SetPoint("RIGHT", 0, -1)
	checkBox:SetChecked(true)
	checkBox:SetCallback("OnValueChanged", function(_, _, checked)
		self:Fire("OnValueChanged", checked)
	end)

	self.checkBox = checkBox

	self.checkBoxDividerLine:SetPoint("RIGHT", checkBox.frame, "LEFT", -6, 0)
	self.checkBoxDividerLine:SetPoint("TOP", self.frame, "TOP")
	self.checkBoxDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")

	self.frame:Show()
end

---@param self EPDiffViewerEntry
local function OnRelease(self)
	self.typeLabel:Release()
	self.typeLabel = nil

	self.checkBox:Release()
	self.checkBox = nil

	self.typeDividerLine:ClearAllPoints()
	self.checkBoxDividerLine:ClearAllPoints()
	self.diffDividerLine:ClearAllPoints()

	self.valueLabel:Release()
	self.valueLabel = nil

	if self.valueLabelTwo then
		self.valueLabelTwo:Release()
	end
	self.valueLabelTwo = nil
end

---@param self EPDiffViewerEntry
---@param oldValue Assignment|CombatLogEventAssignment|TimedAssignment
---@param newValue? Assignment|CombatLogEventAssignment|TimedAssignment
---@param oldRoster table<string, RosterEntry>
---@param newRoster table<string, RosterEntry>
---@param diff GenericDiffEntry
local function SetAssignmentEntryData(self, oldValue, newValue, oldRoster, newRoster, diff)
	if not oldValue then
		return
	end

	local diffType = diff.type
	local typeText = ""
	if diffType == PlanDiffType.Insert then
		typeText = L["Added"]
	elseif diffType == PlanDiffType.Delete then
		typeText = L["Removed"]
	elseif diffType == PlanDiffType.Change then
		typeText = L["Changed"]
	elseif diffType == PlanDiffType.Conflict then
		---@cast diff ConflictDiffEntry<Assignment|CombatLogEventAssignment|TimedAssignment>
		typeText = L["Conflict"]
	end
	self.typeLabel:SetText(typeText)

	local oldValueLabel = AceGUI:Create("EPMultiLineText")
	oldValueLabel.frame:SetParent(self.frame)
	oldValueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	oldValueLabel:SetFullHeight(true)
	oldValueLabel:SetText(CreateAssignmentDiffText(oldValue, oldRoster, diff.localType))
	self.valueLabel = oldValueLabel

	local maxLabelHeight = max(oldValueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	if newValue then
		self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
		self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
		self.diffDividerLine:Show()

		oldValueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

		local newValueLabel = AceGUI:Create("EPMultiLineText")
		newValueLabel.frame:SetParent(self.frame)
		newValueLabel.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
		newValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		newValueLabel:SetFullHeight(true)
		newValueLabel:SetText(CreateAssignmentDiffText(newValue, newRoster, diff.remoteType))
		self.valueLabelTwo = newValueLabel

		maxLabelHeight = max(maxLabelHeight, newValueLabel.frame:GetHeight())
	else
		oldValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		self.diffDividerLine:Hide()
	end

	self.frame:SetHeight(maxLabelHeight)
end

---@param self EPDiffViewerEntry
---@param oldValue FlatAssigneeSpellSet
---@param newValue? FlatAssigneeSpellSet
---@param oldRoster table<string, RosterEntry>
---@param newRoster table<string, RosterEntry>
---@param diffType PlanDiffType
local function SetAssigneeSpellSetEntryData(self, oldValue, newValue, oldRoster, newRoster, diffType)
	if not oldValue then
		return
	end

	local typeText = ""
	if diffType == PlanDiffType.Insert then
		typeText = L["Added"]
	elseif diffType == PlanDiffType.Delete then
		typeText = L["Removed"]
	elseif diffType == PlanDiffType.Change then
		typeText = L["Changed"]
	elseif diffType == PlanDiffType.Conflict then
		typeText = L["Conflict"]
	end
	self.typeLabel:SetText(typeText)

	local oldValueLabel = AceGUI:Create("EPMultiLineText")
	oldValueLabel.frame:SetParent(self.frame)
	oldValueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	oldValueLabel:SetFullHeight(true)
	oldValueLabel:SetText(CreateFlatAssigneeSpellSetDiffText(oldValue, oldRoster))
	self.valueLabel = oldValueLabel

	local maxLabelHeight = max(oldValueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	if newValue then
		self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
		self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
		self.diffDividerLine:Show()

		oldValueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

		local newValueLabel = AceGUI:Create("EPMultiLineText")
		newValueLabel.frame:SetParent(self.frame)
		newValueLabel.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
		newValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		newValueLabel:SetFullHeight(true)
		newValueLabel:SetText(CreateFlatAssigneeSpellSetDiffText(newValue, newRoster))
		self.valueLabelTwo = newValueLabel

		maxLabelHeight = max(maxLabelHeight, newValueLabel.frame:GetHeight())
	else
		oldValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		self.diffDividerLine:Hide()
	end

	self.frame:SetHeight(maxLabelHeight)
end

---@param self EPDiffViewerEntry
---@param planRosterDiff GenericDiffEntry
---@param oldRoster table<string, RosterEntry>
---@param newRoster table<string, RosterEntry>
local function SetRosterEntryData(self, planRosterDiff, oldRoster, newRoster)
	local typeText = ""
	local labelText, labelTwoText
	if planRosterDiff.type == PlanDiffType.Insert then
		---@cast planRosterDiff InsertDiffEntry<RosterEntry>
		typeText = L["Added"]
		labelText = CreateRosterDiffText(
			planRosterDiff.ID,
			planRosterDiff.newValue.class,
			planRosterDiff.newValue.role,
			newRoster
		)
	elseif planRosterDiff.type == PlanDiffType.Delete then
		---@cast planRosterDiff DeleteDiffEntry<RosterEntry>
		typeText = L["Removed"]
		labelText = CreateRosterDiffText(
			planRosterDiff.ID,
			planRosterDiff.oldValue.class,
			planRosterDiff.oldValue.role,
			oldRoster
		)
	elseif planRosterDiff.type == PlanDiffType.Change then
		---@cast planRosterDiff ChangeDiffEntry<RosterEntry>
		typeText = L["Changed"]
		labelText = CreateRosterDiffText(
			planRosterDiff.ID,
			planRosterDiff.oldValue.class,
			planRosterDiff.oldValue.role,
			oldRoster
		)
		labelTwoText = CreateRosterDiffText(
			planRosterDiff.ID,
			planRosterDiff.newValue.class,
			planRosterDiff.newValue.role,
			newRoster
		)
	elseif planRosterDiff.type == PlanDiffType.Conflict then
		---@cast planRosterDiff ConflictDiffEntry<RosterEntry>
		typeText = L["Conflict"]
		labelText = CreateRosterDiffText(
			planRosterDiff.ID,
			planRosterDiff.localValue.class,
			planRosterDiff.localValue.role,
			oldRoster
		)
		labelTwoText = CreateRosterDiffText(
			planRosterDiff.ID,
			planRosterDiff.remoteValue.class,
			planRosterDiff.remoteValue.role,
			newRoster
		)
	end
	self.typeLabel:SetText(typeText)

	local valueLabel = AceGUI:Create("EPMultiLineText")
	valueLabel.frame:SetParent(self.frame)
	valueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT")
	valueLabel:SetFullHeight(true)
	valueLabel:SetText(labelText)
	self.valueLabel = valueLabel

	local maxLabelHeight = max(valueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	if labelTwoText then
		self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
		self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
		self.diffDividerLine:Show()

		valueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

		local valueLabelTwo = AceGUI:Create("EPMultiLineText")
		valueLabelTwo.frame:SetParent(self.frame)
		valueLabelTwo.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
		valueLabelTwo.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		valueLabelTwo:SetFullHeight(true)
		valueLabelTwo:SetText(labelTwoText)
		self.valueLabelTwo = valueLabelTwo

		maxLabelHeight = max(maxLabelHeight, valueLabelTwo.frame:GetHeight())
	else
		valueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		self.diffDividerLine:Hide()
	end

	self.frame:SetHeight(maxLabelHeight)
end

---@param self EPDiffViewerEntry
---@param diffType PlanDiffType
---@param textOne string
---@param textTwo? string
local function SetContentEntryData(self, diffType, textOne, textTwo)
	local typeText = ""
	if diffType == PlanDiffType.Insert then
		typeText = L["Added"]
	elseif diffType == PlanDiffType.Delete then
		typeText = L["Removed"]
	elseif diffType == PlanDiffType.Change then
		typeText = L["Changed"]
	end
	self.typeLabel:SetText(typeText)

	local valueLabel = AceGUI:Create("EPMultiLineText")
	valueLabel.frame:SetParent(self.frame)
	valueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	valueLabel:SetFullHeight(true)
	valueLabel:SetText(textOne)

	self.valueLabel = valueLabel

	local maxLabelHeight = max(valueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	if textTwo then
		self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
		self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
		self.diffDividerLine:Show()

		valueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

		local valueLabelTwo = AceGUI:Create("EPMultiLineText")
		valueLabelTwo.frame:SetParent(self.frame)
		valueLabelTwo.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
		valueLabelTwo.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		valueLabelTwo:SetFullHeight(true)
		valueLabelTwo:SetText(textTwo)
		self.valueLabelTwo = valueLabelTwo

		maxLabelHeight = max(maxLabelHeight, valueLabelTwo.frame:GetHeight())
	else
		valueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
		self.diffDividerLine:Hide()
	end

	self.frame:SetHeight(maxLabelHeight)
end

---@param self EPDiffViewerEntry
---@param oldText string
---@param newText string
local function SetMetaDataEntryData(self, oldText, newText)
	self.typeLabel:SetText(L["Changed"])

	local oldValueLabel = AceGUI:Create("EPMultiLineText")
	oldValueLabel.frame:SetParent(self.frame)
	oldValueLabel.frame:SetPoint("LEFT", self.typeDividerLine, "RIGHT", 0, -1)
	oldValueLabel:SetFullHeight(true)
	oldValueLabel:SetText(oldText)
	self.valueLabel = oldValueLabel

	local maxLabelHeight = max(oldValueLabel.frame:GetHeight(), self.checkBox.frame:GetHeight() + 12)

	self.diffDividerLine:SetPoint("TOP", self.frame, "TOP")
	self.diffDividerLine:SetPoint("BOTTOM", self.frame, "BOTTOM")
	self.diffDividerLine:Show()

	oldValueLabel.frame:SetPoint("RIGHT", self.diffDividerLine, "LEFT", 0, -1)

	local newValueLabel = AceGUI:Create("EPMultiLineText")
	newValueLabel.frame:SetParent(self.frame)
	newValueLabel.frame:SetPoint("LEFT", self.diffDividerLine, "RIGHT", 0, -1)
	newValueLabel.frame:SetPoint("RIGHT", self.checkBoxDividerLine, "LEFT", 0, -1)
	newValueLabel:SetFullHeight(true)
	newValueLabel:SetText(newText)
	self.valueLabelTwo = newValueLabel

	maxLabelHeight = max(maxLabelHeight, newValueLabel.frame:GetHeight())

	self.frame:SetHeight(maxLabelHeight)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultWidth, k.DefaultHeight)

	local bottomLine = frame:CreateTexture(nil, "OVERLAY")
	bottomLine:SetColorTexture(unpack(k.LineColor))
	bottomLine:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
	bottomLine:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT")
	bottomLine:SetHeight(2)

	local typeDividerLine = frame:CreateTexture(nil, "OVERLAY")
	typeDividerLine:SetColorTexture(unpack(k.LineColor))
	typeDividerLine:SetWidth(2)

	local checkBoxDividerLine = frame:CreateTexture(nil, "OVERLAY")
	checkBoxDividerLine:SetColorTexture(unpack(k.LineColor))
	checkBoxDividerLine:SetWidth(2)

	local diffDividerLine = frame:CreateTexture(nil, "OVERLAY")
	diffDividerLine:SetColorTexture(unpack(k.LineColor))
	diffDividerLine:SetWidth(2)

	---@class EPDiffViewerEntry : AceGUIWidget
	---@field diffContainer EPMultiLineText
	---@field diffContainerTwo EPMultiLineText
	---@field checkBox EPCheckBox
	---@field typeLabel EPMultiLineText
	---@field valueLabel EPMultiLineText
	---@field valueLabelTwo EPMultiLineText
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetAssignmentEntryData = SetAssignmentEntryData,
		SetRosterEntryData = SetRosterEntryData,
		SetMetaDataEntryData = SetMetaDataEntryData,
		SetContentEntryData = SetContentEntryData,
		SetAssigneeSpellSetEntryData = SetAssigneeSpellSetEntryData,
		frame = frame,
		type = Type,
		count = count,
		typeDividerLine = typeDividerLine,
		checkBoxDividerLine = checkBoxDividerLine,
		diffDividerLine = diffDividerLine,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
