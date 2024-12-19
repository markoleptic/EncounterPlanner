local Type = "EPReminderAnchor"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local UIParent = UIParent
local CreateFrame = CreateFrame

local defaultFrameHeight = 30
local defaultFrameWidth = 400
local defaultText = "Assignment Text Here"
local frameBackdrop = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local oldFocus
local oldFocusName
local isChoosingFrame = false

local function recurseGetName(frame)
	local name = frame.GetName and frame:GetName() or nil
	if name then
		return name
	end
	local parent = frame.GetParent and frame:GetParent()
	if parent then
		for key, child in pairs(parent) do
			if child == frame then
				return (recurseGetName(parent) or "") .. "." .. key
			end
		end
	end
end

local function StopFrameChooser(frameChooserFrame, frameChooserBox)
	if frameChooserFrame then
		frameChooserFrame:SetScript("OnUpdate", nil)
		frameChooserBox:Hide()
	end
	ResetCursor()
	isChoosingFrame = false
end

local function StartFrameChooser(frameChooserFrame, frameChooserBox)
	isChoosingFrame = true
	frameChooserFrame:SetScript("OnUpdate", function()
		if IsMouseButtonDown("RightButton") then
		elseif IsMouseButtonDown("LeftButton") and oldFocusName then
			StopFrameChooser(frameChooserFrame, frameChooserBox)
		else
			SetCursor("CAST_CURSOR")
			local foci = GetMouseFoci()
			local focus = foci[1] or nil
			local focusName
			if focus then
				focusName = recurseGetName(focus)
				if focusName == "WorldFrame" or not focusName then
					focusName = nil
				end
				if focus ~= oldFocus then
					if focusName then
						frameChooserBox:ClearAllPoints()
						frameChooserBox:SetPoint("bottomleft", focus, "bottomleft", -4, -4)
						frameChooserBox:SetPoint("topright", focus, "topright", 4, 4)
						frameChooserBox:Show()
					end
					if focusName ~= oldFocusName then
						oldFocusName = focusName
					end
					oldFocus = focus
				end
			end
			if not focusName then
				frameChooserBox:Hide()
			end
		end
	end)
end

---@class EPReminderAnchor : AceGUIWidget
---@field frame table|Frame
---@field textFrame table|Frame
---@field type string
---@field assignmentText FontString
---@field alignCenterButton EPButton
---@field alignLeftButton EPButton
---@field alignRightButton EPButton
---@field increaseFontSizeButton EPButton
---@field decreaseFontSizeButton EPButton
---@field chooseAnchorButton EPButton
---@field chooseAnchorFrameButton EPButton

---@param self EPReminderAnchor
local function OnAcquire(self)
	self.assignmentText:SetText(defaultText)
	self.assignmentText:SetJustifyH("CENTER")

	self.frame:SetHeight(defaultFrameHeight)
	self.frame:SetWidth(defaultFrameWidth)

	self.alignLeftButton = AceGUI:Create("EPButton")
	self.alignLeftButton:SetText("Align Left")
	self.alignLeftButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignLeftButton:SetHeight(20)
	self.alignLeftButton:SetWidthFromText()
	self.alignLeftButton.frame:SetParent(self.frame)
	self.alignLeftButton.frame:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT")
	self.alignLeftButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("LEFT")
	end)

	self.alignCenterButton = AceGUI:Create("EPButton")
	self.alignCenterButton:SetText("Align Center")
	self.alignCenterButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignCenterButton:SetHeight(20)
	self.alignCenterButton:SetWidthFromText()
	self.alignCenterButton.frame:SetParent(self.frame)
	self.alignCenterButton.frame:SetPoint("LEFT", self.alignLeftButton.frame, "RIGHT")
	self.alignCenterButton:SetCallback("Clicked", function() end)

	self.alignRightButton = AceGUI:Create("EPButton")
	self.alignRightButton:SetText("Align Right")
	self.alignRightButton:SetBackdropColor(0, 0, 0, 0.9)
	self.alignRightButton:SetHeight(20)
	self.alignRightButton:SetWidthFromText()
	self.alignRightButton.frame:SetParent(self.frame)
	self.alignRightButton.frame:SetPoint("LEFT", self.alignCenterButton.frame, "RIGHT")
	self.alignRightButton:SetCallback("Clicked", function()
		self.assignmentText:SetJustifyH("RIGHT")
	end)

	self.increaseFontSizeButton = AceGUI:Create("EPButton")
	self.increaseFontSizeButton:SetText("+")
	self.increaseFontSizeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.increaseFontSizeButton.frame:SetParent(self.frame)
	self.increaseFontSizeButton.frame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT")
	self.increaseFontSizeButton.frame:SetPoint("BOTTOMLEFT", self.frame, "RIGHT")
	self.increaseFontSizeButton:SetWidth(self.frame:GetHeight() / 2.0)
	self.increaseFontSizeButton:SetCallback("Clicked", function()
		local font, size, flags = self.assignmentText:GetFont()
		if font then
			self.assignmentText:SetFont(font, math.min(48, size + 2), flags)
			self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
		end
	end)

	self.decreaseFontSizeButton = AceGUI:Create("EPButton")
	self.decreaseFontSizeButton:SetText("-")
	self.decreaseFontSizeButton:SetBackdropColor(0, 0, 0, 0.9)
	self.decreaseFontSizeButton.frame:SetParent(self.frame)
	self.decreaseFontSizeButton.frame:SetPoint("TOPRIGHT", self.increaseFontSizeButton.frame, "BOTTOMRIGHT")
	self.decreaseFontSizeButton.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT")
	self.decreaseFontSizeButton:SetCallback("Clicked", function()
		local font, size, flags = self.assignmentText:GetFont()
		if font then
			self.assignmentText:SetFont(font, math.max(10, size - 2), flags)
			self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
		end
	end)

	self.chooseAnchorButton = AceGUI:Create("EPButton")
	self.chooseAnchorButton:SetText("Choose Anchor")
	self.chooseAnchorButton:SetHeight(20)
	self.chooseAnchorButton:SetWidthFromText()
	self.chooseAnchorButton:SetBackdropColor(0, 0, 0, 0.9)
	self.chooseAnchorButton.frame:SetParent(self.frame)
	self.chooseAnchorButton.frame:SetPoint("LEFT", self.alignRightButton.frame, "RIGHT")
	self.chooseAnchorButton:SetCallback("Clicked", function() end)

	self.chooseAnchorFrameButton = AceGUI:Create("EPButton")
	self.chooseAnchorFrameButton:SetText("Choose Anchor Frame")
	self.chooseAnchorFrameButton:SetHeight(20)
	self.chooseAnchorFrameButton:SetWidthFromText()
	self.chooseAnchorFrameButton:SetBackdropColor(0, 0, 0, 0.9)
	self.chooseAnchorFrameButton.frame:SetParent(self.frame)
	self.chooseAnchorFrameButton.frame:SetPoint("LEFT", self.chooseAnchorButton.frame, "RIGHT")
	self.chooseAnchorFrameButton:SetCallback("Clicked", function()
		if isChoosingFrame then
			StopFrameChooser(self.frameChooserFrame, self.frameChooserBox)
		else
			StartFrameChooser(self.frameChooserFrame, self.frameChooserBox)
		end
	end)

	self.frame:SetHeight(self.assignmentText:GetStringHeight() + 8)
	self.frame:Show()
