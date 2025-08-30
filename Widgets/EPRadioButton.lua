local Type = "EPRadioButton"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local UIParent = UIParent
local CreateColor = CreateColor
local CreateFrame = CreateFrame
local unpack = unpack

local k = {
	BackdropColor = { 0, 0, 0, 0 },
	ButtonBackdrop = {
		bgFile = "Interface\\BUTTONS\\White8x8",
		edgeFile = nil,
		tile = false,
		tileSize = 0,
		edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	DefaultFrameHeight = 24,
	DefaultFrameWidth = 100,
	DisabledIconColor = { 0.5, 0.5, 0.5, 1 },
	HoverButtonColor = { 74 / 255.0, 174 / 255.0, 242 / 255.0 },
	IconColor = { 1, 1, 1, 1 },
	SelectedButtonColor = { 1, 1, 1 },
}

---@param self EPRadioButton
local function HandleButtonLeave(self)
	local fadeAlpha = self.button.fadeAlpha
	local fadeColor = self.button.fadeColor

	if fadeColor:IsPlaying() then
		fadeColor:Stop()
	end
	if fadeAlpha:IsPlaying() then
		fadeAlpha:Stop()
	end

	local alpha = self.button.iconCenter:GetAlpha()
	local fadeAlphaAnimation = self.button.fadeAlphaAnimation
	self.button.iconCenter:Show()
	if self.toggled then
		local r, g, b, a = self.button.iconCenter:GetVertexColor()
		local fadeColorAnimation = self.button.fadeColorAnimation
		fadeColorAnimation:SetStartColor(CreateColor(r, g, b, a))
		fadeColorAnimation:SetEndColor(self.white)
		if alpha < 1.0 then
			fadeAlphaAnimation:SetFromAlpha(alpha)
			fadeAlphaAnimation:SetToAlpha(1)
			fadeAlpha:SetScript("OnFinished", function()
				self.button.iconCenter:SetAlpha(1)
			end)
			fadeAlpha:Play()
		end
		fadeColor:Play()
	else
		fadeAlphaAnimation:SetFromAlpha(alpha)
		fadeAlphaAnimation:SetToAlpha(0)
		fadeAlpha:SetScript("OnFinished", function()
			self.button.iconCenter:SetAlpha(0)
		end)
		fadeAlpha:Play()
	end
end

---@param self EPRadioButton
local function HandleButtonEnter(self)
	if not self.toggled then
		local fadeAlpha = self.button.fadeAlpha
		local fadeColor = self.button.fadeColor

		if fadeAlpha:IsPlaying() then
			fadeAlpha:Stop()
		end
		if fadeColor:IsPlaying() then
			fadeColor:Stop()
		end

		local alpha = self.button.iconCenter:GetAlpha()
		local r, g, b, a = self.button.iconCenter:GetVertexColor()

		local fadeColorAnimation = self.button.fadeColorAnimation
		fadeColorAnimation:SetStartColor(CreateColor(r, g, b, a))
		fadeColorAnimation:SetEndColor(self.blue)

		if alpha < 1.0 then
			local fadeAlphaAnimation = self.button.fadeAlphaAnimation
			fadeAlphaAnimation:SetFromAlpha(alpha)
			fadeAlphaAnimation:SetToAlpha(1)
			fadeAlpha:SetScript("OnFinished", function()
				self.button.iconCenter:SetAlpha(1)
			end)
			fadeAlpha:Play()
		end

		fadeColor:Play()
	end
end

---@param self EPRadioButton
local function HandleButtonClicked(self)
	if not self.toggled then
		self:SetToggled(not self.toggled)
		self:Fire("Toggled", self.toggled)
	end
end

---@class EPRadioButton : AceGUIWidget
---@field frame Frame
---@field button table|BackdropTemplate|Button
---@field label EPLabel
---@field type string
---@field obj any
---@field toggled boolean|nil
---@field enabled boolean

---@param self EPRadioButton
local function OnAcquire(self)
	self.toggled = false
	self.frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)

	self.label = AceGUI:Create("EPLabel")
	self.label.frame:SetParent(self.frame)
	self.label.frame:SetPoint("LEFT", self.button, "RIGHT", 4, 0)
	self.label.frame:SetPoint("RIGHT", self.frame, "RIGHT")

	self:SetIconPadding(2, 2)
	self:SetBackdropColor(unpack(k.BackdropColor))
	self:SetToggled(false)
	self:SetEnabled(true)

	self.button.icon:Show()
	self.frame:Show()
end

---@param self EPRadioButton
local function OnRelease(self)
	if self.label then
		self.label:Release()
	end
	self.label = nil
	self.toggled = nil
end

---@param self EPRadioButton
local function SetEnabled(self, enabled)
	self.enabled = enabled
	if enabled then
		self:SetIconColor(unpack(k.IconColor))
	else
		self:SetIconColor(unpack(k.DisabledIconColor))
	end
	self.button.icon:SetDesaturated(not enabled)
	self.button:SetEnabled(enabled)
	self.label:SetEnabled(enabled)
end

