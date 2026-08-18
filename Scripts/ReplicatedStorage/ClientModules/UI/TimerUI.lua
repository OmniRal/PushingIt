-- OmniRal

local TimerUI = {}

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
--local TWEEN_STYLE = UI_Info.BaseTweenStyle
--local TWEEN_DIR = UI_Info.BaseTweenDir

local ON_POSITION = UDim2.fromScale(0.5, 0.05)
local OFF_POSITION = UDim2.fromScale(0.5, -0.1)

local ALLOW_TIMER_ON_SELF = false -- If true, the timer over avatars can be placed on the local player

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer

local Timer: any -- Personal timer; displayed at the top
local CharTimers: {[Player]: {Timer: any, Dead: boolean}} = {} -- Other players timers; billboard guis above their heads
local OtherPlayerConnections: {[Player]: {RBXScriptConnection?}} = {}

local DisplayOnlySeconds = true

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CalculateTimePassed(SavedTime: number, StartedAt: number): string
	local TotalSeconds = tostring(Workspace:GetServerTimeNow() - StartedAt + SavedTime)
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

local function UpdateCharTimer(Player: Player)
	if not Player then return end
	if not CharTimers[Player] then return end

	local ThisTimer = CharTimers[Player].Timer
	if not ThisTimer or CharTimers[Player].Dead then return end

	local GoalSize, GoalDirection = UDim2.fromScale(1, 0.5), Enum.EasingDirection.Out
	local GoalColor = ColorPalette.JetWhite.RGB

	if not Player:GetAttribute("TimerActive") then
		GoalColor = ColorPalette.MidGrey.RGB
	end

	if not Player:GetAttribute("PVPMode") or not LocalPlayer:GetAttribute("PVPMode") then
		GoalSize = UDim2.new(0, 0, 0, 0)
		GoalDirection = Enum.EasingDirection.In
	end

	--TweenService:Create(ThisTimer, TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Back, GoalDirection), {Size = GoalSize}):Play()
	TweenService:Create(ThisTimer.Num, TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Back, GoalDirection), {TextColor3 = GoalColor, Size = GoalSize}):Play()
end

-- Add a timer above another players head (not the LocalPlayer)
local function AddTimerForChar(Player: Player)
	if not Player then return end
	
	local Alive, Char: Model, Human: Humanoid, Root: BasePart = Utility.Players.CheckAlive(Player)
	if not Alive or not Char or not Human or not Root then return end

	Human.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	Human.NameDisplayDistance = 0
	Human.HealthDisplayDistance = 0
	
	if Char:GetAttribute("TimerSetupDone") then return end
	Char:SetAttribute("TimerSetupDone", true)
	
	local NewTimerUI = ReplicatedStorage.Assets.UIs.CharUI:Clone()
	NewTimerUI.PlayerName.Text = Player.Name
	NewTimerUI.Parent = Root
	
	if not CharTimers[Player] then
		CharTimers[Player] = {Timer = NewTimerUI, Dead = false}
	else
		CharTimers[Player].Timer = NewTimerUI
		CharTimers[Player].Dead = false
	end
	
	local DeathConnection: RBXScriptConnection? = nil
	
	-- When the player dies, remove that connection
	DeathConnection =  Human.HealthChanged:Connect(function()
		if CharTimers[Player] then
			CharTimers[Player].Dead = true
		end
		if not DeathConnection then return end
		DeathConnection:Disconnect()
	end)

	UpdateCharTimer(Player)
end

local function AddConnectionsToPlayer(Player: Player)
	if Player == LocalPlayer and not ALLOW_TIMER_ON_SELF then return end
	if OtherPlayerConnections[Player] then return end

	OtherPlayerConnections[Player] = {}

	-- Make sure atrributes are created
	while true do
		task.wait()
		if Player:GetAttribute("PVPMode") == nil then continue end
		if Player:GetAttribute("TimerActive") == nil then continue end
		break
	end
	
	-- Add timer above head connection
	table.insert(OtherPlayerConnections[Player], Player.CharacterAdded:Connect(function()
		task.delay(0.25, function()
			AddTimerForChar(Player)
		end)
	end))

	-- Update timer when PVP mode changes
	table.insert(OtherPlayerConnections[Player], Player:GetAttributeChangedSignal("PVPMode"):Connect(function()
		UpdateCharTimer(Player)
	end))

	-- Update timer when Timer active changes
	table.insert(OtherPlayerConnections[Player], Player:GetAttributeChangedSignal("TimerActive"):Connect(function() 
		UpdateCharTimer(Player)
	end))
	
	-- Incase it didn't work when the player first entered
	task.delay(3, function()
		AddTimerForChar(Player)
	end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


function TimerUI.RunHeartbeat()
	if not LocalPlayer:GetAttribute("TimerActive") then return end
	if not CharTimers then return end
	
	-- Update players timer first
	Timer.Num.Text = CalculateTimePassed(LocalPlayer:GetAttribute("SavedTime"), LocalPlayer:GetAttribute("TimerStartedAt"))
	
	--warn(LocalPlayer:GetAttribute("SavedTime"))
	for Player, Data in CharTimers do
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
	
	-- Show or hide the timer based on PVP mode
	LocalPlayer:GetAttributeChangedSignal("PVPMode"):Connect(function()
		Timer:SetAttribute("Enabled", LocalPlayer:GetAttribute("PVPMode"))

		-- Update timers for other players
		for _, OtherPlayer in Players:GetPlayers() do
			if not OtherPlayer then continue end
			if OtherPlayer == LocalPlayer then continue end
			UpdateCharTimer(OtherPlayer)
		end
	end)

	-- Make timer text white or grey based on if its active
	LocalPlayer:GetAttributeChangedSignal("TimerActive"):Connect(function()
		local GoalColor = ColorPalette.JetWhite.RGB
		if not LocalPlayer:GetAttribute("TimerActive") then
			GoalColor = ColorPalette.MidGrey.RGB
		end

		TweenService:Create(Timer.Num, TweenInfo.new(ANIM_TIME), {TextColor3 = GoalColor}):Play()
	end)
	
	Timer.Position = OFF_POSITION
	
	task.delay(1, function()
		Timer:SetAttribute("Enabled", LocalPlayer:GetAttribute("PVPMode"))
	end)
	
	-- Add a connection for when a player (re)spawns
	Players.PlayerAdded:Connect(function(Player: Player)
		task.spawn(function() AddConnectionsToPlayer(Player) end)
	end)
	
	-- Destroy old connections once a player leaves
	Players.PlayerRemoving:Connect(function(Player: Player)
		if not OtherPlayerConnections[Player] then return end

		for _, Connection in OtherPlayerConnections[Player] do
			if not Connection then continue end
			Connection:Disconnect()
		end

		OtherPlayerConnections[Player] = nil
	end)
	
	task.delay(3, function()
		-- Add the same stuff for existing players
		for _, Player in Players:GetPlayers() do
			if not Player then continue end
			warn("Adding for", Player)
			task.spawn(function() AddConnectionsToPlayer(Player) end)
		end
	end)
end

return TimerUI