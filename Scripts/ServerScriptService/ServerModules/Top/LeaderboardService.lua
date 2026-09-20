-- OmniRal

local LeaderboardService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LEADERSTATS_VERSION = "Alpha_1"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Stores = {
	["Pushes"] = DataStoreService:GetOrderedDataStore("PushingIt_Pushes_" .. LEADERSTATS_VERSION),
	["NPCPushes"] = DataStoreService:GetOrderedDataStore("PushingIt_NPCPushes_" .. LEADERSTATS_VERSION),
	["PlayerPushes"] = DataStoreService:GetOrderedDataStore("PushingIt_PlayerPushes_" .. LEADERSTATS_VERSION),
	["TimeNotPushed"] = DataStoreService:GetOrderedDataStore("PushingIt_TimeNotPushed_" .. LEADERSTATS_VERSION),
	["HighestScore"] = DataStoreService:GetOrderedDataStore("PushingIt_HighestScore_" .. LEADERSTATS_VERSION),
	["RobuxSpent"] = DataStoreService:GetOrderedDataStore("PushingIt_RobuxSpent_" .. LEADERSTATS_VERSION)
}

local PlayerStatsInfo: {
	[Player]: {
		LastWriteTime: number,
		CachedStats: {[string]: number},
		Writing: boolean,
	}
} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LeaderboardService.UpdateStat(Player: Player, Key: string, Value: number)
	if not Player then return end
	local ThisStore = Stores[Key]
	if not ThisStore then warn(Key, " is not a valid Leaderboard Stat!"); return end

	local Success, Error = pcall(function()
		ThisStore:SetAsync(tostring(Player.UserId), Value)
	end)

	if Success then return end
	warn("LeaderboardService failed to write", Key, "for", Player.Name, "---", Error)
end

function LeaderboardService.GetTop(Key: string, Count: number): {{UserID: number, Value: number}}?
	local ThisStore = Stores[Key]
	if not ThisStore then warn(Key, " is not a valid Leaderboard Stat!"); end

	local Entries = {}

	local Success, Results = pcall(function()
		return ThisStore:GetSortedAsync(false, Count)
	end)

	if not Success then
		warn("LeaderboardSerivce failed to fetch data ---", Results)
		return
	end

	local Page = Results:GetCurrentPage()
	for _, Entry in ipairs(Page) do
		table.insert(Entries, {UserID = tonumber(Entry.key), Value = Entry.value})
	end

	return Entries
end

return LeaderboardService