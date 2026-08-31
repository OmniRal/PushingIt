-- OmniRal

local RainBananas = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local NPCService = require(ServerScriptService.Source.ServerModules.General.NPCService)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Y_OFFSET = 50 -- How far up should the banana peel spawn from their drop location
local DROP_SPEED = 10
local PEEL_OFFSET_Y = 0.75 / 2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function RainBananas.Run(Duration: number)
	local DropPositions = NPCService.GetNodePositions()

	for _ = 1, Duration do
		task.wait(1)

		if #DropPositions <= 0 then break end -- Incase it runs out of locations to drop bananas

		local RandIndex = RNG:NextInteger(1, #DropPositions)
		local StartCFrame = CFrame.new(DropPositions[RandIndex] + Vector3.new(0, Y_OFFSET, 0)) * CFrame.Angles(0, RNG:NextNumber(0, math.pi), 0)
		local FinishCFrame = CFrame.new(DropPositions[RandIndex] + Vector3.new(0, PEEL_OFFSET_Y, 0)) * CFrame.Angles(0, RNG:NextNumber(0, math.pi), 0)
		table.remove(DropPositions, RandIndex) -- Avoid spawning peels to the same location

		local NewPeel = ReplicatedStorage.Assets.Hazards.BananaPeel:Clone()
		NewPeel.CFrame = StartCFrame
		NewPeel.Parent = Workspace.Hazards
		NewPeel:SetAttribute("Locked", true)

		TweenService:Create(NewPeel, TweenInfo.new(Y_OFFSET / DROP_SPEED, Enum.EasingStyle.Linear), {CFrame = FinishCFrame}):Play()

		task.delay(Y_OFFSET / DROP_SPEED, function()
			-- Banana is ready to be slipped on
			NewPeel:SetAttribute("Locked", false)
		end)
	end
end

return RainBananas