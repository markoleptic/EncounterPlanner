local _, Namespace = ...
local L = Namespace.L

local Type = "EPPhaseLengthEditor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local CreateFrame = CreateFrame
local format = format
local ipairs = ipairs
local tinsert = tinsert
local tostring = tostring
local unpack = unpack

local defaultFrameWidth = 600
local defaultFrameHeight = 400
local relWidths = {}
local windowBarHeight = 28
local contentFramePadding = { x = 15, y = 15 }
local otherPadding = { x = 10, y = 10 }
local backdropColor = { 0, 0, 0, 1 }
local backdropBorderColor = { 0.25, 0.25, 0.25, 1 }
local closeButtonBackdropColor = { 0, 0, 0, 0.9 }
local headingColor = { 1, 0.82, 0, 1 }
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

---@param self EPPhaseLengthEditor
local function ResetToDefault(self)
	for i = 2, #self.activeContainer.children - 1 do
		local child = self.activeContainer.children[i]
		if child.type == "EPContainer" then
			local containerChildren = child.children
			if #containerChildren == 5 then
				local defaultContainer = containerChildren[2]
				local currentContainer = containerChildren[3]
				local defaultLabel = defaultContainer.children[1]
				local currentMinuteLineEdit = currentContainer.children[1]
				local currentSecondLineEdit = currentContainer.children[3]
				local text = defaultLabel:GetText()
				local minutes, seconds, decimal = text:match("^(%d+):(%d+)[%.]?(%d*)")
				if minutes and seconds then
					currentMinuteLineEdit:SetText(tostring(minutes))
					local formattedSeconds = format("%02d", seconds)
					if decimal and decimal ~= "0" and decimal ~= "" then
						formattedSeconds = formattedSeconds .. "." .. decimal
						currentSecondLineEdit:SetText(formattedSeconds)
					else
						currentSecondLineEdit:SetText(tostring(seconds))
					end
				end
				local defaultCountLabel = containerChildren[4]
				local countLineEdit = containerChildren[5]
				countLineEdit:SetText(defaultCountLabel:GetText())
			end
		end
	end
end

---@class EPPhaseLengthEditor : AceGUIWidget
---@field frame Frame|table
---@field type string
---@field windowBar table|Frame
---@field closeButton EPButton
---@field activeContainer EPContainer
---@field resetAllButton EPButton
---@field FormatTime fun(number): string,string

