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

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local StickerInfo = require(ReplicatedStorage.Source.SharedModules.Info.StickerInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SPEED = 5
local MIN = 0
local MAX = 0.2


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local StickerService = Remotes.Client.StickerService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local RunHeartbeat: RBXScriptConnection? = nil

local AllStickers: {any} = {}
local Assets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Replace the simple basic verion of hazards with better looking models
local function SetAllStickers()
	if not PlayerInfo then return end
	if not PlayerInfo.Data then return end
	if not PlayerInfo.Data.Stickers then return end
	
	for _, Sticker in CollectionService:GetTagged("Sticker") do
		if not Sticker then continue end
		local StickerName = Sticker:GetAttribute("StickerName")
		
		Sticker.Transparency = 1
		for _, Stuff in Assets.Other.StickerPickup:GetChildren() do
			Stuff:Clone().Parent = Sticker
		end
		
		-- Check if the sticker has already been collected
		Sticker:SetAttribute("AmountCollected", 0)
		if PlayerInfo.Data.Stickers[StickerName] then
			Sticker:SetAttribute("AmountCollected", 1)
			Sticker.UI.Icon.Image = "rbxassetid://" .. StickerInfo[StickerName].ID
			Sticker.UI.Icon.ImageTransparency = 0.5
			Sticker.UI.Icon.ImageColor3 = Color3.fromRGB(100, 100, 100)
			Sticker.Sparkles.Enabled = false
		end
		
		-- Collection animation
		Sticker:GetAttributeChangedSignal("AmountCollected"):Connect(function() 
			local AmountCollected = Sticker:GetAttribute("AmountCollected")
			
			-- First time collecting it should be more special
			if AmountCollected == 1 then
				Sticker.FXPoint.Pulse:Emit(1)
				Sticker.FXPoint.Pulse_2:Emit(1)
				
				Sticker.UI.Icon.Image = "rbxassetid://" .. StickerInfo[StickerName].ID
				Sticker.UI.Icon.ImageTransparency = 0.5
				Sticker.UI.Icon.ImageColor3 = Color3.fromRGB(100, 100, 100)
				Sticker.Sparkles.Enabled = false
				
			else
				-- TODO: add sound effect
				print("Add sound effect for collecting already owned sticker")
			end
			
			Sticker.UI.Icon.Size = UDim2.fromScale(0.5, 0.5)
			TweenService:Create(Sticker.UI.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1), ImageTransparency = 1}):Play()			
		end)
		
		Sticker:GetAttributeChangedSignal("Debounce"):Connect(function()
			if Sticker:GetAttribute("Debounce") then return end
			TweenService:Create(Sticker.UI.Icon, TweenInfo.new(0.4), {ImageTransparency = 0.5}):Play()
		end)
		
		table.insert(AllStickers, Sticker)
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
		local Alpha = MIN + (MAX - MIN) * (math.sin(os.clock() * SPEED) * 0.5 + 0.5)
		for _, Sticker in AllStickers do
			if not Sticker then continue end
			
			if Sticker:GetAttribute("AmountCollected") > 0 then continue end
			Sticker.UI.Icon.Size = UDim2.fromScale(1, 1):Lerp(UDim2.fromScale(0, 0), Alpha)
		end
	end)
end

function StickerController:Deferred()
	task.delay(3, function()
		SetAllStickers()
		StickerController.Run()
	end)
	
	StickerService.StickerGrabbed:Connect(function(Sticker: BasePart, 	Amount: number)
		if not Sticker or not Amount then return end
		
		Sticker:SetAttribute("AmountCollected", Amount)
	end)
end

return StickerController