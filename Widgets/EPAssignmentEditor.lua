local Type                = "EPAssignmentEditor"
local Version             = 1
local AceGUI              = LibStub("AceGUI-3.0")
local LSM                 = LibStub("LibSharedMedia-3.0")
local frameWidth          = 200
local frameHeight         = 100
local windowBarHeight     = 24
local contentFramePadding = { x = 10, y = 10 }
local title               = "Assignment Editor"

local FrameBackdrop       = {
	bgFile = "Interface\\BUTTONS\\White8x8",
	edgeFile = "Interface\\BUTTONS\\White8x8",
	tile = true,
	tileSize = 16,
	edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
local titleBarBackdrop    = {
	bgFile = nil,
	edgeFile = nil,
	tile = false,
	edgeSize = 0,
}

local function FlashButton_OnLeave(self)
	local fadeIn = self.fadeIn
	if fadeIn:IsPlaying() then
		fadeIn:Stop()
	end
	self.fadeOut:Play()
end

local function FlashButton_OnEnter(self)
	local fadeOut = self.fadeOut
	if fadeOut:IsPlaying() then
		fadeOut:Stop()
	end
	self.fadeIn:Play()
end

local function CreateFlashButton(parent, text, width, height)
	local Button = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	Button:SetSize(width or 80, height or 20)
	Button:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = "Interface\\BUTTONS\\White8x8",
		edgeSize = 1,
	})
	Button:SetBackdropColor(0.725, 0.008, 0.008)
	Button:SetBackdropBorderColor(0, 0, 0)
	Button:SetScript("OnEnter", FlashButton_OnEnter)
	Button:SetScript("OnLeave", FlashButton_OnLeave)
	Button:SetNormalFontObject("GameFontNormal")
	Button:SetText(text or "")

	Button.bg = Button:CreateTexture(nil, "BORDER")
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		Button.bg:SetAllPoints()
	else
		Button.bg:SetTexelSnappingBias(0.0)
		Button.bg:SetSnapToPixelGrid(false)
		Button.bg:SetPoint("TOPLEFT", Button.TopEdge, "BOTTOMLEFT")
		Button.bg:SetPoint("BOTTOMRIGHT", Button.BottomEdge, "TOPRIGHT")
	end
	Button.bg:SetColorTexture(0.0, 0.6, 0.4)
	Button.bg:Hide()

	Button.fadeIn = Button.bg:CreateAnimationGroup()
	Button.fadeIn:SetScript("OnPlay", function() Button.bg:Show() end)
	local fadeIn = Button.fadeIn:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.4)
	fadeIn:SetSmoothing("OUT")

	Button.fadeOut = Button.bg:CreateAnimationGroup()
	Button.fadeOut:SetScript("OnFinished", function() Button.bg:Hide() end)
	local fadeOut = Button.fadeOut:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.3)
	fadeOut:SetSmoothing("OUT")

	return Button
end

---@class EPAssignmentEditor : AceGUIContainer
---@field frame Frame|BackdropTemplate|table
---@field type string
---@field count number
---@field titleText FontString
---@field assignmentTypeDropdown EPDropdown
---@field spellAssignmentDropdown EPDropdown
---@field assigneeTypeDropdown EPDropdown
---@field assigneeDropdown EPDropdown
---@field timeEditBox AceGUIWidget
---@field assignment Assignment
---@field obj any

local function HandleAssignmentTypeDropdownValueChanged(frame, callbackName, value)
	--local self = frame.obj
	--self:Fire("AssignmentDataChanged", self.assignment)
end

local function HandleSpellAssignmentDropdownValueChanged(frame, callbackName, value)
	local self = frame.obj --[[@as EPAssignmentEditor]]
	local itemText = self.spellAssignmentDropdown:FindItemText(value)
	if itemText then
		self.spellAssignmentDropdown:SetItemDisabled("Recent", false)
		self.spellAssignmentDropdown:AddItemsToExistingDropdownItemMenu("Recent",
			{ { itemValue = value, text = itemText, dropdownItemMenuData = {} } })
	end
	--self:Fire("AssignmentDataChanged", self.assignment)
end

local function HandleAssigneeTypeDropdownValueChanged(frame, callbackName, value)
	--local self = frame.obj
	--self:Fire("AssignmentDataChanged", self.assignment)
end

local function HandleAssigneeDropdownValueChanged(frame, callbackName, value)
	--local self = frame.obj
	--self:Fire("AssignmentDataChanged", self.assignment)
end

