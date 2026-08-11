-- OmniRal

local StickerController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local StickerInfo = require(ReplicatedStorage.Source.SharedModules.Info.StickerInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local RunHeartbeat: RBXScriptConnection? = nil

local Assets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Replace the simple basic verion of hazards with better looking models
local function SetAllStickers()
	if not PlayerInfo.Data then return end

	for _, Sticker in CollectionService:GetTagged("Sticker") do
		if not Sticker then continue end

		Sticker.Transparency = 1
		for _, Stuff in Assets.Other.StickerPickup:GetChildren() do
			Stuff:Clone().Parent = Sticker
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function StickerController.Stop()
	if not RunHeartbeat then return end
	RunHeartbeat:Disconnect()
	RunHeartbeat = nil
end

function StickerController.Run()
	StickerController.Stop()
	
	RunHeartbeat = RunService.Heartbeat:Connect(function()
		if not LocalPlayer.Character then return end
		local Root: BasePart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not Root then return end
	end)
end

function StickerController:Deferred()
	task.delay(3, function()
		SetAllStickers()
		StickerController.Run()
	end)
end

return StickerController