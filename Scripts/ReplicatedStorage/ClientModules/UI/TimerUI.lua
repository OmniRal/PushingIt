-- OmniRal

local TimerUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
--local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ANIM_TIME = UI_Info.BaseAnimTime
--local TWEEN_STYLE = UI_Info.BaseTweenStyle
--local TWEEN_DIR = UI_Info.BaseTweenDir

local ON_POSITION = UDim2.fromScale(0.5, 0.05)
local OFF_POSITION = UDim2.fromScale(0.5, -0.1)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer

local Timer: any -- Personal timer; displayed at the top
local OtherTimers: {} = {} -- Other players timers; billboard guis above their heads

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CalculateTimePassed(SavedTime: number, StartedAt: number): string
	local Passed = tostring(os.clock() - StartedAt + SavedTime)
	local FinalVersion: string = ""

	local LeftToCheck = 3
	for n = 1, string.len(Passed) do
		local Char = string.sub(Passed, n, n)
		
		FinalVersion = FinalVersion .. Char
		
		if Char ~= "." and LeftToCheck >= 3 then continue end
		
		LeftToCheck -= 1
		if LeftToCheck <= 0 then break end
	end

	return FinalVersion .. "s"
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


function TimerUI.RunHeartbeat()
	if not LocalPlayer:GetAttribute("TimerActive") then return end
	if not OtherTimers then return end

	-- Update players timer first
	Timer.Num.Text = CalculateTimePassed(LocalPlayer:GetAttribute("SavedTime"), LocalPlayer:GetAttribute("TimerStartedAt"))
end

function TimerUI.Setup(Gui: ScreenGui)
	Timer = Gui:FindFirstChild("Timer") :: Frame
	if not Timer then return end

	Timer:SetAttribute("Enabled", false)
	Timer:GetAttributeChangedSignal("Enabled"):Connect(function()
		local Enabled = Timer:GetAttribute("Enabled")
		local GoalPosition = if Enabled then ON_POSITION else OFF_POSITION
		local EasingDirection = if Enabled then Enum.EasingDirection.Out else Enum.EasingDirection.In

		TweenService:Create(Timer, TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Back, EasingDirection), {Position = GoalPosition}):Play()
	end)

	LocalPlayer:GetAttributeChangedSignal("PVPMode"):Connect(function()
		Timer:SetAttribute("Enabled", LocalPlayer:GetAttribute("PVPMode"))
	end)

	Timer.Position = OFF_POSITION

	task.delay(1, function()
		Timer:SetAttribute("Enabled", LocalPlayer:GetAttribute("PVPMode"))
	end)
end

return TimerUI