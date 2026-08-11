-- OmniRal

local StickerService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local AssetService = game:GetService("AssetService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local StickerInfo = require(ReplicatedStorage.Source.SharedModules.Info.StickerInfo)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SHOW_DOTS = false

local GRID_Size = 32
local LIFE_TIME = 1000
local SURFACE_OFFSET = 0.02

local COOLDOWN = 0.5

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AllStickers: {} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Expanding-Radius search for a nearby valid hit, used to patch over grid
-- points whose ray missed everything (e.g. a gap between bricks).
local function FindNearestHit(HitPositions: { [number]: Vector3? }, Row: number, Col: number, GridSize: number): Vector3?
	for Radius = 1, GridSize do
		for DRow = -Radius, Radius do
			for DCol = -Radius, Radius do
				local R, C = Row + DRow, Col + DCol
				if R < 0 or R >= GridSize or C < 0 or C > GridSize then continue end
				
				local Index = R * GridSize + C + 1
				local Value = HitPositions[Index]
				if not Value then continue end

				return Value :: Vector3
			end
		end
	end

	return nil
end

local function SetSticker(Sticker: BasePart, StickerName: string)
	local Debounce = false
	
	Sticker.Touched:Connect(function(Hit: BasePart)
		if Debounce then return end
		if not Hit then return end
		if not Hit.Parent then return end
		
		local ThisPlayer = Players:FindFirstChild(Hit.Parent.Name)
		if not ThisPlayer then return end
		
		local Alive = Utility.Players.CheckAlive(ThisPlayer)
		if not Alive then return end

		Debounce = true
		
		local Success, Amount = DataService.CollectSticker(ThisPlayer, StickerName)
		if Success then
			Remotes.Server.StickerService.StickerGrabbed:Fire(ThisPlayer, Sticker, Amount)
		end

		task.wait(COOLDOWN)

		Debounce = false
	end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function StickerService.PlaceSticker(ProjectorPart: BasePart, StickerID: number, Ignore: {}?, Lifetime: number?): MeshPart?
	local GridSize = GRID_Size
	
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = Ignore or {}
	Params.IgnoreWater = true
	
	local CF = ProjectorPart.CFrame
	local Size = ProjectorPart.Size
	
	local Up = CF.UpVector
	local Right = CF.RightVector
	local Forward = -CF.LookVector
	local TH_RowDistance = Size.Z
	local Origin = CF.Position
	
	-- 1. Fire the sample grid through the projector's footprint.
	local HitPositions: { [number]: Vector3? } = {}
	local AnyHit = false
	
	for Row = 0, GridSize - 1 do
		for Col = 0, GridSize - 1 do
			local U = (Col / (GridSize - 1)) - 0.5
			local V = (Row / (GridSize - 1)) - 0.5
			
			local RayOrigin = Origin + (Right * U * Size.X) + (Up * V * Size.Y)
			local Result = Workspace:Raycast(RayOrigin, Forward * TH_RowDistance, Params)
			
			local Index = Row * GridSize + Col + 1
			if not Result then HitPositions[Index] = nil; continue end

			if SHOW_DOTS then Utility.CreateDot(CFrame.new(Result.Position), Vector3.new(0.5, 0.5, 0.5), Enum.PartType.Ball, Color3.fromRGB(250, 50, 50)) end
			
			HitPositions[Index] = Result.Position + (Result.Normal * SURFACE_OFFSET)
			AnyHit = true
		end
	end
	
	if not AnyHit then return nil end

	-- 2. Patch any misses (gaps between bricks, etc.) using the nearest valid hit.
	for Row = 0, GridSize - 1 do
		for Col = 0, GridSize - 1 do
			local Index = Row * GridSize + Col + 1
			if HitPositions[Index] then continue end
			
			HitPositions[Index] = FindNearestHit(HitPositions, Row, Col, GridSize)
		end
	end

	-- 3. Build the EditableMesh from the (now fully patched) grid.
	local EditableMesh = AssetService:CreateEditableMesh()
	local VertexIDs = {}

	for n = 1, GridSize * GridSize do
		local Pos = HitPositions[n] :: Vector3
		VertexIDs[n] = EditableMesh:AddVertex(Pos)

		local Col = (n - 1) % GridSize
		local Row = math.floor((n - 1) / GridSize)
		EditableMesh:AddUV(Vector2.new(Col / (GridSize - 1), 1 - (Row / (GridSize - 1))))
	end

	for Row = 0, GridSize - 2 do
		for Col = 0, GridSize - 2 do
			local i00 = Row * GridSize + Col + 1
			local i10 = Row * GridSize + Col + 2
			local i01 = (Row + 1) * GridSize + Col + 1
			local i11 = (Row + 1) * GridSize + Col + 2

			EditableMesh:AddTriangle(VertexIDs[i00], VertexIDs[i01], VertexIDs[i10])
			EditableMesh:AddTriangle(VertexIDs[i10], VertexIDs[i01], VertexIDs[i11])
		end
	end

	-- 4. Wrap it in a MeshPart and texture it.
	local MeshPart = AssetService:CreateMeshPartAsync(Content.fromObject(EditableMesh))
	MeshPart.Name = "Sticker"
	MeshPart.Anchored = true
	MeshPart.CanCollide = false
	MeshPart.CanQuery = false -- so future Stickers' raycasts pass straight through existing stickers
	MeshPart.CastShadow = false
	MeshPart.Transparency = 1
	MeshPart.Parent = Workspace

	--[[local Decal = Instance.new("Decal")
	Decal.Texture = "rbxassetid://" .. StickerID
	Decal.ColorMap = "rbxassetid://" .. StickerID
	Decal.Face = Enum.NormalId.Top
	Decal.Parent = MeshPart]]

	local SurfaceAppearance = Instance.new("SurfaceAppearance")
	--SurfaceAppearance.ColorMap = Workspace.Tester.SurfaceAppearance.ColorMap
	SurfaceAppearance.AlphaMode = Enum.AlphaMode.Transparency
	SurfaceAppearance.Parent = MeshPart

	Debris:AddItem(MeshPart, Lifetime or LIFE_TIME)

	ProjectorPart:Destroy()

	return MeshPart
end

function StickerService.GetAllStickers()
	local Folder = Instance.new("Folder")
	Folder.Name = "Stickers"
	Folder.Parent = Workspace

	for _, Sticker in CollectionService:GetTagged("Sticker") do
		if not Sticker then continue end
		if not StickerInfo[Sticker:GetAttribute("StickerName")] then continue end
		SetSticker(Sticker, Sticker:GetAttribute("StickerName"))
	end
end

function StickerService:Init()
	Remotes.Server:CreateToClient("StickerGrabbed", {"BasePart", "number"}, "Reliable")
end

function StickerService:Deferred()
	--StickerService.New(Workspace.ProjectorPart, 118698866213297)
	task.delay(2, function()
		StickerService.GetAllStickers()
	end)
end

return StickerService