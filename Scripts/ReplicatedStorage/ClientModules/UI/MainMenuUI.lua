-- OmniRal

local MainMenuUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
--local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local MENU_ON_POSITION = UDim2.fromScale(0.5, 0.5)
local MENU_OFF_POSITION = UDim2.fromScale(0.5, 0.7)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types & Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

type TabType = "Shop" | "Stats" | "Skills" | "Settings"

local DataService = Remotes.Client.DataService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local LocalPlayer = Players.LocalPlayer

local CurrentTab = "Shop"

local Menu: any?
local Base: any?
local MenuButton: any?
local Tabs: {[string]: ImageButton} = {}

local AnimTime = UI_Info.BaseAnimTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateBase()
	if not Tabs[CurrentTab] then return end
	local Tab = Tabs[CurrentTab]
	local Color = Tab.BackgroundColor3
	local Num = Tab:GetAttribute("TabNum")

	-- Figure out the length of the black bar below the tabs
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

	-- Update the background color
	Base.Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color),
		ColorSequenceKeypoint.new(0.5, ColorPalette.JetWhite.RGB),
		ColorSequenceKeypoint.new(1, ColorPalette.JetWhite.RGB)
	}

	-- Update which window is open
	for _, Window in Base.Windows:GetChildren() do
		if not Window then continue end
		Window.Visible = Window.Name == CurrentTab
	end
end

local function TurnOffTabs(Except: ImageButton)
	for _, Tab in Tabs do
		if not Tab then continue end
		if Tab == Except then continue end
		Tab:SetAttribute("On", false)
	end
end

local function UpdateMenuButtonVisuals()
	if not Menu or not MenuButton then return end
	local Hover, Pressed, On, Locked = MenuButton.Button:GetAttribute("Hover"), MenuButton.Button:GetAttribute("Pressed"), MenuButton.Button:GetAttribute("On"), MenuButton.Button:GetAttribute("Locked")

	if not Locked then
		if not Hover and not Pressed then
			MenuButton.Container.Icon.Size = UDim2.fromScale(0.7, 0.7)
		elseif Hover and not Pressed then
			MenuButton.Container.Icon.Size = UDim2.fromScale(0.8, 0.8)
		elseif Pressed then
			MenuButton.Container.Icon.Size = UDim2.fromScale(0.5, 0.5)
		end
	end

	if not On then
		for x = 1, 3 do MenuButton.Container.Icon["Line" .. x].BackgroundColor3 = ColorPalette.DarkGrey.RGB end
	else
		MenuButton.Container.Icon.Line1.BackgroundColor3 = ColorPalette.OmniBlotGreen2.RGB
		MenuButton.Container.Icon.Line2.BackgroundColor3 = ColorPalette.OmniBlotBlue2.RGB
		MenuButton.Container.Icon.Line3.BackgroundColor3 = ColorPalette.OmniBlotRed2.RGB
	end

	Menu:SetAttribute("On", MenuButton.Button:GetAttribute("On"))
end

-- Hover, Pressed and On changes for the tab buttons
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

-- Hover, Pressed, Locked and On changes for the plus button that adds a skill point to the respective skill
local function UpdatePlusSkillButtonVisuals(Plus: any)
	local Hover, Pressed, Locked = Plus:GetAttribute("Hover"), Plus:GetAttribute("Pressed"), Plus:GetAttribute("Locked")
	
	if not Locked then
		Plus.Icon.ImageTransparency = 0
		Plus.Icon.ImageColor3 = ColorPalette.OmniBlotDarkRed.RGB

		if not Hover and not Pressed then
			Plus.Icon.Size = UDim2.fromScale(0.9, 0.9)

		elseif Hover and not Pressed then
			Plus.Icon.Size = UDim2.fromScale(1, 1)

		else
			Plus.Icon.Size = UDim2.fromScale(0.6, 0.6)
		end

	else
		Plus.Icon.ImageTransparency = 0.75
		Plus.Icon.Size = UDim2.fromScale(0.9, 0.9)
		Plus.Icon.ImageColor3 = ColorPalette.JetBlack.RGB
	end
end

