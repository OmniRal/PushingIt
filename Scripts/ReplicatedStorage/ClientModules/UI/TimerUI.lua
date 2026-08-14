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
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

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
local OtherTimers: {[Player]: {Timer: any, Dead: boolean}} = {} -- Other players timers; billboard guis above their heads
local PlayerAddedTimerConnections: {[Player]: RBXScriptConnection?} = {}

local DisplayOnlySeconds = true

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CalculateTimePassed(SavedTime: number, StartedAt: number): string
	local TotalSeconds = tostring(os.clock() - StartedAt + SavedTime)
	local FinalVersion: string = ""
	
	local LeftToCheck = 3
	for n = 1, string.len(TotalSeconds) do
		local Char = string.sub(TotalSeconds, n, n)
		
		FinalVersion = FinalVersion .. Char
		
		if Char ~= "." and LeftToCheck >= 3 then continue end
		
		LeftToCheck -= 1
		if LeftToCheck <= 0 then break end
	end
	
	if not DisplayOnlySeconds then
		return Utility.ConvertSecondsToHMS(TotalSeconds) .. "." .. string.sub(FinalVersion, string.len(FinalVersion) - 1, string.len(FinalVersion))
	end
	
	return FinalVersion .. "s"
end

-- Add a timer above another players head (not the LocalPlayer)
local function AddTimerForChar(Player: Player)
	if not Player then return end
	if Player == LocalPlayer then return end
	
	local Alive, Char: Model, Human: Humanoid, Root: BasePart = Utility.Players.CheckAlive(Player)
	if not Alive or not Char or not Human or not Root then return end
	
	if Char:SetAttribute("TimerSetupDone") then return end
	
	local NewTimerUI = ReplicatedStorage.Assets.UIs.CharTimer:Clone()
	NewTimerUI.Name = "Timer"
	NewTimerUI.Parent = Root
	
	if not OtherTimers[Player] then
		OtherTimers[Player] = {Timer = NewTimerUI, Dead = false}
	else
		OtherTimers[Player].Timer = NewTimerUI
		OtherTimers[Player].Dead = false
	end
	
	local DeathConnection: RBXScriptConnection? = nil
	
	-- When the player dies, remove that connection
	DeathConnection =  Human.HealthChanged:Connect(function()
		if OtherTimers[Player] then
			OtherTimers[Player].Dead = true
		end
		if not DeathConnection then return end
		DeathConnection:Disconnect()
	end)
end

local function AddConnectionsToPlayer(Player: Player)
	--if Player == LocalPlayer then continue end
	
	PlayerAddedTimerConnections[Player] = Player.CharacterAdded:Connect(function()
		task.delay(0.25, function()
			AddTimerForChar(Player)
		end)
	end)
	
	-- Incase it didn't work when the player first entered
	task.delay(1, function()
		AddTimerForChar(Player)
	end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


function TimerUI.RunHeartbeat()
	if not LocalPlayer:GetAttribute("TimerActive") then return end
	if not OtherTimers then return end
	
	-- Update players timer first
	Timer.Num.Text = CalculateTimePassed(LocalPlayer:GetAttribute("SavedTime"), LocalPlayer:GetAttribute("TimerStartedAt"))
	
	--warn(LocalPlayer:GetAttribute("SavedTime"))
	for Player, Data in OtherTimers do
		if not Player or not Data then continue end
		if Data.Dead then
			Data.Timer = nil; continue
		end
		
		local Active = Player:GetAttribute("TimerActive")
		if not Active then continue end
		
		local SavedTime, StartedAt = Player:GetAttribute("SavedTime"), Player:GetAttribute("TimerStartedAt")
		if not SavedTime or not StartedAt then continue end
		
		Data.Timer.Num.Text = CalculateTimePassed(SavedTime, StartedAt)
	end
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
	
	-- Add a connection for when a player (re)spawns
	Players.PlayerAdded:Connect(function(Player: Player)
		if Player == LocalPlayer then return end
		PlayerAddedTimerConnections[Player] = Player.CharacterAdded:Connect(function()
			task.delay(0.25, function()
				AddTimerForChar(Player)
			end)
		end)
		
		-- Incase it didn't work when the player first entered
		task.delay(3, function()
			AddTimerForChar(Player)
		end)
	end)
	
	-- Destroy the connection once a player leaves
	Players.PlayerRemoving:Connect(function(Player: Player)
		local Connection = PlayerAddedTimerConnections[Player]
		if not Connection then return end
		Connection:Disconnect()
		
		PlayerAddedTimerConnections[Player] = nil
	end)
	
	-- Add the same stuff for existing players
	for _, Player in Players:GetPlayers() do
		if not Player then continue end
		--if Player == LocalPlayer then continue end
		
		PlayerAddedTimerConnections[Player] = Player.CharacterAdded:Connect(function()
			task.delay(0.25, function()
				AddTimerForChar(Player)
			end)
		end)
		
		-- Incase it didn't work when the player first entered
		task.delay(1, function()
			AddTimerForChar(Player)
		end)
	end
end

return TimerUI