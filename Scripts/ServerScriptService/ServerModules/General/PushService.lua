-- OmniRal

local PushService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ModerationService = game:GetService("ModerationService")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PUSH_RANGE = 7
local RESET_NPC = true -- Puts the NPC back to its original position after pushed; good for testing
local BASE_POWER = 75

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PlayerVals: {
    [Player]: {
        Points: number,
        Streak: number,
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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function PushService.PushModel(Player: Player?, Model: Model, RootModel: Model?)
    if not Model then return end
    if not Model.PrimaryPart then return end
    if Model:GetAttribute("Locked") then return end

    if not Player and RootModel and ModelRagdolls[RootModel] and #ModelRagdolls[RootModel].Pushers > 0 then
        Player = ModelRagdolls[RootModel].Pushers[1]
    end

    if not Player then return end
    if Player.Name == Model.Name then return end

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

        if not RESET_NPC then return end
        
        task.wait(5)

        Model:SetAttribute("Locked", true)
        Model:SetAttribute("Ragdoll", false)

        task.wait()

        Model.PrimaryPart.Anchored = true

        task.wait()

        Model:PivotTo(OriginCF * CFrame.new(0, 1, 0))
        Model.PrimaryPart.Anchored = false
        Model:SetAttribute("Locked", false)
    end)
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
    local SecondPerGain = 1.4 - (PData.Speed * 0.2)
    local Level = math.clamp(math.floor(TimePassed / SecondPerGain), 1, 5)
    local Power = BASE_POWER * math.clamp(Level, 1, 6)

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

function PushService.ScoreUp(ThesePlayers: {Player}, Add: number)
    for _, Player in ThesePlayers do
        if not PlayerVals then continue end
        if not PlayerVals[Player] then continue end
        PlayerVals[Player].Points += Add
    end
end

function PushService:Init()
    Remotes:CreateToClient("ScoreChanged", {"number"})
    Remotes:CreateToClient("ScoreUp", {"number"})

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
end

function PushService.PlayerAdded(Player: Player)
    if PlayerVals[Player] then return end
    PlayerVals[Player] = {
        Points = 0,
        Streak = 0,
        PushChargeStarted = 0
    }
end

function PushService.PlayerRemoving(Player: Player)
    if not PlayerVals[Player] then return end
    PlayerVals[Player] = nil
end

return PushService