---@param self EPAssignmentEditor
local function OnAcquire(self)
	self.assignment = self.assignment or {}

	self:SetPoint("CENTER")
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	self:SetLayout("EPVerticalLayout")
	self:SetAutoAdjustHeight(true)

	self.assignmentTypeDropdown = AceGUI:Create("EPDropdown");
	self.assignmentTypeDropdown:SetCallback("OnValueChanged", HandleAssignmentTypeDropdownValueChanged)
	self.assignmentTypeDropdown:SetFullWidth(true)
	self.assignmentTypeDropdown.obj = self
	self:AddChild(self.assignmentTypeDropdown)

	self.assigneeTypeDropdown = AceGUI:Create("EPDropdown");
	self.assigneeTypeDropdown:SetCallback("OnValueChanged", HandleAssigneeTypeDropdownValueChanged)
	self.assigneeTypeDropdown:SetFullWidth(true)
	self.assigneeTypeDropdown.obj = self
	self:AddChild(self.assigneeTypeDropdown)

	self.assigneeDropdown = AceGUI:Create("EPDropdown");
	self.assigneeDropdown:SetCallback("OnValueChanged", HandleAssigneeDropdownValueChanged)
	self.assigneeDropdown:SetFullWidth(true)
	self.assigneeDropdown.obj = self
	self:AddChild(self.assigneeDropdown)

	self.spellAssignmentDropdown = AceGUI:Create("EPDropdown");
	self.spellAssignmentDropdown:SetCallback("OnValueChanged", HandleSpellAssignmentDropdownValueChanged)
	self.spellAssignmentDropdown:SetFullWidth(true)
	self.spellAssignmentDropdown.obj = self
	self.spellAssignmentDropdown:AddItem("Recent", "Recent", "EPDropdownItemMenu", {}, true)
	self.spellAssignmentDropdown:SetItemDisabled("Recent", true)
	self:AddChild(self.spellAssignmentDropdown)

	self.timeEditBox = AceGUI:Create("EditBox");
	---@diagnostic disable-next-line: inject-field
	self.timeEditBox.obj = self
	self:AddChild(self.timeEditBox)

	self.frame:Show()

	self:ResumeLayout()
	self:DoLayout()
end

---@param self EPAssignmentEditor
local function OnRelease(self)
	wipe(self.assignment)
end

---@param self EPAssignmentEditor
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetSize(width + contentFramePadding.x * 2, height + windowBarHeight + contentFramePadding.y * 2)
	end
end

---@param self EPAssignmentEditor
---@param assignment Assignment Should be a deep of the assignment since it is nilled on release.
local function SetAssignmentData(self, assignment)
	self.assignment = assignment
end

---@param self EPAssignmentEditor
---@return EPDropdown
local function GetSpellAssignmentDropdown(self)
	return self.spellAssignmentDropdown
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent, "BackdropTemplate")
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	frame:SetSize(frameWidth, frameHeight)
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local windowBar = CreateFrame("Frame", Type .. "WindowBar" .. count, frame, "BackdropTemplate")
	windowBar:SetHeight(windowBarHeight)
	windowBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
	windowBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	windowBar:SetBackdrop(titleBarBackdrop)
	windowBar:SetBackdropColor(0, 0, 0, 0)
	windowBar:EnableMouse(true)

	local windowBarText = windowBar:CreateFontString(Type .. "TitleText" .. count, "OVERLAY", "GameFontNormalLarge")
	windowBarText:SetText(title)
	windowBarText:SetPoint("CENTER", windowBar, "CENTER")
	local h = windowBarText:GetStringHeight()
	local fPath = LSM:Fetch("font", "PT Sans Narrow")
	if fPath then windowBarText:SetFont(fPath, h) end
	windowBar:SetScript("OnMouseDown", function()
		frame:StartMoving()
	end)
	windowBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)

	local contentFrameName = "ContentFrame" .. count
	local contentFrame = CreateFrame("Frame", contentFrameName, frame)
	contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", contentFramePadding.x,
		-(windowBarHeight + contentFramePadding.y))
	contentFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -contentFramePadding.x,
		-(windowBarHeight + contentFramePadding.y))
	contentFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", contentFramePadding.x, contentFramePadding.y)
	contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentFramePadding.x, contentFramePadding.y)

	local closebutton = CreateFlashButton(windowBar, "X", 20, 20)

	---@class EPAssignmentEditor
	local widget = {
		type                       = Type,
		count                      = count,
		frame                      = frame,
		content                    = contentFrame,
		windowBar                  = windowBar,
		OnAcquire                  = OnAcquire,
		OnRelease                  = OnRelease,
		LayoutFinished             = LayoutFinished,
		SetAssignmentData          = SetAssignmentData,
		GetSpellAssignmentDropdown = GetSpellAssignmentDropdown
	}

	closebutton:SetPoint("TOPRIGHT", -2, -2)
	closebutton:SetScript("OnClick", function()
		widget:Release()
	end)

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
