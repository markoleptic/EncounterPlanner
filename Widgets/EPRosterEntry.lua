local _, Namespace = ...
local L = Namespace.L

local Type = "EPRosterEntry"
local Version = 1

local AceGUI = LibStub("AceGUI-3.0")
local CreateFrame = CreateFrame

local mainFrameWidth = 1125
local mainFrameHeight = 600
local contentFramePadding = { x = 4, y = 4 }

---@class EPRosterEntry : AceGUIContainer
---@field frame table|BackdropTemplate|Frame
---@field content table|Frame
---@field nameLineEdit EPLineEdit
---@field classDropdown EPDropdown
---@field roleDropdown EPDropdown
---@field deleteButton EPButton
---@field type string

---@param self EPRosterEntry
local function OnAcquire(self)
	self.frame:SetParent(UIParent)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.frame:Show()

	self:SetLayout("EPHorizontalLayout")

	self.nameLineEdit = AceGUI:Create("EPLineEdit")
	self.nameLineEdit:SetCallback("OnTextSubmitted", function(_, _, value)
		self:Fire("NameChanged", value)
	end)
	self.nameLineEdit:SetHeight(20)
	self.nameLineEdit:SetMaxLetters(12)
	self.classDropdown = AceGUI:Create("EPDropdown")
	self.classDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("ClassChanged", value)
	end)
	self.classDropdown:SetDropdownItemHeight(20)
	self.roleDropdown = AceGUI:Create("EPDropdown")
	self.roleDropdown:SetCallback("OnValueChanged", function(_, _, value)
		self:Fire("RoleChanged", value)
	end)
	self.roleDropdown:SetDropdownItemHeight(20)

	self.deleteButton = AceGUI:Create("EPButton")
	self.deleteButton:SetIcon([[Interface\AddOns\EncounterPlanner\Media\icons8-close-32]])
	self.deleteButton:SetIconPadding(0, 0)
	self.deleteButton:SetHeight(20)
	self.deleteButton:SetWidth(20)
	self.deleteButton:SetCallback("Clicked", function()
		self:Fire("DeleteButtonClicked")
	end)

	self:AddChildren(self.nameLineEdit, self.classDropdown, self.roleDropdown, self.deleteButton)
end

---@param self EPRosterEntry
local function OnRelease(self)
	self.nameLineEdit = nil
	self.classDropdown = nil
	self.roleDropdown = nil
	self.deleteButton = nil
end

---@param self EPRosterEntry
---@param width number|nil
---@param height number|nil
local function LayoutFinished(self, width, height)
	if width and height then
		self.frame:SetSize(width, height)
	end
end

---@param self EPRosterEntry
---@param dropdownItemData DropdownItemData
local function PopulateClassDropdown(self, dropdownItemData)
	self.classDropdown:AddItems(dropdownItemData, "EPDropdownItemToggle")
end

---@param self EPRosterEntry
---@param roles table<RaidGroupRole, boolean>
local function PopulateRoleDropdown(self, roles)
	self.roleDropdown:Clear()
	local items = {}
	if roles["role:tank"] then
		items[#items + 1] = { itemValue = "role:tank", text = L["Tank"] }
	end
	if roles["role:healer"] then
		items[#items + 1] = { itemValue = "role:healer", text = L["Healer"] }
	end
	if roles["role:damager"] then
		items[#items + 1] = { itemValue = "role:damager", text = L["Damager"] }
	end
	self.roleDropdown:AddItems(items, "EPDropdownItemToggle")
end

---@param self EPRosterEntry
---@param name string
---@param class string
---@param role RaidGroupRole
local function SetData(self, name, class, role)
	self.nameLineEdit:SetText(name)
	self.classDropdown:SetValue(class)
	self.roleDropdown:SetValue(role)
end

local function Constructor()
	local count = AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", Type .. count, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetSize(mainFrameWidth, mainFrameHeight)

	local content = CreateFrame("Frame", Type .. "Content" .. count, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")
	content.spacing = contentFramePadding

	---@class EPRosterEntry
	local widget = {
		OnAcquire = OnAcquire,
		OnRelease = OnRelease,
		LayoutFinished = LayoutFinished,
		PopulateClassDropdown = PopulateClassDropdown,
		PopulateRoleDropdown = PopulateRoleDropdown,
		SetData = SetData,
		frame = frame,
		content = content,
		type = Type,
	}

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
