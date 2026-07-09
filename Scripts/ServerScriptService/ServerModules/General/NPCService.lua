-- OmniRal

local NPCService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)
local NPCInfo = require(ReplicatedStorage.Source.SharedModules.Info.NPCInfo)
local RagdollService = require(ServerScriptService.Source.ServerModules.General.RagdollService)
local ServerGlobalValues = require(ServerScriptService.Source.ServerModules.Top.ServerGlobalValues)
local Roll = require(ReplicatedStorage.Source.SharedModules.General.Utility.Roll)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local USE_DEFAULT = false -- Set this to true when you want all NPCs to spawn as the one below
local DEFAULT_NPC = {Rarity = "Common", Name = "John"} -- Change this to test a specific NPC

local KEEP_NODES = true -- If TRUE, the NPC nodes will remain in game instead of being destroyed

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SpawnPoints: {CFrame} = {}
local SpawnNames: {[string]: {CFrame}} = {}

local RarityChances: {{Choice: string, Chance: number}} = {
    {Choice = "Common", Chance = 10},
    {Choice = "Rare", Chance = 5},
    {Choice = "Epic", Chance = 2},
    {Choice = "Legendary", Chance = 1},
    {Choice = "Mythical", Chance = 0.1},
}

local NPCList: {
    [string]: {string}
} = {}

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
	if KEEP_NODES then return end

    for _, Node in List do
        Node:Destroy()
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
		-- Pick a random spawn from the cached list
        ThisPoint = SpawnPoints[RNG:NextInteger(1, #SpawnPoints)]

    elseif ThisPoint and type(ThisPoint) == "string" then
		-- Attempt to look for the spawn point by name
        if SpawnNames[ThisPoint] then
            ThisPoint = SpawnNames[ThisPoint][RNG:NextInteger(1, #SpawnNames[ThisPoint])]
        else
			-- Fall back to picking a random one
            ThisPoint = SpawnPoints[RNG:NextInteger(1, #SpawnPoints)]
        end
    end

    local NPCRarity: string
    local NPCName: string

    if not USE_DEFAULT then
        if Rarity and Name then
            -- Pick specific NPC chosen ONLY IF rarity and name fields BOTH exist
            NPCRarity = Rarity
            NPCName = Name

		elseif Rarity and not Name then
			NPCRarity = Rarity
			NPCName = NPCList[NPCRarity][RNG:NextInteger(1, #NPCList[NPCRarity])]

        elseif not Rarity and not Name then
            -- Pick random rarity ane name
            NPCRarity = Roll.Pick(RarityChances) :: string
            NPCName = NPCList[NPCRarity][RNG:NextInteger(1, #NPCList[NPCRarity])]
        end
    else
        -- Go with default NPC
        NPCRarity = DEFAULT_NPC.Rarity
        NPCName = DEFAULT_NPC.Name
    end

    if not NPCRarity or not NPCName then return end

    local Info = NPCInfo[NPCRarity][NPCName]

    local NewNPC = if not ServerGlobalValues.NPC_Use_R6 then Assets.Misc.BaseNPC:Clone() else Assets.Misc.BaseNPC_R6:Clone()
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

	if not ServerGlobalValues.NPC_Use_R6 then
    	RagdollService.SetRagdoll(NewNPC)
	else
		RagdollService.SetRagdoll_R6(NewNPC)
	end
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

				-- Handle their movement
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
    -- Fill NPC list
    for Rarity, List in NPCInfo do
        if not NPCList[Rarity] then
            NPCList[Rarity] = {}
        end

        for Name, _ in List do
            table.insert(NPCList[Rarity], Name)
        end
    end

    GetSpawnPoints()
    GetPathNodes()

    NPCService.Spawn("A", "Common")
    NPCService.Spawn("B", "Common")

    NPCService.Run()
end

return NPCService