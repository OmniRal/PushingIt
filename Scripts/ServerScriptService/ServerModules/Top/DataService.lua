--!nocheck

local DataService = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')
--local MarketplaceService = game:GetService("MarketplaceService")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local ProfileService = require(ServerScriptService.Source.ProfileService)

local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

--local ProductInfo = require(ReplicatedStorage.Source.SharedModules.Info.ProductInfo)
--local ShopInfo = require(ReplicatedStorage.Source.SharedModules.Info.ShopInfo)
--local BadgeInfo = require(ReplicatedStorage.Source.SharedModules.Info.BadgeInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DataService.ProfileReady = false
DataService.ServiceReady = false

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ProfileTemplate = {
	LogInTimes = 0,
	LoggedInDuration = 0,
	LastLoggedIn = 0,
	
	PlayStats = {
		TimerRecord = 0,
		PlayTime = 0
	},
	
	XP = 0,
	Level = 1,
	Points = 0,
	
	PVPMode = true,
	LastPVPChange = 0,
	
	SavedTime = 0,
	TimerActive = false,
	TimerStartedAt = 0,
	
	SkillPoints = 100,
	Skills = {
		ChargePower = 1,
		ChargeSpeed = 1,
		PushCooldown = 1,
		
		DodgeRange = 1,
		DodgeCooldown = 1,
	},

	NPCs = {
		-- [string]: {Time: number, Pushes: number, New: boolean}
	},

	Stamps = {
		-- [string]: {Time: number, New: boolean}
	},
}

local ProfileStore = ProfileService.GetProfileStore('OmniBlot_PushingIt_Alpha_35', ProfileTemplate)
local Profiles = {}

local UpgradeSkillRequests: {[Player]: boolean} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

local function PlayerAdded(Player)
	while not DataService.ProfileReady or not DataService.ServiceReady do
		task.wait()
	end
	
	Player:SetAttribute("Joined", os.time())
	
	local profile = ProfileStore:LoadProfileAsync("Player_" .. Player.UserId)
	print("Loaded profile : ", profile)
	if profile ~= nil then
		profile:AddUserId(Player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		--print("R: ", profile)
		profile:ListenToRelease(function()
			Profiles[Player] = nil
			-- The profile could"ve been loaded on another Roblox server:
			Player:Kick("Could not load player data (1)")
		end)
		
		if Player:IsDescendantOf(Players) == true then
			Profiles[Player] = profile
			-- A profile has been successfully loaded:
			profile.Data.LogInTimes += 1
			profile.Data.LastLoggedIn = os.time()
			
			Player:SetAttribute("DataLoaded", true)
			Remotes.Server.DataService.FullDataUpdate:Fire(Player, Profiles[Player].Data)
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn"t be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		Player:Kick("Could not load player data (2)")
	end
end

local function PlayerRemoving(Player: Player)
	local Profile = Profiles[Player]
	if not Profile then return end
	
	Profile.Data.LoggedInDuration += os.time() - Player:GetAttribute("Joined")

	if Profile.Data.PVPMode then
		Profile.Data.SavedTime += os.time() - Player:GetAttribute("Joined")
	else
		Profile.Data.SavedTime = 0
	end
	
	warn("SAVED TIME: ", os.clock() - Player:GetAttribute("Joined"))
	
	Profile:Release()
end

--[[function DataService.Client:GetIndex(...)
return DataService:GetIndex(...)
end]]

local function RequestChangePVPMode(Player: Player)
	if not Player then return end
	if not Player.Character then return "Dead!" end -- Needs to exist and be alive
	local Alive: boolean, _, Human: Humanoid, Root: BasePart = Utility.Players.CheckAlive(Player)
	if not Alive or not Human or not Root then return "Dead!" end
	
	-- Make sure the player is not moving
	if Human.MoveDirection.Magnitude > SharedGlobalValues.ChangePVPMode_PlayerVelocityTolerance then return "Cange change while moving!" end
	if Root.AssemblyAngularVelocity.Magnitude > SharedGlobalValues.ChangePVPMode_PlayerVelocityTolerance then return "Can't change while moving!" end
	
	-- Make sure not close to other players
	for _, OtherPlayer in Players:GetPlayers() do
		if not OtherPlayer then continue end
		if OtherPlayer == Player then continue end
		local OtherAlive: boolean, _, _, OtherRoot: BasePart = Utility.Players.CheckAlive(OtherPlayer)
		if not OtherAlive or not OtherRoot then continue end
		
		if (Root.Position - OtherRoot.Position).Magnitude > SharedGlobalValues.ChangePVPMode_PlayerRange then continue end
		
		return "Too close to other players!"
	end
	
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	if not PData then print("Data not found while trying to change PVP Mode for", Player.Name); return "DataMissing" end
	if PData.PVPMode == nil or PData.LastPVPChange == nil then print("PVPMode or LastPVPChange data not found while trying to change PVP mode for", Player.Name); return end
	
	-- Make sure its not on cooldown

	if os.time() < PData.LastPVPChange + SharedGlobalValues.ChangePVPModeCooldown then return "On cooldown!" end
	
	-- Save data
	PData.LastPVPChange = os.time()
	PData.PVPMode = not PData.PVPMode
	PData.SavedTime = 0
	PData.TimerActive = PData.PVPMode
	PData.TimerStartedAt = os.clock()

	warn("Changing!!")

	-- Send updated data to player
	Remotes.Server.DataService.MultiDataUpdate:Fire(Player, {
		LastPVPChange = os.time(),
		PVPMode = PData.PVPMode,
		SavedTime = PData.SavedTime,
		TimerActive = PData.TimerActive,
		TimerStartedAt = os.clock()
	})

	-- Change respective attributes (they exist so other players can see how who is in PVP mode and their timers)
	Player:SetAttribute("PVPMode", PData.PVPMode)
	Player:SetAttribute("SavedTime", 0)
	Player:SetAttribute("TimerActive", PData.TimerActive)
	Player:SetAttribute("TimerStartedAt", os.clock()) 
	
	return 1
end

local function RequestUpgradeSkill(Player: Player, ThisSkill: string)
	if not Player then return end
	
	-- Check if they are allowed to
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	if not PData then print("Data not found while trying to upgrade skill for", Player.Name); return "-DataMissing"; end
	if not PData.Skills or not PData.SkillPoints then print("Skills or SkillPoints data not found while trying to upgrade skill for", Player.Name); return "-DataMissing" end
	if not PData.Skills[ThisSkill] then print(ThisSkill, " is not a valid skill"); return "-SkillIncorrect" end
	if PData.Skills[ThisSkill] >= 5 then return "Skill maxed!" end
	if PData.SkillPoints <= 0 then return "Need skill points!" end
	
	-- Prevent too many changes at once
	if UpgradeSkillRequests[Player] then return "TooManyRequests" end
	UpgradeSkillRequests[Player] = true
	
	PData.SkillPoints -= 1
	PData.Skills[ThisSkill] += 1
	
	Remotes.Server.DataService.MultiDataUpdate:Fire(Player, {SkillPoints = PData.SkillPoints, Skills = PData.Skills})
	
	-- Decent cooldown before can upgrade again
	task.delay(0.5, function() UpgradeSkillRequests[Player] = false end)
	
	return 1
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function DataService.GetProfileTable(Player: Player)
	while not DataService.ServiceReady do
		task.wait()
	end
	while Profiles[Player] == nil do
		task.wait()
	end
	return Profiles[Player].Data
end

function DataService.GetIndex(Player: Player, Index: string): boolean | number | string | {}
	DataService.WaitForPlayerDataLoaded(Player)
	return Profiles[Player].Data[Index]
end

-- Returns a players current skill levels
function DataService.GetSkills(Player: Player): {[string]: number}
	DataService.WaitForPlayerDataLoaded(Player)
	
	return Profiles[Player].Data.Skills
end

-- Returns one specific skill level of a player
function DataService.GetOneSkill(Player: Player, ThisSkill:  string): number?
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	
	if not PData.Skills[ThisSkill] then return end
	return PData.Skills[ThisSkill]
end

function DataService.SetIndex(Player: Player, Index: string | {}, Value: string? | number? | boolean? | {}?, DoNotSendUpdate: boolean?)
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	
	if typeof(Index) == "string" then
		PData[Index] = Value
	else
		local ThisData = PData
		for n = 1, #Index - 1 do
			ThisData = ThisData[Index[n]]
		end
		ThisData[Index[#Index]] = Value
	end
	
	if DoNotSendUpdate then return end
	Remotes.Server.DataService.SingleDataUpdate:Fire(Player, Index, Value)
end

function DataService.IncrementIndex(Player: Player, Index: string, Increment: number, DoNotSendUpdate: boolean?)
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	
	if Index == "XP" then
		local NewLevel = PData.Level
		local CurrentXP = PData.XP + Increment
		
		-- Check what the new level will be based on how much xp
		for _ = PData.Level, SharedGlobalValues.MaxLevel do
			local XPNeededToLevelUp = Utility.LevelXPCurve.CalculateXPNeeded(PData.Level)
			if CurrentXP >= XPNeededToLevelUp then
				CurrentXP -= XPNeededToLevelUp
				NewLevel += 1
			else
				break
			end
		end
		
		if NewLevel >= SharedGlobalValues.MaxLevel then
			CurrentXP = 0
		end
		
		local UpdateList = {}
		
		if PData.Level < NewLevel then
			PData.Level = NewLevel
			PData.SkillPoints += 1
			
			UpdateList["Level"] = NewLevel
			UpdateList["SkillPoints"] = PData.SkillPoints
		end
		
		PData.XP = CurrentXP
		
		Remotes.Server.DataService.MultiDataUpdate:Fire(Player, UpdateList)
		Remotes.Server.DataService.GiveAddXP:Fire(Player, Increment)
		return
	end
	
	PData[Index] += Increment
	
	if DoNotSendUpdate then return end
	Remotes.Server.DataService.SingleDataUpdate:Fire(Player, Index, PData[Index])
end

function DataService.AddNPCPushCount(Player: Player, NPCName: string)
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	if not PData then return end
	if not PData.NPCs then return end

	if not PData.NPCs[NPCName] then
		-- If the NPC isn't added already, add it
		PData.NPCs[NPCName] = {Time = os.time(), Pushes = 1, New = true}
		Remotes.Server.DataService.SingleDataUpdate:Fire(Player, {"NPCs", NPCName}, PData.NPCs[NPCName])
	else
		-- NPC exists, just add up the total pushes
		PData.NPCs[NPCName].Pushes += 1
		Remotes.Server.DataService.SingleDataUpdate:Fire(Player, {"NPCs", NPCName, "Pushes"}, PData.NPCs[NPCName].Pushes)
	end
end

function DataService.CollectStamp(Player: Player, StampName: string): boolean
	DataService.WaitForPlayerDataLoaded(Player)
	local PData = Profiles[Player].Data
	if not PData then return false end
	if not PData.Stamps then return false end

	if PData.Stamps[StampName] then return false end

	PData.Stamps[StampName] = {Time = os.time(), New = true}
	Remotes.Server.DataService.SingleDataUpdate:Fire(Player, {"Stamps", StampName}, PData.Stamps[StampName])

	return true
end

function DataService.WaitForPlayerDataLoaded(Player)
	if Player:GetAttribute("DataLoaded") then return end
	Player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

function DataService:Init()
	Remotes.Server:CreateToClient("FullDataUpdate", {"table"}, "Reliable")
	Remotes.Server:CreateToClient("SingleDataUpdate", {"string | table", "any"}, "Reliable")
	Remotes.Server:CreateToClient("MultiDataUpdate", {"table"}, "Reliable")
	Remotes.Server:CreateToClient("GiveAddXP", {"number"}, "Reliable")
	
	Remotes.Server:CreateToServer("RequestNotNew", {"table"}, "Returns", function(Player: Player, Item) end)
	Remotes.Server:CreateToServer("RequestChangePVPMode", {}, "Returns", function(Player: Player) return RequestChangePVPMode(Player) end)
	Remotes.Server:CreateToServer("RequestUpgradeSkill", {"string"}, "Returns", function(Player: Player, ThisSkill: string) return RequestUpgradeSkill(Player, ThisSkill) end)
	
	--[[for WeaponName, W_Info in pairs(WeaponInfo) do
	local WeaponUnlocked = false
	if W_Info.UnlockedBy == "Default" then
		WeaponUnlocked = true
	end 
	
	local Skins = {}
	for SkinName, S_Info in pairs(W_Info.Skins) do
		local SkinUnlocked = false
		if S_Info.UnlockedBy == "Default" then
			SkinUnlocked = true
		end
		Skins[SkinName] = {Unlocked = SkinUnlocked, Date = "2023:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", IsNew = true}
	end
	
	ProfileTemplate.Weapons[WeaponName] = {Unlocked = WeaponUnlocked, Date = "2024:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", IsNew = true, Skins = Skins, EquippedSuit = "Default"}
	
	ProfileTemplate.Stats.Weapons[WeaponName] = {
	TimePlayed = {Seconds = 0, Minutes = 0, Hours = 0, Days = 0},
	Kills = 0,
	Assists = 0,
	}
end]]

self.ProfileReady = true

------------------------------------------------------------------------------------------------------------------

print("Data Service Init...")
end

function DataService:Deferred()
	self.ServiceReady = true
	
	print("Data Service Deferred...")
end

function DataService.PlayerAdded(Player: Player)
	task.spawn(function()
		PlayerAdded(Player)
	end)
end

function DataService.PlayerRemoving(Player: Player)
	task.spawn(function()
		PlayerRemoving(Player)
	end)
end

return DataService
