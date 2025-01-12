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

local defaultFrameWidth = 400
local defaultFrameHeight = 400
local minFrameWidth = 400
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
	for i = 2, #self.activeContainer.children do
		local child = self.activeContainer.children[i]
		if child.type == "EPContainer" then
			local containerChildren = child.children
			if #containerChildren == 3 then
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

	local labelContainer = AceGUI:Create("EPContainer")
	labelContainer:SetLayout("EPHorizontalLayout")
	labelContainer:SetSpacing(16, 0)
	labelContainer:SetFullWidth(true)

	local phaseNameLabel = AceGUI:Create("EPLabel")
	phaseNameLabel:SetText("Phase")
	phaseNameLabel:SetRelativeWidth(0.3)
	phaseNameLabel.text:SetTextColor(unpack(headingColor))

	local defaultDurationLabel = AceGUI:Create("EPLabel")
	defaultDurationLabel:SetText("Default Duration")
	defaultDurationLabel:SetHorizontalTextAlignment("CENTER")
	defaultDurationLabel:SetRelativeWidth(0.3)
	defaultDurationLabel.text:SetTextColor(unpack(headingColor))

	local durationLabel = AceGUI:Create("EPLabel")
	durationLabel:SetText("Custom Duration")
	durationLabel:SetHorizontalTextAlignment("CENTER")
	durationLabel:SetRelativeWidth(0.4)
	durationLabel.text:SetTextColor(unpack(headingColor))

	self.resetAllButton = AceGUI:Create("EPButton")
	self.resetAllButton.frame:SetParent(self.frame)
	self.resetAllButton.frame:SetPoint("BOTTOM", 0, contentFramePadding.y)
	self.resetAllButton:SetText("Reset All to Default")
	self.resetAllButton:SetWidthFromText()
	self.resetAllButton:SetCallback("Clicked", function()
		ResetToDefault(self)
		self:Fire("ResetAllButtonClicked")
	end)

	labelContainer:AddChildren(phaseNameLabel, defaultDurationLabel, durationLabel)
	self.activeContainer:AddChildren(labelContainer)

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
end

---@param self EPPhaseLengthEditor
---@param entries table<integer, {name:string, defaultDuration: number, fixedDuration: boolean|nil, duration:number}>>
local function AddEntries(self, entries)
	local containers = {}
	for _, phase in ipairs(entries) do
		local container = AceGUI:Create("EPContainer")
		container:SetLayout("EPHorizontalLayout")
		container:SetSpacing(16, 0)
		container:SetFullWidth(true)

		local label = AceGUI:Create("EPLabel")
		label:SetText(phase.name)
		label:SetRelativeWidth(0.3)

		local defaultContainer = AceGUI:Create("EPContainer")
		defaultContainer:SetLayout("EPHorizontalLayout")
		defaultContainer:SetSpacing(0, 0)
		defaultContainer:SetRelativeWidth(0.3)

		local defaultMinutes, defaultSeconds = self.FormatTime(phase.defaultDuration)
		local defaultText = format("%s:%s", defaultMinutes, defaultSeconds)

		local defaultLabel = AceGUI:Create("EPLabel")
		defaultLabel:SetText(defaultText)
		defaultLabel:SetHorizontalTextAlignment("CENTER")
		defaultLabel:SetFullWidth(true)

		local minutes, seconds = self.FormatTime(phase.duration)

		local currentContainer = AceGUI:Create("EPContainer")
		currentContainer:SetLayout("EPHorizontalLayout")
		currentContainer:SetSpacing(0, 0)
		currentContainer:SetRelativeWidth(0.4)

		local minuteLineEdit = AceGUI:Create("EPLineEdit")
		local secondLineEdit = AceGUI:Create("EPLineEdit")

		minuteLineEdit:SetText(minutes)
		minuteLineEdit:SetRelativeWidth(0.475)
		minuteLineEdit:SetEnabled(not phase.fixedDuration)
		minuteLineEdit:SetCallback("OnTextSubmitted", function(widget, ...)
			self:Fire("DataChanged", phase.name, widget, secondLineEdit)
		end)

		local separatorLabel = AceGUI:Create("EPLabel")
		separatorLabel:SetText(":")
		separatorLabel:SetHorizontalTextAlignment("CENTER")
		separatorLabel:SetRelativeWidth(0.05)

		secondLineEdit:SetText(seconds)
		secondLineEdit:SetRelativeWidth(0.475)
		secondLineEdit:SetEnabled(not phase.fixedDuration)
		secondLineEdit:SetCallback("OnTextSubmitted", function(widget, _, text)
			self:Fire("DataChanged", phase.name, minuteLineEdit, widget)
		end)

		defaultContainer:AddChildren(defaultLabel)
		currentContainer:AddChildren(minuteLineEdit, separatorLabel, secondLineEdit)
		container:AddChildren(label, defaultContainer, currentContainer)
		tinsert(containers, container)
	end
	self.activeContainer:AddChildren(unpack(containers))
end

---@param self EPPhaseLengthEditor
local function Resize(self)
	local height = contentFramePadding.y
		+ self.windowBar:GetHeight()
		+ self.activeContainer.frame:GetHeight()
		+ otherPadding.y
		+ self.resetAllButton.frame:GetHeight()
		+ contentFramePadding.y
	self.frame:SetSize(minFrameWidth, height)
	self.activeContainer:DoLayout()
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
	windowBarText:SetText("Phase Timing Editor")
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
		frame = frame,
		type = Type,
		windowBar = windowBar,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
