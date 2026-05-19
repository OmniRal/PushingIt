-- OmniRal

local NPCService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)

local NPCInfo = require(ReplicatedStorage.Source.SharedModules.Info.NPCInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SpawnPoints: {CFrame} = {}

local NPCs: {
    [Model]: {
        Dead: boolean
    }
} = {}
local NPCFolder: Folder

local Assets = ServerStorage.Assets
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetSpawnPoints()
    for _, Spawn: BasePart in CollectionService:GetTagged("NPCSpawn") do
        if not Spawn then continue end
        table.insert(SpawnPoints, Spawn.CFrame)
        Spawn:Destroy()
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function NPCService.Spawn(ThisPoint: CFrame?, Rarity: NPCInfo.NPCRariry?, Name: string?)
    if not ThisPoint then
        ThisPoint = SpawnPoints[RNG:NextInteger(1, #SpawnPoints)]
    end

    local Info = NPCInfo.Common.John

    local NewNPC = Assets.Misc.BaseNPC:Clone()
    
    local Description = Instance.new("HumanoidDescription")
    Description.Face = Info.FaceID
    
    Description.HeadColor = Info.HeadColor or Info.SkinColor
    Description.TorsoColor = Info.TorsoColor or Info.SkinColor
    Description.LeftArmColor = Info.LeftArmColor or Info.SkinColor
    Description.RightArmColor = Info.RightArmColor or Info.SkinColor
    Description.LeftLegColor = Info.LeftLegColor or Info.SkinColor
    Description.RightLegColor = Info.RightLegColor or Info.SkinColor

    Description.HatAccessory = Info.Hat or 0
    Description.HairAccessory = Info.Hair or 0
    Description.Shirt = Info.Shirt or 0
    Description.Pants = Info.Pants or 0

    Description.Parent = NewNPC
    NewNPC.Parent = NPCFolder
    
    local Success, Error = pcall(function() 
        NewNPC.Humanoid:ApplyDescriptionAsync(Description)
    end)

    if not Success then
        warn(Error)
        return
    end

    NewNPC:PivotTo(ThisPoint)

    NPCs[NewNPC] = {
        Dead = false
    }
end

function NPCService:Init()
    NPCFolder = New.Instance("Folder", "NPCs", Workspace)
end

function NPCService:Deferred()
    GetSpawnPoints()

    NPCService.Spawn()
end

return NPCService