---@param self EPPhaseLengthEditor
local function OnAcquire(self)
	local edgeSize = frameBackdrop.edgeSize
	local buttonSize = windowBarHeight - 2 * edgeSize

	self.closeButton = AceGUI:Create("EPButton")
	self.closeButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.closeButton:SetIconPadding(2, 2)
	self.closeButton:SetWidth(buttonSize)
	self.closeButton:SetHeight(buttonSize)
	self.closeButton:SetBackdropColor(unpack(closeButtonBackdropColor))
	self.closeButton.frame:SetParent(self.windowBar)
	self.closeButton.frame:SetPoint("RIGHT", self.windowBar, "RIGHT", -edgeSize, 0)
	self.closeButton:SetCallback("Clicked", function()
		self:Fire("CloseButtonClicked")
	end)

	self.resetAllButton = AceGUI:Create("EPButton")
	self.resetAllButton.frame:SetParent(self.frame)
	self.resetAllButton.frame:SetPoint("BOTTOM", 0, contentFramePadding.y)
	self.resetAllButton:SetText(L["Reset All to Default"])
	self.resetAllButton:SetWidthFromText()
	self.resetAllButton:SetCallback("Clicked", function()
		ResetToDefault(self)
		self:Fire("ResetAllButtonClicked")
	end)

	self.activeContainer = AceGUI:Create("EPContainer")
	self.activeContainer:SetLayout("EPVerticalLayout")
	self.activeContainer:SetSpacing(0, 4)
	self.activeContainer:SetFullWidth(true)
	self.activeContainer.frame:EnableMouse(true)
	self.activeContainer.frame:SetParent(self.frame)
	self.activeContainer.frame:SetPoint(
		"TOPLEFT",
		self.windowBar,
		"BOTTOMLEFT",
		contentFramePadding.x,
		-contentFramePadding.y
	)
	self.activeContainer.frame:SetPoint("RIGHT", self.frame, "RIGHT", -contentFramePadding.x, 0)

	local labelsAndWidths = {}
	local phaseNameLabel = AceGUI:Create("EPLabel")
	phaseNameLabel:SetText(L["Intermission"] .. " 8 (100 Energy)", 0)
	phaseNameLabel:SetFrameWidthFromText()
	phaseNameLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { phaseNameLabel, phaseNameLabel.frame:GetWidth() })
	phaseNameLabel:SetText(L["Phase"], 0)
	phaseNameLabel:SetFrameWidthFromText()

	local defaultDurationLabel = AceGUI:Create("EPLabel")
	defaultDurationLabel:SetText(L["Default Duration"], 0)
	defaultDurationLabel:SetHorizontalTextAlignment("CENTER")
	defaultDurationLabel:SetFrameWidthFromText()
	defaultDurationLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { defaultDurationLabel, defaultDurationLabel.frame:GetWidth() })

	local durationLabel = AceGUI:Create("EPLabel")
	durationLabel:SetText(L["Custom Duration"], 0)
	durationLabel:SetHorizontalTextAlignment("CENTER")
	durationLabel:SetFrameWidthFromText()
	durationLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { durationLabel, durationLabel.frame:GetWidth() })

	local defaultCountLabel = AceGUI:Create("EPLabel")
	defaultCountLabel:SetText(L["Default Count"], 0)
	defaultCountLabel:SetHorizontalTextAlignment("CENTER")
	defaultCountLabel:SetFrameWidthFromText()
	defaultCountLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { defaultCountLabel, defaultCountLabel.frame:GetWidth() })

	local countLabel = AceGUI:Create("EPLabel")
	countLabel:SetText(L["Custom Count"], 0)
	countLabel:SetHorizontalTextAlignment("CENTER")
	countLabel:SetFrameWidthFromText()
	countLabel.text:SetTextColor(unpack(headingColor))
	tinsert(labelsAndWidths, { countLabel, countLabel.frame:GetWidth() })

	local totalWidth = 0.0
	for _, labelAndWidth in ipairs(labelsAndWidths) do
		totalWidth = totalWidth + labelAndWidth[2]
	end
	for i, labelAndWidth in ipairs(labelsAndWidths) do
		local relWidth = labelAndWidth[2] / totalWidth
		labelAndWidth[1]:SetRelativeWidth(relWidth)
		relWidths[i] = relWidth
	end

	local totalLabel = AceGUI:Create("EPLabel")
	totalLabel:SetText(L["Total"], 0)
	totalLabel.text:SetTextColor(unpack(headingColor))
	totalLabel:SetRelativeWidth(relWidths[1])

	local totalDefaultDurationLabel = AceGUI:Create("EPLabel")
	totalDefaultDurationLabel:SetText("0:00", 0)
	totalDefaultDurationLabel:SetHorizontalTextAlignment("CENTER")
	totalDefaultDurationLabel:SetRelativeWidth(relWidths[2])

	local totalCustomDurationLabel = AceGUI:Create("EPLabel")
	totalCustomDurationLabel:SetText("0:00", 0)
	totalCustomDurationLabel:SetHorizontalTextAlignment("CENTER")
	totalCustomDurationLabel:SetRelativeWidth(relWidths[3])

	local fourthSpacer = AceGUI:Create("EPSpacer")
	fourthSpacer:SetRelativeWidth(relWidths[4])

	local fifthSpacer = AceGUI:Create("EPSpacer")
	fifthSpacer:SetRelativeWidth(relWidths[5])

	local labelContainer = AceGUI:Create("EPContainer")
	labelContainer:SetLayout("EPHorizontalLayout")
	labelContainer:SetSpacing(10, 0)
	labelContainer:SetFullWidth(true)
	labelContainer:AddChildren(phaseNameLabel, defaultDurationLabel, durationLabel, defaultCountLabel, countLabel)

	local totalContainer = AceGUI:Create("EPContainer")
	totalContainer:SetLayout("EPHorizontalLayout")
	totalContainer:SetSpacing(10, 0)
	totalContainer:SetFullWidth(true)
	totalContainer:AddChildren(
		totalLabel,
		totalDefaultDurationLabel,
		totalCustomDurationLabel,
		fourthSpacer,
		fifthSpacer
	)

	self.activeContainer:AddChildren(labelContainer, totalContainer)

	self.frame:Show()
end

---@param self EPPhaseLengthEditor
local function OnRelease(self)
	self.closeButton:Release()
	self.closeButton = nil

	self.activeContainer.frame:EnableMouse(false)
	self.activeContainer:Release()
	self.activeContainer = nil

	self.resetAllButton:Release()
	self.resetAllButton = nil

	self.FormatTime = nil
	wipe(relWidths)
end

