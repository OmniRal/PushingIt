-- OmniRal

local PushService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)
local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PUSH_RANGE = 7
local RESET_NPC = false -- Puts the NPC back to its original position after pushed; good for testing
local BASE_POWER = 75

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PlayerVals: {
    [Player]: {
		Started: number, -- Time score run was started
        Points: number,
        Streak: number, -- Amount of NPCs / players that have been pushed in a row
		Multiplier: number,
        PushChargeStarted: number,
    }
} = {}

local ModelRagdolls: {
    [Model]: {Pushers: {Player}}
} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CheckAliveAndClose(Root: BasePart, Model: Model): (boolean, BasePart?)
    if not Model then return false end

    --if Model:GetAttribute("Ragdoll") then return false end

    local OtherHuman, OtherRoot = Model:FindFirstChild("Humanoid") :: Humanoid, Model:FindFirstChild("HumanoidRootPart") :: BasePart
    if not OtherHuman or not OtherRoot then return false end

    if OtherHuman.Health <= 0 then return false end

    local FrontPos = (Root.CFrame * CFrame.new(0, 0, -2)).Position
    if (FrontPos - OtherRoot.Position).Magnitude > PUSH_RANGE then return false end

    return true, OtherRoot
end

local function UpdatePlayerVals()
	for _, ThisPlayer in Players:GetPlayers() do
		if not ThisPlayer then continue end
		local Vals = PlayerVals[ThisPlayer]
		if not Vals then continue end

		if Vals.Started <= 0 then continue end

		if os.clock() < Vals.Started + SharedGlobalValues.ScoreFinalizeTime then continue end

		PushService.ResetScore(ThisPlayer)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function PushService.PushModel(Player: Player?, Model: Model, RootModel: Model?): boolean
    if not Model then return false end
    if not Model.PrimaryPart then return false end
    if Model:GetAttribute("Locked") or Model:GetAttribute("Ragdoll") then return false end

    if not Player and RootModel and ModelRagdolls[RootModel] and #ModelRagdolls[RootModel].Pushers > 0 then
        Player = ModelRagdolls[RootModel].Pushers[1]
    end

    if not Player then return false end
    if Player.Name == Model.Name then return false end

    if not ModelRagdolls[Model] then
        ModelRagdolls[Model] = {
            Pushers = {}
        }

        local Human = Model:FindFirstChild("Humanoid") :: Humanoid
        if Human then
            Human.HealthChanged:Connect(function()
                if Human.Health > 0 then return end
                ModelRagdolls[Model] = nil
            end)
        end
    end

    if not table.find(ModelRagdolls[Model].Pushers, Player) then
        table.insert(ModelRagdolls[Model].Pushers, Player)
    end
    
    task.spawn(function()
        local OriginCF = Model:GetPivot()
        Model:SetAttribute("OriginCF", OriginCF)
        Model:SetAttribute("Ragdoll", true)

        if not Model:GetAttribute("StartOriginCF") then
            Model:SetAttribute("StartOriginCF", OriginCF)
        end
        
        task.wait(5)
        
        Model:SetAttribute("Ragdoll", false)
        
        if not RESET_NPC then return end
        Model:SetAttribute("Locked", true)
        task.wait()

        Model.PrimaryPart.Anchored = true

        task.wait()

        Model:PivotTo(OriginCF * CFrame.new(0, 1, 0))
        Model.PrimaryPart.Anchored = false
        Model:SetAttribute("Locked", false)
    end)

    return  true
end

function PushService.GetPushers(Model: Model): {Player}?
    if not Model then return end
    if not ModelRagdolls[Model] then return end
    if not ModelRagdolls[Model].Pushers then return end

    return ModelRagdolls[Model].Pushers
end

-- Player tries to push an NPC or another player
function PushService.AttemptPush(Player: Player)
    local PVals, PData = PlayerVals[Player], DataService.GetSkills(Player)
    if not PVals or not PData then return end

    local Alive: boolean, _, Root: BasePart = Utility.Players.CheckAlive(Player)
    if not Alive or not Root then return end

    local TimePassed = os.clock() - PVals.PushChargeStarted
    local SecondPerGain = SharedGlobalValues.ChargeGain_Base - (PData.ChargeSpeed * SharedGlobalValues.ChargeGain_Subtract)
    local Level = math.clamp((TimePassed / SecondPerGain), 0.1, PData.ChargePower)
    local Power = BASE_POWER * math.clamp(Level, 0.1, 6)

	warn("___")
	print("Level: ", Level)
	print("Power: ", Power)

    -- First look for NPCs to push
    for _, NPC: Model in CollectionService:GetTagged("NPC") do
        if not NPC then continue end
        local CanPush, OtherRoot = CheckAliveAndClose(Root, NPC)
        if not CanPush or not OtherRoot  then continue end

        task.spawn(function()
            PushService.PushModel(Player, NPC)
            task.wait()
            OtherRoot.AssemblyLinearVelocity = Root.CFrame.LookVector * Power + Vector3.new(0, Power * 0.2, 0)
        end)
    end

    -- Then look for other players to push
