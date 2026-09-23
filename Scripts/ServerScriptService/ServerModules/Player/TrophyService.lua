-- OmniRal

local TrophyService = {}

-- Comment from test-branch-2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BadgeService = game:GetService("BadgeService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local TrophyInfo = require(ReplicatedStorage.Source.SharedModules.Info.TrophyInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Incrememnt progress on a trophy
local function UpdateTrophyProgress(Player: Player, TrophyName: string, By: number): boolean
	local PData = DataService.GetProfileTable(Player)
	if not PData then warn(Player, " has corrupted data while trying to make progress on trophy [" .. TrophyName .. "] info!"); return false end
	if not PData.Trophys then warn(Player, " has corrupted data while trying to make progress on trophy [" .. TrophyName .. "] info!"); return false end

	local SavedData = PData.Trophys[TrophyName]
	if SavedData.Complete then return false end -- Trophy is already completed

	DataService.UpdateTrophyProgress(Player, TrophyName, By)
    Remotes.Server.TrophyService.TrophyUpdate:Fire(Player, TrophyName, PData.Trophies[TrophyName])
	
	return true
end

-- Try to claim a reward from a trophy
local function ClaimTrophyReward(Player: Player, TrophyName: string): boolean
	local PData = DataService.GetProfileTable(Player)
	if not PData then warn(Player, " has corrupted data while trying to collect trophy [" .. TrophyName .. "] info!"); return false end
	if not PData.Trophys then warn(Player, " has corrupted data while trying to collect trophy [" .. TrophyName .. "] info!"); return false end

	local SavedData = PData.Trophys[TrophyName]
	local ThisInfo = TrophyInfo

	if not SavedData or not ThisInfo then warn(Player, " has corrupted data or missing trophy [" .. TrophyName .. "] info!"); return false end
	if not SavedData.Complete or ThisInfo.RewardType == "None" then return false end
	if SavedData.RewardClaimed then return false end
	
	DataService.ClaimTrophyReward(Player, TrophyName)

	-- Handle giving reward here
    if ThisInfo.RewardType == "Coins" then
        task.delay(0.5, function()
            --DataService:IncrementCoins(Player, Info.Reward)
        end)
    end

	Remotes.Server.DataService.TrophyUpdate:Fire(Player, TrophyName, PData.Trophies[TrophyName])
	
	return true
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function TrophyService:CheckPlayerHasTrophy(Player: Player, TrophyName: string): boolean?
	if not Player or not TrophyName then return end
	local Info = TrophyInfo[TrophyName]
	if not Info then return end
	
	local Success, Result = pcall(function()
		return BadgeService:UserHasTrophyAsync(Player.UserId, Info.TrophyID)
	end)
	
	if not Success then return end
	if not Result then return end
	return true
end

function TrophyService:CheckPlayerHasMultipleTrophies(Player: Player, TrophyNames: {string})
	if not Player or not TrophyNames then return end
end

function TrophyService:Init()
	Remotes.Server:CreateToClient("TrophyUpdate", {"string", "table"}, "Reliable")

	Remotes.Server:CreateToServer("RequestUpdateTrophyProgress", {"string", "number?"}, "Returns", function(Player: Player, TrophyName: string, By: number)
		return UpdateTrophyProgress(Player, TrophyName, By)
	end)
	
	Remotes.Server:CreateToServer("RequestClaimTrophyReward", {"string"}, "Returns", function(Player: Player, TrophyName: string)
		return ClaimTrophyReward(Player, TrophyName)
	end)
end

function TrophyService:Deferred()
	--[[workspace.TrophyTester.Touched:Connect(function(Hit: any)
	if workspace.TrophyTester:GetAttribute("Debounce") then return end
	if not Hit then return end
	if not Hit.Parent then return end
	if not Hit.Parent:FindFirstChild("Humanoid") then return end
	local Player = Players:FindFirstChild(Hit.Parent.Name)
	if not Player then return end
	
	workspace.TrophyTester:SetAttribute("Debounce", true)
	
	DataService:UpdateTrophyProgress(Player, "TestTrophy", 1)
	
	task.wait(2)
	
	workspace.TrophyTester:SetAttribute("Debounce", false)
end)]]
end

return TrophyService