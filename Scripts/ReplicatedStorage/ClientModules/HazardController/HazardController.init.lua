-- OmniRal

local HazardController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

HazardController.SpeedReduction = 0

local LocalPlayer = Players.LocalPlayer
local RunHeartbeat: RBXScriptConnection? = nil

local AllHazards: {} = {}
local Slows: {[Model | BasePart]: number} = {}

local Assets = ReplicatedStorage.Assets

local Modules = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetAllHazards()
	for _, Hazard in CollectionService:GetTagged("Hazard") do
		if not Hazard then continue end
		table.insert(AllHazards, Hazard)
	end
end

-- Replace the simple basic verion of hazards with better looking models
local function ReplaceHazardModels()
	for _, Replace in CollectionService:GetTagged("Replace") do
		if not Replace then continue end
		if not Assets.Hazards:FindFirstChild(Replace.Name) then continue end
		
		local PlaceHere: CFrame
		if Replace:IsA("BasePart") then
			PlaceHere = Replace.CFrame
			Replace.Transparency = 1
			
		else
			PlaceHere = Replace:GetPivot()
			for _, Part in Replace:GetDescendants() do
				if not Part:IsA("BasePart") then continue end
				Part.Transparency = 1
			end
		end
		
		local NicerModel = Assets.Hazards[Replace.Name]:Clone()
		NicerModel:PivotTo(PlaceHere)
		NicerModel.Parent = Workspace.ClientVisuals

		if not Modules[Replace.Name] then continue end
		if not Modules[Replace.Name].Setup then continue end

		Modules[Replace.Name].Setup(Replace, PlaceHere, NicerModel)
	end
end

local function CalculateSpeedReduction()
	local UpdatedReduction = 0
	for Hazard, Amount in Slows do
		if not Hazard then continue end
		UpdatedReduction += Amount
	end
	
	HazardController.SpeedReduction = UpdatedReduction
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function HazardController.Stop()
	if not RunHeartbeat then return end
	RunHeartbeat:Disconnect()
	RunHeartbeat = nil
end

function HazardController.Run()
	HazardController.Stop()
	
	RunHeartbeat = RunService.Heartbeat:Connect(function()
		if not LocalPlayer.Character then return end
		local Root: BasePart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not Root then return end
		
		for _, Hazard in AllHazards do
			if not Hazard then continue end
			
			if Hazard.Name == "GrassBush" then
				if (Hazard.Position - Root.Position).Magnitude <= 4 then
					if not Slows[Hazard] then Slows[Hazard] = 4 end
				else
					if Slows[Hazard] then Slows[Hazard] = nil end
				end
			end
		end
		
		CalculateSpeedReduction()
	end)
end

function HazardController:Deferred()
	task.delay(3, function()
		-- Get modules within this module for each hazard
		for _, Script in script:GetChildren() do
			Modules[Script.Name] = require(Script)
		end

		GetAllHazards()
		ReplaceHazardModels()
		HazardController.Run()
	end)
end

return HazardController