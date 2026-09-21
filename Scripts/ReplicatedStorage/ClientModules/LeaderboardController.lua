-- OmniRal

local LeaderboardController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DEFAULT_HEADSHOT = ""

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LeaderboardService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local HeadshotCache: {[string]: string} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetHeadshot(UserID: number): (boolean, string)
	-- Check cache first
	if HeadshotCache[tostring(UserID)] then return true, HeadshotCache[tostring(UserID)] end
	local Success, Content = pcall(function()
		return Players:GetUserThumbnailAsync(UserID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	
	if Success then
		HeadshotCache[tostring(UserID)] = Content
	end

	return Success, Content or DEFAULT_HEADSHOT
end

local function UpdateBoard(ThisBoard: Model)
	if not ThisBoard then return end
	local Display = ThisBoard:FindFirstChild("Display")
	if not Display then return end
	
	for _, Entry in Display.Gui.ScrollFrame:GetChildren() do
		if Entry.Name == "OG_Entry" or Entry.Name == "ListLayout" then continue end
		local UserID = Entry:GetAttribute("UserID")
		if UserID == nil then continue end
		local _, Content = GetHeadshot(UserID)
		Entry.Box.Headshot.Image = Content

		if UserID ~= LocalPlayer.UserId then return end
		Entry.Box.Headshot.PlayerName.Text = "YOU!"
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LeaderboardController:Deferred()
	Utility.CheckRemotesLoaded({"LeaderboardService"})
	LeaderboardService = Remotes.Client.LeaderboardService

	LeaderboardService.UpdateBoard:Connect(UpdateBoard)
	
	-- Update all boards at the start
	for _, Board in CollectionService:GetTagged("Leaderboard") do
		if not Board then continue end
		if Board:GetAttribute("Stat") == nil then continue end
		UpdateBoard(Board)
	end
end

return LeaderboardController