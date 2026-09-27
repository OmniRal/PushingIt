-- OmniRal

local EventService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AllEvents: {
	[string]: {
		State: "Inactive" | "Active" | "OnCooldown",
		ActiveTime: number, -- How many seconds it runs when active
		CooldownTime: number, -- How many seconds the event is on cooldown before being usable again
		FromPlayer: Player?, -- Which player purchased this event
		DisplayName: string,
		Color: Color3,
		Icon: number,
		Ref: Configuration?,
	}
} = {
	RainBananaPeels = {
		State = "None",
		ActiveTime = 30,
		CooldownTime = 60 * 5,
		DisplayName = "Rain Banana Peels!",
		Color = Color3.fromRGB(255, 227, 54),
		Icon = 108754125315510,
	}
}

local Modules = {} -- Modules for the individual events functionality

local EventTracker = Instance.new("Folder")
EventTracker.Name = "EventTracker"
EventTracker.Parent = ReplicatedStorage
-- Folder that contains references for all the events
-- Purely for the client to display each events data on their UI

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Run the specific event
function EventService.RunEvent(ThisEvent: string, FromPlayer: Player)
	local Data = AllEvents[ThisEvent]
	local Module = Modules[ThisEvent]
	if not Data or not Module then return end
	if Data.State ~= "None" then return end
	if Data.Ref == nil or Module.Run == nil then return end

	Data.State = "Active"
	Data.Ref:SetAttribute("State", "Active")
	Data.Ref:SetAttribute("FromPlayer", FromPlayer.Name)
	Data.Ref:SetAttribute("FromPlayerUserID", FromPlayer.UserId)
	Data.Ref:SetAttribute("TimeStartedAt", Workspace:GetServerTimeNow())

	task.delay(Data.ActiveTime, function()
		Data.State = "OnCooldown"
		Data.Ref:SetAttribute("State", "OnCooldown")
		
		task.wait(Data.CooldownTime)

		Data.State = "Inactive"
		Data.Ref:SetAttribute("State", "Inactive")
	end)
	Remotes.Server.EventService.NewEventStarted:FireAll(ThisEvent, FromPlayer.Name)

	Module.Run(Data.ActiveTime)
end

function EventService:Init()
	Remotes.Server:CreateToClient("NewEventStarted", {"string", "string"}, "Reliable")
end

function EventService:Deferred()
	-- Get all the event modules
	for _, Script in script:GetChildren() do
		if not Script:IsA("ModuleScript") then continue end
		Modules[Script.Name] = require(Script)
	end

	-- Fill the folder with all the event references
	for Name, Data in AllEvents do
		local Ref = Instance.new("Configuration")
		Ref.Name = Name
		Ref:SetAttribute("State", "None")
		Ref:SetAttribute("FromPlayer", "None")
		Ref:SetAttribute("FromPlayerUserID", 0)
		Ref:SetAttribute("TimeStartedAt", 0)
		Ref:SetAttribute("Duration", Data.ActiveTime)
		Ref:SetAttribute("Color", Data.Color)
		Ref:SetAttribute("Icon", Data.Icon)
		Ref.Parent = EventTracker

		Data.Ref = Ref
	end

	task.delay(2, function()
		--Modules.RainBananas.Run(AllEvents.RainBananas.ActiveTime)
	end)
end

return EventService