end

---@param self EPReminderAnchor
local function OnRelease(self)
	if self.alignCenterButton then
		self.alignCenterButton:Release()
	end
	if self.alignLeftButton then
		self.alignLeftButton:Release()
	end
	if self.alignRightButton then
		self.alignRightButton:Release()
	end
	if self.increaseFontSizeButton then
		self.increaseFontSizeButton:Release()
	end
	if self.decreaseFontSizeButton then
		self.decreaseFontSizeButton:Release()
	end
	if self.chooseAnchorButton then
		self.chooseAnchorButton:Release()
	end
	if self.chooseAnchorFrameButton then
		self.chooseAnchorFrameButton:Release()
	end
	self.alignCenterButton = nil
	self.alignLeftButton = nil
	self.alignRightButton = nil
	self.increaseFontSizeButton = nil
	self.decreaseFontSizeButton = nil
	self.chooseAnchorButton = nil
	self.chooseAnchorFrameButton = nil
end

---@param self EPReminderAnchor
---@param text string
local function SetText(self, text)
	self.assignmentText:SetText(text)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetSize(defaultFrameWidth, defaultFrameHeight)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetBackdrop(frameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 0.5)
	frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.5)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetResizable(true)
	frame:SetResizeBounds(defaultFrameWidth, defaultFrameHeight, nil, nil)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:StartMoving(true)
		end
	end)
	frame:SetScript("OnMouseUp", function(self, _)
		frame:StopMovingOrSizing()
	end)

	local textFrame = CreateFrame("Frame", "TextFrame", frame)
	textFrame:SetPoint("TOPLEFT", 2, -2)
	textFrame:SetPoint("BOTTOMRIGHT", 2, -2)

	local assignmentText = textFrame:CreateFontString(Type .. "Text", "OVERLAY", "GameFontNormalLarge")
	assignmentText:SetPoint("TOPLEFT")
	assignmentText:SetPoint("BOTTOMRIGHT")
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then
		assignmentText:SetFont(fPath, 24)
	end
	assignmentText:SetJustifyH("CENTER")

	local frameChooserFrame = CreateFrame("Frame")
	local frameChooserBox = CreateFrame("Frame", nil, frameChooserFrame, "BackdropTemplate")
	frameChooserBox:SetFrameStrata("TOOLTIP")
	frameChooserBox:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	frameChooserBox:SetBackdropBorderColor(0, 1, 0)
	frameChooserBox:Hide()
	-- local resizer = CreateFrame("Button", Type .. "Resizer" .. count, frame)
	-- resizer:SetPoint("BOTTOMRIGHT", 0, 0)
	-- resizer:SetSize(16, 16)
	-- resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	-- resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	-- resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	-- resizer:SetScript("OnMouseDown", function(self, button)
	-- 	if button == "LeftButton" then
	-- 		frame:StartSizing("BOTTOMRIGHT")
	-- 	end
	-- end)
	-- resizer:SetScript("OnMouseUp", function(self, _)
	-- 	frame:StopMovingOrSizing()
	-- end)

	---@class EPReminderAnchor
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetText = SetText,
		GetText = GetText,
		frame = frame,
		textFrame = textFrame,
		type = Type,
		assignmentText = assignmentText,
		frameChooserFrame = frameChooserFrame,
		frameChooserBox = frameChooserBox,
	}

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
