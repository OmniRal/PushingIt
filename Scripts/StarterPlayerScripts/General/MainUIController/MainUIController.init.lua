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
--local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

--local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)
local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

local ScoreDisplayUI = require(ReplicatedStorage.Source.ClientModules.UI.ScoreDisplayUI)
local PushChargeBarUI = require(ReplicatedStorage.Source.ClientModules.UI.PushChargeBarUI)

--local GeneralUILibrary = require(ReplicatedStorage.Source.SharedModules.UI.GeneralUILibrary)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local VisualService = Remotes.VisualService
local DataService = Remotes.DataService
local PushService = Remotes.PushService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MainUIController.Menu = "None"

local LocalPlayer = Players.LocalPlayer

local Gui: ScreenGui

local Assets = ReplicatedStorage.Assets

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
    ScoreDisplayUI.Setup(Gui)
	PushChargeBarUI.Setup(Gui)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
	if DeltaTime then return end
end

function MainUIController:Init()
    CreateNewGui()
end

function MainUIController:Deferred()
    SetupGui()

    DeviceController.CurrentDevice:Connect(function()
        print("Main UI Controller Device ", DeviceController.CurrentDevice:Get())
    end)

	DataService.DataUpdate:Connect(function()
        task.defer(function()
			PushChargeBarUI.UpdateDivBars()
		end)
    end)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
        MainUIController.RunHeartbeat(DeltaTime)
    end)

	PushService.ScoreUp:Connect(function()
		task.defer(function()
			ScoreDisplayUI.UpdatePoints(PlayerInfo.CurrentPoints)
		end)
	end)
end

return MainUIController