---@param self EPPhaseLengthEditor
---@param entries table<integer, BossPhase>>
local function AddEntries(self, entries)
	local containers = {}
	for index, phase in ipairs(entries) do
		local container = AceGUI:Create("EPContainer")
		container:SetLayout("EPHorizontalLayout")
		container:SetSpacing(10, 0)
		container:SetFullWidth(true)

		local label = AceGUI:Create("EPLabel")
		label:SetText(phase.name, 0)
		label:SetRelativeWidth(relWidths[1])

		local defaultContainer = AceGUI:Create("EPContainer")
		defaultContainer:SetLayout("EPHorizontalLayout")
		defaultContainer:SetSpacing(0, 0)
		defaultContainer:SetRelativeWidth(relWidths[2])
		local defaultMinutes, defaultSeconds = self.FormatTime(phase.defaultDuration)
		local defaultText = format("%s:%s", defaultMinutes, defaultSeconds)
		local defaultLabel = AceGUI:Create("EPLabel")
		defaultLabel:SetText(defaultText, 0)
		defaultLabel:SetHorizontalTextAlignment("CENTER")
		defaultLabel:SetFullWidth(true)

		local currentContainer = AceGUI:Create("EPContainer")
		currentContainer:SetLayout("EPHorizontalLayout")
		currentContainer:SetSpacing(0, 0)
		currentContainer:SetRelativeWidth(relWidths[3])
		local minuteLineEdit = AceGUI:Create("EPLineEdit")
		local secondLineEdit = AceGUI:Create("EPLineEdit")
		local minutes, seconds = self.FormatTime(phase.duration)
		minuteLineEdit:SetText(minutes)
		minuteLineEdit:SetRelativeWidth(0.475)
		minuteLineEdit:SetEnabled(not phase.fixedDuration)
		minuteLineEdit:SetCallback("OnTextSubmitted", function(widget, ...)
			self:Fire("DataChanged", index, widget, secondLineEdit)
		end)
		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":", 0)
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(0.05)
		secondLineEdit:SetText(seconds)
		secondLineEdit:SetRelativeWidth(0.475)
		secondLineEdit:SetEnabled(not phase.fixedDuration)
		secondLineEdit:SetCallback("OnTextSubmitted", function(widget, _, text)
			self:Fire("DataChanged", index, minuteLineEdit, widget)
		end)

		local defaultCountLabel = AceGUI:Create("EPLabel")
		defaultCountLabel:SetText(tostring(phase.defaultCount), 0)
		defaultCountLabel:SetHorizontalTextAlignment("CENTER")
		defaultCountLabel:SetRelativeWidth(relWidths[4])

		local countLineEdit = AceGUI:Create("EPLineEdit")
		countLineEdit:SetText(tostring(phase.count))
		countLineEdit:SetRelativeWidth(relWidths[5])
		countLineEdit:SetCallback("OnTextSubmitted", function(widget, _, text)
			self:Fire("CountChanged", index, text, widget)
		end)
		countLineEdit:SetEnabled(phase.repeatAfter ~= nil and not phase.fixedCount)

		defaultContainer:AddChildren(defaultLabel)
		currentContainer:AddChildren(minuteLineEdit, separatorLabel, secondLineEdit)
		container:AddChildren(label, defaultContainer, currentContainer, defaultCountLabel, countLineEdit)

		tinsert(containers, container)
	end

	self.activeContainer:InsertChildren(
		self.activeContainer.children[#self.activeContainer.children],
		unpack(containers)
	)
end

---@param self EPPhaseLengthEditor
---@param counts table<integer, integer>
local function SetPhaseCounts(self, counts)
	for i = 1, #counts do
		local child = self.activeContainer.children[i + 1]
		if child.type == "EPContainer" then
			local containerChildren = child.children
			if #containerChildren == 5 then
				local countLineEdit = containerChildren[5]
				countLineEdit:SetText(tostring(counts[i]))
			end
		end
	end
end

---@param self EPPhaseLengthEditor
---@param totalDefault string
---@param totalCustom string
local function SetTotalDurations(self, totalDefault, totalCustom)
	local child = self.activeContainer.children[#self.activeContainer.children]
	if child.type == "EPContainer" then
		local containerChildren = child.children
		if #containerChildren == 5 then
			local defaultTotalDurationLabel = containerChildren[2]
			defaultTotalDurationLabel:SetText(totalDefault, 0)
			local customTotalDurationLabel = containerChildren[3]
			customTotalDurationLabel:SetText(totalCustom, 0)
		end
	end
end

---@param self EPPhaseLengthEditor
local function Resize(self)
	local height = contentFramePadding.y
		+ self.windowBar:GetHeight()
		+ self.activeContainer.frame:GetHeight()
		+ otherPadding.y
		+ self.resetAllButton.frame:GetHeight()
		+ contentFramePadding.y
	self.frame:SetSize(defaultFrameWidth, height)
	self.activeContainer:DoLayout()
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(unpack(backdropColor))
	frame:SetBackdropBorderColor(unpack(backdropBorderColor))
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(unpack(backdropColor))
	windowBar:SetBackdropBorderColor(unpack(backdropBorderColor))
	windowBar:EnableMouse(true)
	local windowBarText = windowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(L["Phase Timing Editor"])
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
	---@class EPPhaseLengthEditor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		AddEntries = AddEntries,
		Resize = Resize,
		SetPhaseCounts = SetPhaseCounts,
		SetTotalDurations = SetTotalDurations,
		frame = frame,
		type = Type,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
