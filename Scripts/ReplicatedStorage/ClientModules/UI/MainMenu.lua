-- OmniRal

local MainMenu = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
--local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

type TabType = "Shop" | "Stats" | "Skills" | "Settings"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer

local CurrentTab = "Shop"

local Base: any?
local Tabs: {[string]: ImageButton} = {}


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateBase()
	if not Tabs[CurrentTab] then return end
	local Tab = Tabs[CurrentTab]
	local Color = Tab.BackgroundColor3
	local Num = Tab:GetAttribute("TabNum")

	local LeftLength = 0.25 * (Num - 1)
	local RightLength = 1 - (0.25 * Num)

	if LeftLength <= 0 then
		Base.LeftBar.Visible = false
	else
		Base.LeftBar.Visible = true
		Base.LeftBar.Size = UDim2.new(LeftLength, -3 + (Num - 2), 0, 0)
	end

	if RightLength <= 0. then
		Base.RightBar.Visible = false
	else
		Base.RightBar.Visible = true
		Base.RightBar.Size = UDim2.new(RightLength, -1 - (Num - 1), 0, 0)
	end

	Base.Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color),
		ColorSequenceKeypoint.new(0.5, ColorPalette.JetWhite.RGB),
		ColorSequenceKeypoint.new(1, ColorPalette.JetWhite.RGB)
	}
end

local function TurnOffTabs(Except: ImageButton)
	for _, Tab in Tabs do
		if not Tab then continue end
		if Tab == Except then continue end
		Tab:SetAttribute("On", false)
	end
end

-- Hover, pressed and on changes for the tab buttons
local function UpdateTabVisuals(Tab: ImageButton, CopyTab: ImageButton)
	if not Tab or not CopyTab then return end

	local Cover = Tab:FindFirstChild("Cover")
	if not Cover then return end

	local Hover, Pressed, On = Tab:GetAttribute("Hover"), Tab:GetAttribute("Pressed"), Tab:GetAttribute("On")
	
	Cover.Visible = false

	if On then
		CurrentTab = Tab.Name

		Tab.Size = UDim2.new(0.25, -3, 1, 0)
		Cover.Visible = false

		UpdateBase()
		TurnOffTabs(Tab)
	else
		Cover.Visible = true

		if not Hover and not Pressed then
			Tab.Size = UDim2.new(0.25, -3, 0.8, 0)
			Cover.BackgroundTransparency = 0.75
			
		elseif Hover and not Pressed then
			Tab.Size = UDim2.new(0.25, -3, 0.9, 0)
			Cover.BackgroundTransparency = 0.85

		else -- Hover and Pressed
			Tab.Size = UDim2.new(0.25, -3, 0.6, 0)
			Cover.BackgroundTransparency = 0.65
		end
	end

	CopyTab.Size = Tab.Size
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainMenu.Setup(Gui: ScreenGui)
	if not Gui then return end

	local Menu = Gui:FindFirstChild("Menu")
	if not Menu then return end

	Base = Menu:FindFirstChild("Base")
	if not Base then return end

	-- Set up tab buttons
	for _, Tab in Menu.Tabs:GetChildren() do
		if not Tab then continue end
		if not Tab:IsA("ImageButton") then continue end

		local CopyTab = Menu.BackTabs:FindFirstChild(Tab.Name)
		if not CopyTab then return end

		BasicInteractions.AddButton(Tab)
		BasicInteractions.ConnectFXInteractionsFN(Tab, UpdateTabVisuals, false, false, false, CopyTab)
		
		if Tab.Name == "Shop" then Tab:SetAttribute("On", true) end

		Tabs[Tab.Name] = Tab
	end
end

function MainMenu:Init()
end

function MainMenu:Deferred()
end

return MainMenu