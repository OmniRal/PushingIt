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
local New = require(ReplicatedStorage.Source.Pronghorn.New)

local ServerGlobalValues = require(ServerScriptService.Source.ServerModules.Top.ServerGlobalValues)
local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)

local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PUSH_RANGE = 7
local RESET_NPC = false -- Puts the NPC back to its original position after pushed; good for testing
local BASE_POWER = 75

local BASE_DODGE_FORCE = 50
local INC_DODGE_FORCE = 15
local DODGE_DURATION = 0.1

local RAGDOLL_TIME = 3 -- How long the player stays a ragdoll before they can get up
local IMMUNSE_TIME = 3 -- After a player comes out of being ragdolled, how long are they immune

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
		PushDone: number, -- When the push was completed; used for the push cooldown

		DodgeDone: number, -- When the dodge was completed; used for the dodge cooldown
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
	if Model:GetAttribute("Dodging") then return false end
	if Model:GetAttribute("Immune") then return false end
	
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

local function RunResetNPCPositioning(Model: Model)
	if not Model.PrimaryPart then return end

	-- Save NPCs original place they got pushed from
	local OriginCF = Model:GetPivot()
	Model:SetAttribute("OriginCF", OriginCF)
	Model:SetAttribute("Ragdoll", true)
	
	if not Model:GetAttribute("StartOriginCF") then
		Model:SetAttribute("StartOriginCF", OriginCF)
	end
	
	task.wait(5)
	
	Model:SetAttribute("Ragdoll", false)
	
	-- Reset them back to that location when getting up
	Model:SetAttribute("Locked", true)
	task.wait()
	
	Model.PrimaryPart.Anchored = true
	
	task.wait()
	
	Model:PivotTo(OriginCF * CFrame.new(0, 1, 0))
	Model.PrimaryPart.Anchored = false
	Model:SetAttribute("Locked", false)
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
			-- Remove the NPC from the list when they die
			Human.HealthChanged:Connect(function()
				if Human.Health > 0 then return end
				ModelRagdolls[Model] = nil
			end)
			
			-- Reset the pushers for this NPC when they stop ragdolling
			Model:GetAttributeChangedSignal("Ragdoll"):Connect(function()
				if not Model then return end
				if Model:GetAttribute("Ragdoll") ~= false then return end
				if not ModelRagdolls[Model] then return end
				if not ModelRagdolls[Model].Pushers then return end
				table.clear(ModelRagdolls[Model].Pushers)
			end)
		end
	end
	
	-- Add the player as a pusher
	if not table.find(ModelRagdolls[Model].Pushers, Player) then
		table.insert(ModelRagdolls[Model].Pushers, Player)
	end
	
	task.spawn(function()
		if not RESET_NPC then
			Model:SetAttribute("Ragdoll", true)
			task.wait(5)
			Model:SetAttribute("Ragdoll", false)
		else
			-- Move NPC back where they were
			RunResetNPCPositioning(Model)
		end
	end)
	
	return  true
end

function PushService.GetPushers(Model: Model): {Player}?
	if not Model then return end
	if not ModelRagdolls[Model] then return end
	if not ModelRagdolls[Model].Pushers then return end
	
	return ModelRagdolls[Model].Pushers
end

function PushService.StartPushCharge(Player: Player)
	local PVals, PData = PlayerVals[Player], DataService.GetSkills(Player)
	if not PVals or not PData then return end
	
	local Alive: boolean, _, Root: BasePart = Utility.Players.CheckAlive(Player)
	if not Alive or not Root then return end
	
	local CooldownTime = SharedGlobalValues.PushCooldown_Base - (SharedGlobalValues.PushCooldown_Subtract * (PData.PushCooldown - 1))
	if os.clock() < PVals.PushDone + CooldownTime then return -1 end

	PVals.PushChargeStarted = os.clock()

	return true
end

