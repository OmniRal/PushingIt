-- OmniRal

local LeaderboardService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

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

function LeaderboardService.UpdateBoard(Key: string, Count: number, ThisBoard: Model)
	local ThisStore = Stores[Key]
	if not ThisStore then warn(Key, " is not a valid Leaderboard Stat!"); end
	local Display = ThisBoard:FindFirstChild("Display")
	if not Display then warn(ThisBoard, " is missing Display!"); return end

	local Entries = {}

	local Success, Results = pcall(function()
		return ThisStore:GetSortedAsync(false, Count)
	end)

	if not Success then
		warn("LeaderboardService failed to fetch data ---", Results)
		return
	end

	local Page = Results:GetCurrentPage()
	for _, Entry in ipairs(Page) do
		table.insert(Entries, {UserID = tonumber(Entry.key), Value = Entry.value})
	end

	Display.Gui.ScrollFrame.OG_Entry.Visible = false
	-- Clean up old ones
	for _, OldEntry in Display.Gui.ScrollFrame:GetChildren() do
		if OldEntry.Name == "OG_Entry" or OldEntry.Name == "ListLayout" then continue end
		OldEntry:Destroy()
	end

	-- Make new entries
	for x, Data in ipairs(Entries) do
		local NewEntry = Display.Gui.ScrollFrame.OG_Entry:Clone()
		NewEntry.Name = x
		NewEntry.Box.Rank.Num.Text = x
		NewEntry.Box.Value.Text = Data.Value
		NewEntry.Box.Headshot.PlayerName.Text = Players:GetPlayerByUserId(Data.UserID).Name
		NewEntry.Visible = true
		NewEntry:SetAttribute("UserID", Data.UserID)
		NewEntry.Parent = Display.Gui.ScrollFrame
	end

	Display.Gui.ScrollFrame.CanvasSize = UDim2.fromOffset(0, Display.Gui.ScrollFrame.OG_Entry.AbsoluteSize.Y * 100)

	Remotes.Server.LeaderboardService.UpdateBoard:FireAll(ThisBoard)
end

function LeaderboardService:Init()
	Remotes.Server:CreateToClient("UpdateBoard", {"Model"}, "Reliable")
end

return LeaderboardService