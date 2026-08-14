-- OmniRal

local HazardController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
--local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

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

local SpecificSetups: {[string]: (Original: BasePart | Model, PlaceHere: CFrame, NicerModel: Model) -> ()} = {
	["SpringLauncher"] = function(Original: any, _: CFrame, NicerModel: any)
        Original.Transparency = 1
        local BaseCushionCFrame = NicerModel.Cushion.CFrame

        Original:GetAttributeChangedSignal("Launched"):Connect(function()
            if not Original:GetAttribute("Launched") then return end

            local UpTween = TweenService:Create(NicerModel.Cushion, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {CFrame = BaseCushionCFrame * CFrame.new(0, 2, 0)})
            local DownTween = TweenService:Create(NicerModel.Cushion, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = BaseCushionCFrame})
            UpTween.Completed:Connect(function()
                task.wait(0.5)
                DownTween:Play()
            end)
            UpTween:Play()
        end)
	end,
}

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
		NicerModel.Parent = Replace.Parent
		
		if not SpecificSetups[Replace.Name] then continue end
		
		SpecificSetups[Replace.Name](Replace, PlaceHere, NicerModel)
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
		GetAllHazards()
		ReplaceHazardModels()
		HazardController.Run()
	end)
end

return HazardController