---@param self EPRadioButton
---@param text string
local function SetLabelText(self, text)
	self.label:SetText(text or "")
	self.label:SetFrameWidthFromText()
	self.frame:SetWidth(self.label.frame:GetWidth() + self.button:GetWidth() + 4)
end

---@param self EPRadioButton
---@param r number
---@param g number
---@param b number
---@param a number
local function SetIconColor(self, r, g, b, a)
	local iconTexture = self.button.icon
	if iconTexture then
		iconTexture:SetVertexColor(r, g, b, a)
	end
end

---@param self EPRadioButton
---@param toggled boolean
local function SetToggled(self, toggled)
	self.toggled = toggled

	local fadeAlpha = self.button.fadeAlpha
	local fadeColor = self.button.fadeColor

	if fadeAlpha:IsPlaying() then
		fadeAlpha:Stop()
	end
	if fadeColor:IsPlaying() then
		fadeColor:Stop()
	end

	self.button.iconCenter:SetVertexColor(1, 1, 1, 1)
	if self.toggled then
		self.button.iconCenter:SetAlpha(1)
	else
		self.button.iconCenter:SetAlpha(0)
	end
end

---@param self EPRadioButton
local function IsToggled(self)
	return self.toggled
end

---@param self EPRadioButton
---@param r number
---@param g number
---@param b number
---@param a number
local function SetBackdropColor(self, r, g, b, a)
	self.button:SetBackdropColor(r, g, b, a)
end

---@param self EPRadioButton
---@param x number
---@param y number
local function SetIconPadding(self, x, y)
	self.button.icon:SetPoint("TOPLEFT", self.button, "TOPLEFT", x, -y)
	self.button.icon:SetPoint("BOTTOMLEFT", self.button, "BOTTOMLEFT", x, y)
	self.button.iconCenter:SetPoint("TOPLEFT", self.button, "TOPLEFT", x, -y)
	self.button.iconCenter:SetPoint("BOTTOMLEFT", self.button, "BOTTOMLEFT", x, y)
	self.button.icon:SetWidth(self.button:GetHeight() - 2 * y)
	self.button.iconCenter:SetWidth(self.button:GetHeight() - 2 * y)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetSize(k.DefaultFrameWidth, k.DefaultFrameHeight)
	frame:EnableMouse(true)

	local button = CreateFrame("Button", Type .. "Button" .. count, frame, "BackdropTemplate")
	button:SetBackdrop(k.ButtonBackdrop)
	button:SetBackdropColor(unpack(k.BackdropColor))
	button:RegisterForClicks("LeftButtonUp")
	button:SetPoint("TOPLEFT")
	button:SetPoint("BOTTOMLEFT")
	button:SetWidth(k.DefaultFrameHeight)
	button:SetMouseMotionEnabled(false)

	button.icon = button:CreateTexture(Type .. "Icon" .. count, "OVERLAY")
	button.icon:SetBlendMode("ADD")
	button.icon:SetPoint("TOPLEFT")
	button.icon:SetPoint("BOTTOMRIGHT")
	button.icon:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-unchecked-radio-button-96]])
	button.icon:SetSnapToPixelGrid(false)
	button.icon:SetTexelSnappingBias(0)

	button.iconCenter = button:CreateTexture(Type .. "Background" .. count, "BORDER")
	button.iconCenter:SetPoint("TOPLEFT")
	button.iconCenter:SetPoint("BOTTOMRIGHT")
	button.iconCenter:SetSnapToPixelGrid(false)
	button.iconCenter:SetTexelSnappingBias(0)
	button.iconCenter:SetTexture([[Interface\AddOns\EncounterPlanner\Media\icons8-radio-button-center-96]])
	button.iconCenter:SetAlpha(0.0)

	button.fadeColor = button.iconCenter:CreateAnimationGroup()
	button.fadeColorAnimation = button.fadeColor:CreateAnimation("VertexColor")
	button.fadeColorAnimation:SetDuration(0.3)
	button.fadeColorAnimation:SetSmoothing("OUT")

	button.fadeAlpha = button.iconCenter:CreateAnimationGroup()
	button.fadeAlphaAnimation = button.fadeAlpha:CreateAnimation("Alpha")
	button.fadeAlphaAnimation:SetDuration(0.3)
	button.fadeAlphaAnimation:SetSmoothing("OUT")

	---@class EPRadioButton
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		SetLabelText = SetLabelText,
		SetBackdropColor = SetBackdropColor,
		SetToggled = SetToggled,
		IsToggled = IsToggled,
		SetIconPadding = SetIconPadding,
		SetIconColor = SetIconColor,
		SetEnabled = SetEnabled,
		frame = frame,
		type = Type,
		button = button,
		blue = CreateColor(unpack(k.HoverButtonColor)),
		white = CreateColor(unpack(k.SelectedButtonColor)),
	}

	frame:SetScript("OnEnter", function()
		HandleButtonEnter(widget)
		widget:Fire("OnEnter")
	end)
	frame:SetScript("OnLeave", function()
		HandleButtonLeave(widget)
		widget:Fire("OnLeave")
	end)
	button:SetScript("OnClick", function()
		HandleButtonClicked(widget)
	end)
	frame:SetScript("OnMouseUp", function()
		HandleButtonClicked(widget)
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
