-- OmniRal

local PushService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PUSH_RANGE = 7
local RESET_NPC = true -- Puts the NPC back to its original position after pushed; good for testing

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

function PushService.AttemptPush(Player: Player, Power: number)
    local Alive: boolean, _, Root: BasePart = Utility.Players.CheckAlive(Player)
    if not Alive or not Root then return end

    -- First look for NPCs to push
    for _, NPC: Model in CollectionService:GetTagged("NPC") do
        if not NPC then continue end
        local CanPush, OtherRoot = CheckAliveAndClose(Root, NPC)
        if not CanPush or not OtherRoot  then continue end

        task.spawn(function()
            local OriginCF = NPC:GetPivot()

            NPC:SetAttribute("Ragdoll", true)
            task.wait()
            OtherRoot.AssemblyLinearVelocity = Root.CFrame.LookVector * Power + Vector3.new(0, Power * 0.2, 0)

            if not RESET_NPC then return end

            task.wait(5)

            NPC:SetAttribute("Ragdoll", false)
            task.wait()
            NPC:PivotTo(OriginCF)
        end)
    end

    -- Then look for other players to push
end

function PushService:Init()
    Remotes:CreateToServer("AttemptPush", {"number"}, "Reliable", function(Player: Player, Power: number)
        PushService.AttemptPush(Player, Power)
    end)
end

function PushService:Deferred()
end

return PushService