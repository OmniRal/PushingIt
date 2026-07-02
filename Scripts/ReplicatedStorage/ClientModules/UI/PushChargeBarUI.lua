-- OmniRal

local PushChargeBarUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local Global = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ANIM_TIME = UI_Info.BaseAnimTime
local TWEEN_STYLE = UI_Info.BaseTweenStyle
local TWEEN_DIR = UI_Info.BaseTweenDir

local ON_POSITION = UDim2.fromScale(0.5, 0.7)
local OFF_POSITION = UDim2.fromScale(0.5, 0.75)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DelayToggleThread: thread?

local ToggleTween: any
local ChargeTween: any

local Bar: any

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function ToggleEnabled()
	local GoalPosition, GoalTransparency = ON_POSITION, 0
	local EasingStyle, EasingDirection = Enum.EasingStyle.Back, Enum.EasingDirection.Out
	
	if Bar:GetAttribute("Enabled") then
		Bar.Visible = true
	else
		GoalPosition = OFF_POSITION
		GoalTransparency = 1

		EasingStyle = TWEEN_STYLE
		EasingDirection = TWEEN_DIR
	end

	if ToggleTween then ToggleTween:Pause(); ToggleTween:Destroy(); ToggleTween = nil end

	ToggleTween = TweenService:Create(Bar, TweenInfo.new(ANIM_TIME, EasingStyle, EasingDirection), {Position = GoalPosition, GroupTransparency = GoalTransparency}) :: Tween
	ToggleTween.Completed:Connect(function() 
		if not ToggleTween then return end
		if Bar:GetAttribute("Enabled") then return end
		Bar.Visible = false
	end)

	ToggleTween:Play()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function PushChargeBarUI.UpdateDivBars()
	for _, OldDiv in Bar:GetChildren() do
		if OldDiv.Name ~= "Div" then continue end
		OldDiv:Destroy()
	end

	local ChargePower = PlayerInfo.Data.Skills.ChargePower
	if ChargePower <= 1 then return end

	local Spacing = 1 / ChargePower

	for x = 1, ChargePower - 1 do
		local NewDiv = Bar.OGDiv:Clone()
		NewDiv.Name = "Div"
		NewDiv.Position = UDim2.fromScale(Spacing * x, 0)
		NewDiv.Visible = true
		NewDiv.Parent = Bar
	end
end

function PushChargeBarUI.StartCharge(ChargeSpeed: number, ChargePower: number)
	PushChargeBarUI.StopCharge()

	Bar.Fill.Size = UDim2.fromScale(0, 1)
	Bar:SetAttribute("Enabled", true)

	local Time = SharedGlobalValues.ChargeGain_Base - (ChargeSpeed * SharedGlobalValues.ChargeGain_Subtract)
	Time *= ChargePower

	ChargeTween = TweenService:Create(Bar.Fill, TweenInfo.new(Time, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 1)})
	ChargeTween:Play()
end

function PushChargeBarUI.StopCharge()
	if ChargeTween then ChargeTween:Pause(); ChargeTween:Destroy(); ChargeTween = nil end
end

function PushChargeBarUI.Toggle(SetTo: boolean, Delay: number?)
	if not Delay then
		Bar:SetAttribute("Enabled", SetTo)
	else
		if DelayToggleThread then task.cancel(DelayToggleThread); DelayToggleThread = nil end
		task.delay(Delay, function()
			Bar:SetAttribute("Enabled", SetTo)
		end)
	end
end

function PushChargeBarUI.Setup(Gui: ScreenGui)
	Bar = Gui:FindFirstChild("PushChargeBar") :: CanvasGroup
	if not Bar then return end

	Bar:SetAttribute("Enabled", false)

	Bar:GetAttributeChangedSignal("Enabled"):Connect(function()
		ToggleEnabled()
	end)

	Bar:GetPropertyChangedSignal("GroupTransparency"):Connect(function() 
		Bar.Stroke.Transparency = Bar.GroupTransparency
	end)

	Bar.Position = OFF_POSITION
	Bar.GroupTransparency = 1
	Bar.Visible = false
end

return PushChargeBarUI