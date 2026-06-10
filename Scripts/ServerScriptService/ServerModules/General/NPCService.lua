-- OmniRal

local NPCService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RemoteCursorService = game:GetService("RemoteCursorService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)

local NPCInfo = require(ReplicatedStorage.Source.SharedModules.Info.NPCInfo)

local RagdollService = require(ServerScriptService.Source.ServerModules.General.RagdollService)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local USE_DEFAULT = true -- Set this to true when you want all NPCs to spawn as the one below
local DEFAULT_NPC = {Rarity = "Common", Name = "John"} -- Change this to test a specific NPC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SpawnPoints: {CFrame} = {}
local SpawnNames: {[string]: {CFrame}} = {}

local NPCs: {
    [Model]: {
        Name: string,
        Movement: NPCInfo.NPCMovement,

        Human: Humanoid,

        GoalNode: string,
        GoalPoint: CFrame, -- Which point the NPC should walk to
        ReachedPoint: false, -- If they've reached that point
        GoToNextPointAt: number,  -- After reaching the point, pick when to walk to a new point
        
        Dead: boolean,
    }
} = {}

local Nodes: {
    [string]: {Pos: Vector3, Connections: {string}}
} = {}

local NPCFolder: Folder

local RunThread: thread?

local Assets = ServerStorage.Assets
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Get all the NPC spawns in the world
local function GetSpawnPoints()
    table.clear(SpawnPoints)
    table.clear(SpawnNames)

    for _, Spawn: BasePart in CollectionService:GetTagged("NPCSpawn") do
        if not Spawn then continue end
        table.insert(SpawnPoints, Spawn.CFrame) -- Add the raw cframe

        -- Group spawn points with the same name
        local BaseName = string.sub(Spawn.Name, 10, string.len(Spawn.Name))
        if not SpawnNames[BaseName] then
            SpawnNames[BaseName] = {Spawn.CFrame}
        else
            table.insert(SpawnNames[BaseName], Spawn.CFrame)
        end

        Spawn:Destroy()
    end
end

-- Get all the path nodes in the world
local function GetPathNodes()
    table.clear(Nodes)

    local List: {BasePart} = {}

    -- Name all the nodes first
    for n, Node in Workspace.PathNodes:GetChildren() do
        Node.Name = "N_" .. n
        table.insert(List, Node)
    end

    -- Set up connections
    for _, Node in List do
        Nodes[Node.Name] = {
            Pos = Node.Position,
            Connections = {},
        }

        -- Get the other nodes this node is connected to
        for _, Connection in Node:GetChildren() do
            if not Connection:IsA("Beam") then continue end
            table.insert(Nodes[Node.Name].Connections, Connection.Attachment1.Parent.Name)
        end
    end

    -- Destroy all the nodes in workspace
    for _, Node in List do
        --Node:Destroy()
    end

    warn(Nodes)
end

-- Find the closest node to a position
local function FindClosestNode(FromHere: Vector3): (string?, number?)
    local ChosenNode = nil
    local LastDistance = 1000
    
    for Node, Data in Nodes do
        if not Node or not Data then continue end
        if not Data.Pos then continue end
        local Distance = (Data.Pos - FromHere).Magnitude
        if Distance > LastDistance then continue end

        ChosenNode = Node
        LastDistance = Distance
    end

    if not ChosenNode then return end

    return ChosenNode, LastDistance
end

local function PickNodeFromConnections(Node: string): string
    local Data = Nodes[Node]

    return Data.Connections[RNG:NextInteger(1, #Data.Connections)]
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Spawn in an NPC
-- @ThisPoint = Where to spawn; can be a CFrame or a spawn points name
-- @Rarity = Which rarity of NPC it should pick from
-- @Name = Optionally spawn in a very specific NPC
function NPCService.Spawn(ThisPoint: CFrame? | string, Rarity: NPCInfo.NPCRariry?, Name: string?)
    if not ThisPoint then
        ThisPoint = SpawnPoints[RNG:NextInteger(1, #SpawnPoints)]

    elseif ThisPoint and type(ThisPoint) == "string" then
        if SpawnNames[ThisPoint] then
            ThisPoint = SpawnNames[ThisPoint][RNG:NextInteger(1, #SpawnNames[ThisPoint])]
        else
            ThisPoint = SpawnPoints[RNG:NextInteger(1, #SpawnPoints)]
        end
    end

    local Rarity = Rarity or DEFAULT_NPC.Rarity
    local NPCName = Name or DEFAULT_NPC.Name

    local Info = NPCInfo[Rarity][NPCName]

    local NewNPC = Assets.Misc.BaseNPC:Clone()
    NewNPC.Name = NPCName
    
    local Description = Instance.new("HumanoidDescription")
    
    Description.HeadColor = Info.HeadColor or Info.SkinColor
    Description.TorsoColor = Info.TorsoColor or Info.SkinColor
    Description.LeftArmColor = Info.LeftArmColor or Info.SkinColor
    Description.RightArmColor = Info.RightArmColor or Info.SkinColor
    Description.LeftLegColor = Info.LeftLegColor or Info.SkinColor
    Description.RightLegColor = Info.RightLegColor or Info.SkinColor
    
    Description.Face = Info.FaceID

    Description.HatAccessory = Info.Hat or 0
    Description.HairAccessory = Info.Hair or 0
    Description.FaceAccessory = Info.Face or 0
    Description.NeckAccessory = Info.Neck or 0
    Description.ShouldersAccessory = Info.Shoulder or 0
    Description.FrontAccessory = Info.Front or 0
    Description.BackAccessory = Info.Back or 0
    Description.WaistAccessory = Info.Waist or 0
    
    Description.Shirt = Info.Shirt or 0
    Description.Pants = Info.Pants or 0

    Description.Parent = NewNPC
    NewNPC:AddTag("NPC")
    NewNPC.Parent = NPCFolder
    
    local Success, Error = pcall(function() 
        NewNPC.Humanoid:ApplyDescriptionAsync(Description)
    end)

    if not Success then
        warn(Error)
        return
    end

    NewNPC:PivotTo(ThisPoint)

    local GoalNode = ""
    local GoalPoint = Vector3.new(0, 0, 0)
    if Info.Movement == "Roam" then
        GoalNode, GoalPoint = FindClosestNode(NewNPC:GetPivot().Position)
    end

    NPCs[NewNPC] = {
        Name = NPCName or "John",
        Movement = Info.Movement,

        Human = NewNPC.Humanoid,

        GoalNode = GoalNode,
        GoalPoint = GoalPoint,
        ReachedPoint = true,
        GoToNextPointAt = 0,
        
        Dead = false,
    }

    RagdollService.SetRagdoll(NewNPC)
end

function NPCService.Stop()
    if not RunThread then return end
    task.cancel(RunThread)
end

function NPCService.Run()
    NPCService.Stop()

    RunThread = task.spawn(function()
        while true do
            task.wait(1)

            for Model, Data in NPCs do
                if not Model or not Data then continue end
                
                if Data.Movement == "Stationary" then continue end

                if Data.ReachedPoint then
                    if os.clock() < Data.GoToNextPointAt then continue end
                    
                    local NextNode = PickNodeFromConnections(Data.GoalNode)
                    Data.GoalNode = NextNode
                    Data.GoalPoint = Nodes[NextNode].Pos
                    Data.ReachedPoint = false
                    Data.Human:MoveTo(Data.GoalPoint)
                else
                    Data.Human:MoveTo(Data.GoalPoint)

                    local Distance = (Model:GetPivot().Position - Data.GoalPoint).Magnitude
                    if Distance > 5 then continue end

                    Data.ReachedPoint = true
                    Data.GoToNextPointAt = os.clock() + RNG:NextInteger(1, 3)
                end
            end
        end
    end)
end

function NPCService:Init()
    NPCFolder = New.Instance("Folder", "NPCs", Workspace)
end

function NPCService:Deferred()
    GetSpawnPoints()
    GetPathNodes()

    NPCService.Spawn("A")
    NPCService.Spawn("B")

    NPCService.Run()
end

return NPCService