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
        TimePlayed = {Seconds = 0, Minutes = 0, Hours = 0, Days = 0},
    },

    XP = 0,
    Level = 1,
	Points = 0,

    Skills = {
        ChargePower = 2,
        ChargeSpeed = 1,
		ChargeCooldown = 1,

		DodgeRange = 1,
		DodgeCooldown = 1,
    }
}

local ProfileStore = ProfileService.GetProfileStore('OmniBlot_PushingIt_Alpha_8', ProfileTemplate)
local Profiles = {}

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
            Remotes.DataService.FullDataUpdate:Fire(Player, Profiles[Player].Data)
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

function PlayerRemoving(Player)
    task.wait(0.25)
	local profile = Profiles[Player]
    if profile ~= nil then
		profile.Data.LoggedInDuration += os.time() - Player:GetAttribute("Joined")
        profile:Release()
    end
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

function DataService.GetIndex(Player, Index)
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

function DataService.SetIndex(Player: Player, Index: string | {}, Value: string? | number? | boolean? | {}?)
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

    Remotes.DataService.SingleDataUpdate:Fire(Player, Index, Value)
    --Remotes.DataService.DataUpdate:Fire(Player, Profiles[Player].Data)
end

function DataService.IncrementIndex(Player, Index, Increment)
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

        if PData.Level < NewLevel then
            PData.Level = NewLevel
            Remotes.DataService.SingleDataUpdate:Fire(Player, "Level", NewLevel)
        end

        PData.XP = CurrentXP
        Remotes.DataService.SingleDataUpdate:Fire(Player, "XP", CurrentXP)
        Remotes.DataService.GiveAddXP:Fire(Player, Increment)
        return
    end

	PData[Index] += Increment
    Remotes.DataService.SingleDataUpdate:Fire(Player, Index, PData[Index])

    --Remotes.DataService.DataUpdate:Fire(Player, Profiles[Player].Data)
end

function DataService.WaitForPlayerDataLoaded(Player)
	if Player:GetAttribute("DataLoaded") then return end
	Player:GetAttributeChangedSignal("DataLoaded"):Wait()
end

function DataService:Init()
    Remotes:CreateToClient("FullDataUpdate", {"table"}, "Reliable")
    Remotes:CreateToClient("SingleDataUpdate", {"string | table", "any"}, "Reliable")
    Remotes:CreateToClient("GiveAddXP", {"number"}, "Reliable")

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

    print("Template Ready : ", ProfileTemplate)
end

function DataService:Deferred()
    print("Data Service Deferred...")
    self.ServiceReady = true
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