end

-- Add points for specific players
-- @ThesePlayers = Which players should be affected
-- @Add = How many points
-- @MultiplierGain = How much the multiplier should go up by
-- @PointPositions = Worldspace positions where the point originated from
-- @KeepStartedTimeSame = If true, the Started time will NOT get set to os.clock(); which would reset the timer
-- @IgnoreMultiplier = Does not add the multiplier to the final score to give
function PushService.ScoreUp(ThesePlayers: {Player}, PointGain: number, MultiplierGain: number?, PointPositions: {Vector3}?, KeepStartedTimeSame: boolean?, IgnoreMultiplier: boolean?)	
	for n, ThisPlayer in ipairs(ThesePlayers) do
		local Vals = PlayerVals[ThisPlayer]
        if not Vals then continue end

		if KeepStartedTimeSame ~= true then
			Vals.Started = os.clock()
			Vals.Streak += 1
			Vals.Multiplier += MultiplierGain or 0

			if MultiplierGain == SharedGlobalValues.MultiplierGainPerConsecutiveHit and PointPositions and PointPositions[n] then
    			Remotes.WorldUIService.SpawnTextDisplay:Fire(ThisPlayer, "NPCStreakAdd", PointPositions[n], {Amount = SharedGlobalValues.BonusPointsPerConsecutiveHit})
			end
		end

		local Final = PointGain
		if IgnoreMultiplier ~= true then
			Final = PointGain + (math.floor(PointGain * Vals.Multiplier))
		end
        Vals.Points += Final

		Remotes.PushService.ScoreChanged:Fire(ThisPlayer, Vals.Points, Vals.Streak, Vals.Multiplier)
    end
end

function PushService.ResetScore(ThisPlayer: Player)
	if not ThisPlayer then return end

	local Vals = PlayerVals[ThisPlayer]
	if not Vals then return end

	-- Add current points to grand total points
	DataService.IncrementIndex(ThisPlayer, "Points", Vals.Points)
    DataService.IncrementIndex(ThisPlayer, "XP", Vals.Points)

	Vals.Started = 0 -- Means no score run
	Vals.Points = 0
	Vals.Streak = 0
	Vals.Multiplier = 0

	Remotes.PushService.ScoreChanged:Fire(ThisPlayer, 0, 0, 0)
end

function PushService.StartTimer(ThisPlayer: Player)
	-- Make sure the player is in PVP mode first
	local PVPMode = DataService.GetIndex(ThisPlayer, "PVPMode")
	if not PVPMode then return end

	ThisPlayer:SetAttribute("TimerActive", true)
	ThisPlayer:SetAttribute("SavedTime", 0)

	-- Make sure timer isn't already running; really should only be relevant when the player first joins
	local IsActive = DataService.GetIndex(ThisPlayer, "TimerActive")
	if IsActive then
		local SavedTime = DataService.GetIndex(ThisPlayer, "SavedTime")
		ThisPlayer:SetAttribute("SavedTime", SavedTime)
	end

	DataService.SetIndex(ThisPlayer, "TimerActive", true, true)
	DataService.SetIndex(ThisPlayer, "TimerStartedAt", os.clock(), true)

	ThisPlayer:SetAttribute("TimerStartedAt", os.clock())
end

function PushService.StopTimer(ThisPlayer: Player)
	DataService.SetIndex(ThisPlayer, "TimerActive", false, true)
	ThisPlayer:SetAttribute("TimerActive", false)
end

function PushService:Init()
    Remotes:CreateToClient("ScoreChanged", {"number", "number", "number"})

    -- Sets the start push charge time for the player
    Remotes:CreateToServer("StartPushCharge", {}, "Reliable", function(Player: Player)
        if not PlayerVals[Player] then return end
        PlayerVals[Player].PushChargeStarted = os.clock()
    end)

    -- Upon releasing the charge; push the player
    Remotes:CreateToServer("AttemptPush", {}, "Reliable", function(Player: Player)
        PushService.AttemptPush(Player)
    end)
end

function PushService:Deferred()
	task.spawn(function()
		while true do
			task.wait(1)
			UpdatePlayerVals()
		end
	end)
end

function PushService.PlayerAdded(Player: Player)
    if PlayerVals[Player] then return end
    PlayerVals[Player] = {
		Started = 0,
        Points = 0,
        Streak = 0,
		Multiplier = 0,
        PushChargeStarted = 0
    }

	local PVPMode = DataService.GetIndex(Player, "PVPMode")
	Player:SetAttribute("PVPMode", PVPMode)

	local CheckedStartTimer = false
	Player.CharacterAdded:Connect(function(Char: Model)
		local Human, Root = Char:WaitForChild("Humanoid"), Char:WaitForChild("HumanoidRootPart")
		if not Human or not Root then return end

		CheckedStartTimer = true
		PushService.StartTimer(Player)
	end)

	if CheckedStartTimer then return end
	PushService.StartTimer(Player)
end

function PushService.PlayerRemoving(Player: Player)
    if not PlayerVals[Player] then return end
    PlayerVals[Player] = nil
end

return PushService