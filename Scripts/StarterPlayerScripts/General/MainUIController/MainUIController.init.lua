-- OmniRal

local MainUIController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
--local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
--local TweenService = game:GetService("TweenService")
--local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local LevelXPCurve = require(ReplicatedStorage.Source.SharedModules.General.Utility.LevelXPCurva)

--local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)
local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

local MainMenu = require(ReplicatedStorage.Source.ClientModules.UI.MainMenu)
local ScoreDisplayUI = require(ReplicatedStorage.Source.ClientModules.UI.ScoreDisplayUI)
local PushChargeBarUI = require(ReplicatedStorage.Source.ClientModules.UI.PushChargeBarUI)
local TimerUI = require(ReplicatedStorage.Source.ClientModules.UI.TimerUI)

--local GeneralUILibrary = require(ReplicatedStorage.Source.SharedModules.UI.GeneralUILibrary)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ADD_XP_PAUSE = 1 -- How many seconds to pause adding more XP to the bar after leveling up

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local VisualService = Remotes.VisualService
local DataService = Remotes.Client.DataService
local PushService = Remotes.Client.PushService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MainUIController.Menu = "None"

local LocalPlayer = Players.LocalPlayer

local Gui: any

local AddXPPauseUntil = 0

local Assets = ReplicatedStorage.Assets

local CachedTweens: {[any]: Tween} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CreateNewGui()
    Gui = Assets.UIs.MainGui:Clone()
    Gui.Parent = LocalPlayer.PlayerGui

    task.spawn(function()
        for _ = 1, 20 do
            task.wait(0.2)
            for _, OldGui in LocalPlayer.PlayerGui:GetChildren() do
                if not OldGui then continue end
                if OldGui.Name == "MainGui" and OldGui ~= Gui then
                    OldGui:Destroy()
                end
            end
        end
    end)
end

local function SetupGui()
	MainMenu.Setup(Gui)
    ScoreDisplayUI.Setup(Gui)
	PushChargeBarUI.Setup(Gui)
	TimerUI.Setup(Gui)
end

local function HandleAddXP()
    if PlayerInfo.AddXP <= 0 then return end

    if AddXPPauseUntil <= 0 then
        PlayerInfo.AddXP -= 1
        PlayerInfo.CurrentXP += 1
        if PlayerInfo.CurrentXP >= PlayerInfo.CurrentMaxXP then
            AddXPPauseUntil = os.clock() + ADD_XP_PAUSE

            PlayerInfo.CurrentLevel += 1
            PlayerInfo.CurrentMaxXP = LevelXPCurve.CalculateXPNeeded(PlayerInfo.CurrentLevel)
            PlayerInfo.CurrentXP = 0

            MainUIController.UpdateLevelInfoUI()

            return
        end

        MainUIController.UpdateLevelInfoUI()
    else
        if os.clock() < AddXPPauseUntil then return end
        AddXPPauseUntil = 0
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Update the players current level and xp
function MainUIController.UpdateLevelInfoUI()
    Gui.LevelInfo.Level.Text = "Lv. " .. PlayerInfo.CurrentLevel
    Gui.LevelInfo.XP.Text = PlayerInfo.CurrentXP .. " / " .. PlayerInfo.CurrentMaxXP .. " XP"
    Gui.LevelInfo.Progress.Fill.Size = UDim2.fromScale(PlayerInfo.CurrentXP / PlayerInfo.CurrentMaxXP, 1)
end

function MainUIController.RunAbilityCooldown(ThisAbility: "Push" | "Dodge", Time: number)
	if not Gui then return end
	if not Gui:FindFirstChild("AbilityInfo") then return end
	
	local Frame = Gui.AbilityInfo:FindFirstChild(ThisAbility)
	if not Frame then return end

	if CachedTweens[Frame] then
		CachedTweens[Frame]:Pause()
		CachedTweens[Frame]:Destroy()
		CachedTweens[Frame] = nil
	end

	Frame.Fill.Size = UDim2.fromScale(1, 1)
	CachedTweens[Frame] = TweenService:Create(Frame.Fill, TweenInfo.new(Time, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 0)})
	CachedTweens[Frame].Completed:Connect(function() 
		Frame.Icon.ImageTransparency = 0.25
	end)

	CachedTweens[Frame]:Play()
	Frame.Icon.ImageTransparency = 0.75
end

-- Update all data dependent elements of the UI
function MainUIController.UpdateAllUI()
	MainMenu.UpdateSkills()
	PushChargeBarUI.UpdateDivBars()
	MainUIController.UpdateLevelInfoUI()
end

function MainUIController.ControlPushBar(Action: "Start" | "Stop" | "StopAndHide")
	if Action == "Start" then
		PushChargeBarUI.StartCharge(PlayerInfo.Data.Skills.ChargeSpeed, PlayerInfo.Data.Skills.ChargePower)

	elseif Action == "Stop" then
		PushChargeBarUI.StopCharge()

	elseif Action == "StopAndHide" then
		PushChargeBarUI.StopCharge()
		PushChargeBarUI.Toggle(false, 1)
	end
end

function MainUIController.SetCharacter()
    if not LocalPlayer.Character then return end
end

function MainUIController.RunHeartbeat(DeltaTime: number)
	if not DeltaTime then return end

    HandleAddXP()
	TimerUI.RunHeartbeat()
end

function MainUIController:Init()
    CreateNewGui()
end

function MainUIController:Deferred()
    SetupGui()

    DeviceController.CurrentDevice:Connect(function()
        print("Main UI Controller Device ", DeviceController.CurrentDevice:Get())
    end)

	while true do
		task.wait()
		if not Remotes.Client.DataService or not Remotes.Client.PushService then continue end
		DataService = Remotes.Client.DataService
		PushService = Remotes.Client.PushService
		break
	end

	DataService.FullDataUpdate:Connect(function()
		task.defer(function()
			MainMenu.UpdateSkills()
			PushChargeBarUI.UpdateDivBars()
		end)
	end)

	DataService.MultiDataUpdate:Connect(function(UpdateList: {[string]: any})
		task.defer(function() 
			for Entry, _ in UpdateList do
				if Entry == "Skills" then
					MainMenu.UpdateSkills()
					PushChargeBarUI.UpdateDivBars()
				end
			end
		end)
	end)

	DataService.SingleDataUpdate:Connect(function(Index: string, Value: any)
        task.defer(function()
            --local PData = PlayerInfo.Data

            if typeof(Index) == "string" then
				if Value then return end

            elseif typeof(Index) == "table" then
                if Index[#Index] == "ChargePower" then
                    PushChargeBarUI.UpdateDivBars()
                end
            end
        end)
    end)

    DataService.GiveAddXP:Connect(function(ThisMuch: number)
        PlayerInfo.AddXP += ThisMuch
    end)

	PushService.ScoreChanged:Connect(function()
		task.defer(function()
			ScoreDisplayUI.UpdateScore(PlayerInfo.CurrentPoints, PlayerInfo.CurrentStreak, PlayerInfo.CurrentMultiplier)
		end)
	end)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
        MainUIController.RunHeartbeat(DeltaTime)
    end)

	warn("LOADED MAIN UIIIII")
end

return MainUIController