-- Player tries to push an NPC or another player
function PushService.AttemptPush(Player: Player, AimDirection: number)
	local PVals, PData = PlayerVals[Player], DataService.GetSkills(Player)
	if not PVals or not PData then return end
	
	local Alive: boolean, _, _, Root: BasePart = Utility.Players.CheckAlive(Player)
	if not Alive or not Root then return end
	
	local CooldownTime = SharedGlobalValues.PushCooldown_Base - (SharedGlobalValues.PushCooldown_Subtract * (PData.PushCooldown - 1))
	if os.clock() < PVals.PushDone + CooldownTime then return -1 end
	
	PVals.PushDone = os.clock()

	local TimePassed = os.clock() - PVals.PushChargeStarted
	local SecondPerGain = SharedGlobalValues.ChargeGain_Base - (PData.ChargeSpeed * SharedGlobalValues.ChargeGain_Subtract)
	local Power = math.clamp((TimePassed / SecondPerGain), 0.1, PData.ChargePower)
	
	local FinalPower = BASE_POWER * math.clamp(Power, 0.1, 6)
	if ServerGlobalValues.NPCs_TestMode then FinalPower += 200 end
	
	warn("___")
	print("Level: ", Power)
	print("Power: ", FinalPower)

	local RootCF = Root.CFrame
	if AimDirection == 1 then
		RootCF *= CFrame.Angles(math.rad(75), 0, 0)
	elseif AimDirection == 2 then
		RootCF *= CFrame.Angles(math.rad(45), 0, 0)
	elseif AimDirection == 4 then
		RootCF *= CFrame.Angles(math.rad(-75), 0, 0)
	end

	-- First, look for other players to push
	if Player:GetAttribute("PVPMode") then
		for _, OtherPlayer in Players:GetPlayers() do
			if not OtherPlayer then continue end
			if OtherPlayer == Player then continue end
			if not OtherPlayer:GetAttribute("PVPMode") then continue end
			if not OtherPlayer.Character then continue end
			local CanPush, OtherRoot = CheckAliveAndClose(Root, OtherPlayer.Character)
			if not CanPush or not OtherRoot then continue end

			task.spawn(function()
				-- Push player
				PushService.PushModel(Player, OtherPlayer.Character)

				OtherRoot.AssemblyLinearVelocity = RootCF.LookVector * FinalPower + Vector3.new(0, FinalPower * 0.2, 0)

				-- Stop them from ragdolling, but make them immune
				task.wait(RAGDOLL_TIME)
				if not OtherPlayer then return end
				if not OtherPlayer.Character then return end
				OtherPlayer.Character:SetAttribute("Ragdoll", false)
				OtherPlayer.Character:SetAttribute("Immune", true)

				-- Take away immunity
				task.wait(IMMUNSE_TIME)
				if not OtherPlayer then return end
				if not OtherPlayer.Character then return end
				OtherPlayer.Character:SetAttribute("Immune", false)
			end)
		end
	end

	-- Second, look for NPCs to push
	for _, NPC: Model in CollectionService:GetTagged("NPC") do
		if not NPC then continue end
		local CanPush, OtherRoot = CheckAliveAndClose(Root, NPC)
		if not CanPush or not OtherRoot  then continue end
		
		task.spawn(function()
			PushService.PushModel(Player, NPC)
			DataService.AddNPCPushCount(Player, NPC.Name)
			task.wait()
			OtherRoot.AssemblyLinearVelocity = RootCF.LookVector * FinalPower + Vector3.new(0, FinalPower * 0.2, 0)
		end)
	end

	return true
end

function PushService.AttemptDodge(Player: Player)
	local PVals, PData = PlayerVals[Player], DataService.GetSkills(Player)
	if not PVals or not PData then return end
	
	local Alive: boolean, Char: Model, _, Root: BasePart = Utility.Players.CheckAlive(Player)
	if not Alive or not Char then return end

	local CooldownTime = SharedGlobalValues.DodgeCooldown_Base - (SharedGlobalValues.DodgeCooldown_Subtract * (PData.DodgeCooldown - 1))
	if os.clock() < PVals.DodgeDone + CooldownTime then return -1 end

	task.spawn(function()
		Char:SetAttribute("Dodging", true)

		local MaxPower = BASE_DODGE_FORCE + (INC_DODGE_FORCE * (PData.DodgeRange - 1))

		-- Body movers life cycle
		local LineVel = New.Instance("LinearVelocity", Char, "DodgeVelocity", {Attachment0 = Root:FindFirstChild("RootAttachment"), 
			ForceLimitMode = Enum.ForceLimitMode.PerAxis, MaxAxesForce = Vector3.new(1000000, 0, 1000000), VectorVelocity = Root.CFrame.LookVector * MaxPower})
		local AlignPos = New.Instance("AlignPosition", Char, "DodgeAlign", {Attachment0 = Root:FindFirstChild("RootAttachment"), Mode = Enum.PositionAlignmentMode.OneAttachment,
			Position = Root.Position, ForceLimitMode = Enum.ForceLimitMode.PerAxis, MaxAxesForce = Vector3.new(0, 1000000, 0), Responsiveness = 100})
		
		task.wait(DODGE_DURATION)

		LineVel:Destroy()
		AlignPos:Destroy()

		task.wait(DODGE_DURATION * 2)

		Char:SetAttribute("Dodging", false)
	end)

	return true
