--!nocheck

local DataService = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')
--local MarketplaceService = game:GetService("MarketplaceService")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local ProfileService = require(ServerScriptService.Source.ProfileService)

local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
local LevelXPCurve = require(ReplicatedStorage.Source.SharedModules.General.Utility.LevelXPCurva)

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

	TimerActive = false,
	SavedTime = 0,

	SkillPoints = 100,
    Skills = {
        ChargePower = 1,
        ChargeSpeed = 1,
		PushCooldown = 1,

		DodgeRange = 1,
		DodgeCooldown = 1,
    }
}

local ProfileStore = ProfileService.GetProfileStore('OmniBlot_PushingIt_Alpha_23', ProfileTemplate)
local Profiles = {}

local UpgradeSkillRequests: {[Player]: boolean} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

function PlayerAdded(Player)
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

function PlayerRemoving(Player: Player)
	local Profile = Profiles[Player]
    if not Profile then return end
	
	Profile.Data.LoggedInDuration += os.time() - Player:GetAttribute("Joined")
	Profile.Data.SavedTime += os.time() - Player:GetAttribute("Joined")
    
	warn("SAVED TIME: ", os.clock() - Player:GetAttribute("Joined"))
	
	Profile:Release()
end

--[[function DataService.Client:GetIndex(...)
	return DataService:GetIndex(...)
end]]

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
            local XPNeededToLevelUp = LevelXPCurve.CalculateXPNeeded(PData.Level)
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

function DataService.WaitForPlayerDataLoaded(Player)
	if Player:GetAttribute("DataLoaded") then return end
	Player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

function DataService:Init()
    Remotes.Server:CreateToClient("FullDataUpdate", {"table"}, "Reliable")
    Remotes.Server:CreateToClient("SingleDataUpdate", {"string | table", "any"}, "Reliable")
	Remotes.Server:CreateToClient("MultiDataUpdate", {"table"}, "Reliable")
    Remotes.Server:CreateToClient("GiveAddXP", {"number"}, "Reliable")

	Remotes.Server:CreateToServer("RequestUpgradeSkill", {"string"}, "Returns", function(Player: Player, ThisSkill: string)
		if not Player then return end

		DataService.WaitForPlayerDataLoaded(Player)
		local PData = Profiles[Player].Data
		if not PData then print("Data not found while trying to upgrade skill for", Player.Name); return "DataMissing"; end
		if not PData.Skills or not PData.SkillPoints then print("Skills or SkillPoints data not found while trying to upgrade skill for", Player.Name); return "DataMissing" end
		if not PData.Skills[ThisSkill] then print(ThisSkill, " is not a valid skill"); return "SkillIncorrect" end
		if PData.Skills[ThisSkill] >= 5 then return "SkillMaxed" end
		if PData.SkillPoints <= 0 then return "NeedSkillPoints" end

		if UpgradeSkillRequests[Player] then return "TooManyRequests" end
		UpgradeSkillRequests[Player] = true

		PData.SkillPoints -= 1
		PData.Skills[ThisSkill] += 1

		Remotes.Server.DataService.MultiDataUpdate:Fire(Player, {SkillPoints = PData.SkillPoints, Skills = PData.Skills})

		task.delay(0.5, function() UpgradeSkillRequests[Player] = false end)

		return 1
	end)

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
