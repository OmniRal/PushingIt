-- OmniRal

local AimerUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
--local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ANIM_TIME = UI_Info.BaseAnimTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer

local Aimer: any

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function AimerUI.SetAimerLine(ID: number)
	for _, Line in Aimer:GetChildren() do
		if not Line then continue end
		if not Line:IsA("Frame") then continue end
		Line.BackgroundTransparency = 0.8
		Line.Stroke.Transparency = 0.8
	end

	Aimer["A_" .. ID].BackgroundTransparency = 0.25
	Aimer["A_" .. ID].Stroke.Transparency = 0.25
end

function AimerUI.Toggle(SetTo: boolean)
	Aimer:SetAttribute("Enabled", SetTo)
end

function AimerUI.Setup(Gui: ScreenGui)
	Aimer = Gui:FindFirstChild("Aimer") :: Frame
	if not Aimer then return end

	Aimer:SetAttribute("Enabled", true)
	local FadeTween

	Aimer:GetAttributeChangedSignal("Enabled"):Connect(function()
		local GoalTransparency = 1
		if FadeTween then FadeTween:Pause(); FadeTween:Destroy(); FadeTween = nil end

		if Aimer:GetAttribute("Enabled") then
			Aimer.Visible = true
			GoalTransparency = 0
		end

		FadeTween = TweenService:Create(Aimer, TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Linear), {GroupTransparency = GoalTransparency})
		FadeTween.Completed:Connect(function()
			if Aimer:GetAttribute("Enabled") then return end
			Aimer.Visible = false
		end)
		FadeTween:Play()
	end)

	task.delay(1, function() AimerUI.Toggle(false) end)
end

return AimerUI