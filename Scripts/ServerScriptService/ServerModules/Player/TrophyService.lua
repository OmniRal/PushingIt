-- OmniRal

local TrophyService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BadgeService = game:GetService("BadgeService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local TrophyInfo = require(ReplicatedStorage.Source.SharedModules.Info.TrophyInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AWARD_BADGES = false -- Set to FALSE only when testing

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- For when the player requests to claim a trophy, it will check through this
local TrophyChecks: {[string]: (Player, ...any) -> (boolean)} = {
	["Timer"] = function(Player: Player, FullName: string) -- 90s, 300s, 600s
		local SavedTime = Player:GetAttribute("SavedTime")
		local TimerStartedAt = Player:GetAttribute("TimerStartedAt")
		if not SavedTime or not TimerStartedAt then return false end
		local CurrentTime = Workspace:GetServerTimeNow() - TimerStartedAt + SavedTime

		local ThisInfo = TrophyInfo[FullName]
		if not ThisInfo then return false end

		if CurrentTime <= 9 then return false end

		return true
	end,
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Runs when a player requests to make trophy progress
local function HandlePlayerTrophyRequest(Player: Player, TrophyName: string, ...): boolean
	if not TrophyChecks[TrophyName] then
		-- Check for a function name without the "_"
		local ShortName = (string.gsub(TrophyName, "_%d+$", ""))
		warn(ShortName)
		if not TrophyChecks[ShortName] then return false end
		return TrophyChecks[ShortName](Player, TrophyName)
	else
		return TrophyChecks[TrophyName](Player, ...)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Incrememnt progress on a trophy
function TrophyService.UpdateTrophyProgress(Player: Player, TrophyName: string, By: number, Score: number?): boolean
	local PData = DataService.GetProfileTable(Player, "Trophies")
	if not PData then warn(Player, " has corrupted data while trying to make progress on trophy [" .. TrophyName .. "] info!"); return false end

	local SavedData = PData[TrophyName]
	local ThisInfo = TrophyInfo[TrophyName]
	if not SavedData or not ThisInfo then return false end
	if SavedData.Complete then return false end -- Trophy is already completed
	if ThisInfo.ScoreNeeded and Score and Score < ThisInfo.ScoreNeeded then return false end -- Score isn't high enough to make progress

	local Complete = DataService.UpdateTrophyProgress(Player, TrophyName, By)
    Remotes.Server.DataService.SingleDataUpdate:Fire(Player, {"Trophies", TrophyName}, PData[TrophyName])

	if Complete and ThisInfo.BadgeID and AWARD_BADGES then
		local Success, Error = pcall(function() return BadgeService:AwardBadgeAsync(Player.UserId, ThisInfo.BadgeID) end)
		if not Success then
			-- Don't award trophy if the badge wasn't awarded
			warn("Failed to award badge", TrophyName, " (" .. ThisInfo.BadgeID .. ") - ", Error)
			return false
		end
	end
	
	return true
end

-- Incrememnt progress on multiple trophies
function TrophyService.UpdateMultipleTrophiesProgress(Player: Player, TrophyNames: {string}, By: {number}, Score: number?)
	local PData = DataService.GetProfileTable(Player, "Trophies")
	if not PData then warn(Player, " has corrupted data while trying to make progress on trophies!"); return end

	for n, TrophyName in ipairs(TrophyNames) do
		local SavedData = PData[TrophyName]
		local ThisInfo = TrophyInfo[TrophyName]
		if not SavedData or not ThisInfo then continue end
		if SavedData.Complete or not By[n] then continue end -- Trophy is already complete
		if ThisInfo.ScoreNeeded and Score and Score < ThisInfo.ScoreNeeded then continue end -- Score isn't high enough to make progress

		local Complete = DataService.UpdateTrophyProgress(Player, TrophyName, By[n])
		Remotes.Server.DataService.SingleDataUpdate:Fire(Player, {"Trophies", TrophyName}, PData[TrophyName])

		if Complete and TrophyInfo[TrophyName].BadgeID and AWARD_BADGES then
			local Success, Error = pcall(function() return BadgeService:AwardBadgeAsync(Player.UserId, TrophyInfo[TrophyName].BadgeID) end)
			if not Success then
				-- Don't award trophy if the badge wasn't awarded
				warn("Failed to award badge", TrophyName, " (" .. TrophyInfo[TrophyName].BadgeID .. ") - ", Error)
				return -- Stop all updating
			end
		end
	end
end

-- Try to claim a reward from a trophy
function TrophyService.ClaimTrophyReward(Player: Player, TrophyName: string): boolean
	local PData = DataService.GetProfileTable(Player, "Trophies")
	if not PData then warn(Player, " has corrupted data while trying to collect trophy [" .. TrophyName .. "] info!"); return false end

	local SavedData = PData[TrophyName]
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

	Remotes.Server.DataService.SingleDataUpdate:Fire(Player, {"Trophies", TrophyName}, PData[TrophyName])
	
	return true
end

function TrophyService.CheckPlayerHasBadge(Player: Player, TrophyName: string): boolean
	if not Player or not TrophyName then return false end
	local Info = TrophyInfo[TrophyName]
	if not Info then return false end
	
	local Success, Error = pcall(function()
		return BadgeService:UserHasTrophyAsync(Player.UserId, Info.BadgeID)
	end)
	
	if not Success then
		warn("Error while checking if player has badge", TrophyName, " (" .. Info.BadgeID .. ") - ", Error)
		return false
	end

	return true
end

function TrophyService.CheckPlayerHasMultipleTrophies(Player: Player, TrophyNames: {string})
	if not Player or not TrophyNames then return end
end

function TrophyService:Init()
	Remotes.Server:CreateToServer("RequestUpdateTrophyProgress", {"string", "number?", "number?"}, "Returns", function(Player: Player, TrophyName: string, By: number, Score: number?)
		if not HandlePlayerTrophyRequest(Player, TrophyName) then return false end
		return TrophyService.UpdateTrophyProgress(Player, TrophyName, By, Score)
	end)
	
	Remotes.Server:CreateToServer("RequestClaimTrophyReward", {"string"}, "Returns", function(Player: Player, TrophyName: string)
		return TrophyService.ClaimTrophyReward(Player, TrophyName)
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