local function TestViewportDummy()
	if not Menu then return end

	local Frame = Menu.Base.Windows.Stuff:FindFirstChild("Frame")
	if not Frame then return end

	local Dummy = ReplicatedStorage.Assets.Other.AnimDummy:Clone()
	Dummy:PivotTo(CFrame.new(0, 0, 0))
	Dummy.Parent = Frame.Viewport.WorldModel

	local NewCam = Instance.new("Camera")
	NewCam.CFrame = CFrame.new(0, 0, 10)
	NewCam.Parent = Frame.Viewport

	local NewAnim = Instance.new("Animation")
	NewAnim.AnimationId = "rbxassetid://" .. 136393663879299
	local NewTrack = Dummy.AnimationController.Animator:LoadAnimation(NewAnim)
	NewTrack.Looped = true
	NewTrack:Play()

	Frame.Viewport.CurrentCamera = NewCam
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainMenuUI.UpdateSkills()
	if not PlayerInfo.Data then return end
	if not PlayerInfo.Data.Skills then return end

	local Points = PlayerInfo.Data.SkillPoints

		-- Update skill points left
	Base.Windows.Skills.Info.PointsLeft.Text = Points
	
	for _, Frame in Base.Windows.Skills.List:GetChildren() do
		if not Frame:IsA("Frame") then continue end
		
		local Skill = PlayerInfo.Data.Skills[Frame.Name]
		if not Skill then continue end
		
		-- Update how much each skill progress bar is filled
		for x = 1, 5 do
			local Slot = Frame.Right.Progress:FindFirstChild("Slot_" .. x)
			if not Slot then continue end

			Slot.Fill.Visible = Skill >= x
		end

		-- Update if the + skill button is locked
		Frame.Right.Plus:SetAttribute("Locked", Points <= 0 or Skill >= 5)
	end
end

function MainMenuUI.Setup(Gui: ScreenGui)
	if not Gui then return end

	Menu = Gui:FindFirstChild("Menu")
	if not Menu then return end

	Base, MenuButton = Menu:FindFirstChild("Base"), Gui:FindFirstChild("MenuButton")
	if not Base or not MenuButton then return end

	-- Set up menu button
	BasicInteractions.AddButton(MenuButton.Button, true)
	BasicInteractions.ConnectFXInteractionsFN(MenuButton.Button, UpdateMenuButtonVisuals)
	UpdateMenuButtonVisuals()

	task.wait(1)

	Menu:SetAttribute("On", false)
	local MenuTween: any

	Menu:GetAttributeChangedSignal("On"):Connect(function()
		local GoalPosition, GoalTransparency, Direction = MENU_ON_POSITION, 0, Enum.EasingDirection.Out

		if not Menu:GetAttribute("On") then
			GoalPosition = MENU_OFF_POSITION
			GoalTransparency = 1
			Direction = Enum.EasingDirection.In
		else
			Menu.Visible = true
		end

		MenuTween = TweenService:Create(Menu, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Direction), {Position = GoalPosition, GroupTransparency = GoalTransparency})
		MenuTween.Completed:Connect(function()
			if Menu:GetAttribute("On") then return end
			Menu.Visible = false
		end)
		MenuTween:Play()
	end)
	Menu.Position = MENU_OFF_POSITION
	Menu.GroupTransparency = 1
	Menu.Visible = true

	-- Set up tab buttons
	for _, Tab in Menu.Tabs:GetChildren() do
		if not Tab then continue end
		if not Tab:IsA("ImageButton") then continue end

		local CopyTab = Menu.BackTabs:FindFirstChild(Tab.Name)
		if not CopyTab then return end

		BasicInteractions.AddButton(Tab)
		BasicInteractions.ConnectFXInteractionsFN(Tab, UpdateTabVisuals, false, false, false, true, CopyTab)
		
		if Tab.Name == "Shop" then Tab:SetAttribute("On", true) end

		Tabs[Tab.Name] = Tab
	end

	-- Set up skills tab
	for _, Frame in Base.Windows.Skills.List:GetChildren() do
		if not Frame:IsA("Frame") then continue end

		Frame.Right.Plus.AutoButtonColor = false
		BasicInteractions.AddButton(Frame.Right.Plus)
		BasicInteractions.ConnectFXInteractionsFN(Frame.Right.Plus, UpdatePlusSkillButtonVisuals, false, false, true, false)

		Frame.Right.Plus.Activated:Connect(function()
			if Frame.Right.Plus:GetAttribute("Locked") then return end
			local Result = DataService:RequestUpgradeSkill(Frame.Name)
			if Result == 1 then
				print("Success!")
			else
				print(Result)
			end
		end)
	end

	TestViewportDummy()
end

return MainMenuUI