end

-- Add points for specific players
-- @ThesePlayers = Which players should be affected
-- @Add = How many points
-- @MultiplierGain = How much the multiplier should go up by
-- @PointPosition = Worldspace position where the point originated from
-- @KeepStartedTimeSame = If true, the Started time will NOT get set to os.clock(); which would reset the timer
-- @IgnoreMultiplier = Does not add the multiplier to the final score to give
function PushService.ScoreUp(ThesePlayers: {Player}, PointGain: number, MultiplierGain: number?, PointPosition: Vector3?, KeepStartedTimeSame: boolean?, IgnoreMultiplier: boolean?)	
	for _, ThisPlayer in ipairs(ThesePlayers) do
		local Vals = PlayerVals[ThisPlayer]
		if not Vals then continue end
		
		if KeepStartedTimeSame ~= true then
			Vals.Started = os.clock()
			Vals.Streak += 1
			Vals.Multiplier += MultiplierGain or 0
			
			if MultiplierGain == SharedGlobalValues.MultiplierGainPerConsecutiveHit and PointPosition then
				Remotes.Server.WorldUIService.SpawnTextDisplay:Fire(ThisPlayer, "NPCStreakAdd", PointPosition, {Amount = SharedGlobalValues.BonusPointsPerConsecutiveHit})
			end
		end
		
		local Final = PointGain
		if IgnoreMultiplier ~= true then
			Final = PointGain + (math.floor(PointGain * Vals.Multiplier))
		end
		Vals.Points += Final
		
		Remotes.Server.PushService.ScoreChanged:Fire(ThisPlayer, Vals.Points, Vals.Streak, Vals.Multiplier)
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
	
	Remotes.Server.PushService.ScoreChanged:Fire(ThisPlayer, 0, 0, 0)
end

function PushService.PlayerAdded(Player: Player)
	if PlayerVals[Player] then return end
	PlayerVals[Player] = {
		Started = 0,
		Points = 0,
		Streak = 0,
		Multiplier = 0,

		PushChargeStarted = 0,
		PushDone = 0,

		DodgeDone = 0,
	}
	
	local PVPMode = DataService.GetIndex(Player, "PVPMode")
	Player:SetAttribute("PVPMode", PVPMode)
	
	local CheckedStartTimer = false
	Player.CharacterAdded:Connect(function(Char: Model)
		local Human, Root = Char:WaitForChild("Humanoid"), Char:WaitForChild("HumanoidRootPart")
		if not Human or not Root then return end
		
		CheckedStartTimer = true
		DataService.StartTimer(Player)
	end)
	
	if CheckedStartTimer then return end
	DataService.StartTimer(Player)
end

function PushService.PlayerRemoving(Player: Player)
	if not PlayerVals[Player] then return end
	PlayerVals[Player] = nil
end

function PushService:Init()
	Remotes.Server:CreateToClient("ScoreChanged", {"number", "number", "number"})
	
	-- Sets the start push charge time for the player
	Remotes.Server:CreateToServer("StartPushCharge", {}, "Returns", function(Player: Player)
		return PushService.StartPushCharge(Player)
	end)
	
	-- Upon releasing the charge; push the player
	Remotes.Server:CreateToServer("AttemptPush", {"number"}, "Returns", function(Player: Player, AimDirection: number)
		return PushService.AttemptPush(Player, AimDirection)
	end)

	Remotes.Server:CreateToServer("AttemptDodge", {}, "Returns", function(Player: Player)
		return PushService.AttemptDodge(Player)
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

return PushService