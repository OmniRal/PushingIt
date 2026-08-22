-- OmniRal

local MainController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UserGameSettings = UserSettings().GameSettings

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ContextActionService = game:GetService("ContextActionService")
--local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)


local CameraController = require(StarterPlayer.StarterPlayerScripts.Source.General.CameraController)
local MainUIController = require(StarterPlayer.StarterPlayerScripts.Source.General.MainUIController)
local AnimationController = require(StarterPlayer.StarterPlayerScripts.Source.General.AnimationController)

local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

local ControlModule

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local VOICELINE_REQUEST_COOLDOWN = 3

local AIM_UP_DEGREES = 40
local AIM_DOWN_DEGREES = -60

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local NPCService = Remotes.Client.NPCService
local DataService = Remotes.Client.DataService
local PushService = Remotes.Client.PushService
local RagdollService = Remotes.Client.RagdollService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
--local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local CharacterSetup = false

--local CurrentlyPushing = false

local PushAnimationsList : {[string]: {ID: number, Priority: Enum.AnimationPriority, Looped: boolean?}} = {
	["StartPush"] = {ID = 128311229502892, Priority = Enum.AnimationPriority.Action2},
    ["ChargePush"] = {ID = 136393663879299, Priority = Enum.AnimationPriority.Action2, Looped = true},
    ["FinishPush"] = {ID = 102907787145425, Priority = Enum.AnimationPriority.Action2},

	["Dodge"] = {ID = 90672690441150, Priority = Enum.AnimationPriority.Action2}
}

local GroundParams = RaycastParams.new()
GroundParams.FilterType = Enum.RaycastFilterType.Include
GroundParams.FilterDescendantsInstances = {Workspace}
GroundParams.IgnoreWater = true

--local Assets = ReplicatedStorage.Assets
--local RNG = Random.new()

local LastNPCVoicelineRequest = 0

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CheckNearNPCs()
	if PlayerInfo.Dead or not PlayerInfo.Root then return end
	if not Workspace:FindFirstChild("NPCs") then return end
	if os.clock() < LastNPCVoicelineRequest + VOICELINE_REQUEST_COOLDOWN then return end

	for _, NPC in Workspace.NPCs:GetChildren() do
		if not NPC then continue end
		if NPC:GetAttribute("Ragdoll") then continue end
		local Human: Humanoid, Root: BasePart = NPC:FindFirstChild("Humanoid"), NPC:FindFirstChild("HumanoidRootPart")
		if not Human or not Root then continue end
		if Human.Health <= 0 then continue end

		if (PlayerInfo.Root.Position - (Root.CFrame * CFrame.new(0, 0, -5)).Position ).Magnitude > 10 then continue end

		LastNPCVoicelineRequest = os.clock()

		NPCService:RequestNormalNPCVoiceline(NPC)
	end
end

-- Check if the player is touching the ground
local function CheckGrounded()
    if PlayerInfo.Dead or not PlayerInfo.Root then 
        if PlayerInfo.Grounded.State then
            PlayerInfo.Grounded.State = false
        end
        return 
    end
    if not GroundParams then 
        PlayerInfo.Grounded.State = false 
        return 
    end

    local SurfaceType = "None"

    local RayDown = Workspace:Raycast(PlayerInfo.Root.Position, Vector3.new(0, -4, 0), GroundParams)
    if RayDown then
        if RayDown.Instance then
            PlayerInfo.Grounded.State = true
            PlayerInfo.Grounded.Surface = RayDown.Instance
            PlayerInfo.Grounded.Position = RayDown.Position
            PlayerInfo.Grounded.Normal = RayDown.Normal

            SurfaceType = RayDown.Instance:GetAttribute("SurfaceType") -- Get the kind of ground the player is standing on

        else
            PlayerInfo.Grounded.State = false
        end
    else
        PlayerInfo.Grounded.State = false
    end

    if LocalPlayer.Character then
        LocalPlayer.Character:SetAttribute("CurrentSurface", SurfaceType)
    end
end

local function UpdateWalkSpeed()
    if not LocalPlayer.Character or PlayerInfo.Dead then return end
    if not PlayerInfo.Human or not PlayerInfo.Root or not PlayerInfo.UnitValues then return end

    local TotalWalkSpeed = PlayerInfo.UnitValues.Base:GetAttribute("WalkSpeed")

    if ControlModule then
         PlayerInfo.MoveVector = ControlModule:GetMoveVector()
    end

    if PlayerInfo.UnitValues.States:GetAttribute("Rooted") then
        TotalWalkSpeed = CustomEnum.RootWalkSpeed
    end

    if PlayerInfo.UnitValues.States:GetAttribute("Stunned") then
        TotalWalkSpeed = 0
    end

    PlayerInfo.Human.WalkSpeed = TotalWalkSpeed
end

-- Update which way the push should be aimed based on the camera look direction
local function UpdatePushAim(GetID: boolean?): number?
	local Degrees = math.deg(math.asin(Camera.CFrame.LookVector.Y))

	local LineID = 2
	if Degrees >= AIM_UP_DEGREES then
		LineID = 1
	elseif Degrees <= AIM_DOWN_DEGREES then
		LineID = 3
	end

	MainUIController.Modules.AimerUI.SetAimerLine(LineID)

	if not GetID then return end
	return LineID
end

local function PushAnimFunc(Keyframe: string, AnimName: string, ...)
    local Params = {...}

	if Params then
		Params[1] = 1
	end

    if Keyframe == "End" then
        if AnimName == "StartPush" then
            AnimationController.PlayNew(LocalPlayer.Character, "PushAnimations", "ChargePush", false, 1)
        
        --elseif AnimName == "FinishPush" then
            --CurrentlyPushing = false
        end

    elseif Keyframe == "Push" then
       	PushService:AttemptPush(UpdatePushAim(true))
	   	MainUIController.ControlPushBar("StopAndHide")

	   	local CooldownTime = SharedGlobalValues.PushCooldown_Base - (SharedGlobalValues.PushCooldown_Subtract * PlayerInfo.Data.Skills.PushCooldown)
	   	MainUIController.RunAbilityCooldown("Push", CooldownTime)
    end
end

local function AttemptPush(_, State: Enum.UserInputState, _: InputObject)
    if not PlayerInfo.Data then return end
	if not PlayerInfo.Data.Skills then return end
	if not PlayerInfo.Data.Skills.PushCooldown then return end
	
	if State == Enum.UserInputState.Begin then
		if PlayerInfo.PushStarted then return end

		local CooldownTime = SharedGlobalValues.PushCooldown_Base - (SharedGlobalValues.PushCooldown_Subtract * (PlayerInfo.Data.Skills.PushCooldown - 1))
		if os.clock() < PlayerInfo.PushDone + CooldownTime then 
			MainUIController.Modules.ErrorMessageUI.New("On cooldown!") 
			return
		end

		local Result = PushService:StartPushCharge()
		if Result == true then
			PlayerInfo.PushStarted = true
			MainUIController.ControlPushBar("Start")
			AnimationController.PlayNew(LocalPlayer.Character, "PushAnimations", "StartPush", false, 1, PushAnimFunc)
			MainUIController.Modules.AimerUI.Toggle(true)
			UpdatePushAim()
		end

    elseif State == Enum.UserInputState.End then
		if not PlayerInfo.PushStarted then return end

		PlayerInfo.PushStarted = false
		PlayerInfo.PushDone = os.clock()
        AnimationController.PlayNew(LocalPlayer.Character, "PushAnimations", "FinishPush", false, 1, PushAnimFunc)
		MainUIController.Modules.AimerUI.Toggle(false)
    end
end

local function AttemptDodge(_, State: Enum.UserInputState, _: InputObject)
	if not PlayerInfo.Data then return end
	if not PlayerInfo.Data.Skills then return end
	if not PlayerInfo.Data.Skills.DodgeCooldown then return end

	if State ~= Enum.UserInputState.Begin then return end

	local CooldownTime = SharedGlobalValues.DodgeCooldown_Base - (SharedGlobalValues.DodgeCooldown_Subtract * (PlayerInfo.Data.Skills.DodgeCooldown))
	if os.clock() < PlayerInfo.DodgeDone + CooldownTime then return end

	local Result = PushService:AttemptDodge()
	if Result == true then
		PlayerInfo.DodgeDone = os.clock()
		AnimationController.PlayNew(LocalPlayer.Character, "PushAnimations", "Dodge", false, 4)

		MainUIController.RunAbilityCooldown("Dodge", CooldownTime)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainController.ToggleBasicControls(SetTo: boolean)
    if SetTo then
        ContextActionService:BindAction("PushControls", AttemptPush, false, Enum.UserInputType.MouseButton1)
		ContextActionService:BindAction("DodgeControls", AttemptDodge, false, Enum.KeyCode.E)

    else
        ContextActionService:UnbindAction("PushControls")
		ContextActionService:UnbindAction("DodgeControls")
    end
end

function MainController.SetCharacter()
    print("Main - Setting character started.")
    if CharacterSetup then
        return
    end
    CharacterSetup = true

    while LocalPlayer.Character == nil do task.wait() end
	while LocalPlayer.Character:FindFirstChild("HumanoidRootPart") == nil do task.wait() end

    PlayerInfo.Human = LocalPlayer.Character:WaitForChild("Humanoid")
    PlayerInfo.Root = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    PlayerInfo.Dead = false
    PlayerInfo.IsRunning = false

    local NewGroundParams = RaycastParams.new()
    NewGroundParams.FilterType = Enum.RaycastFilterType.Exclude
    NewGroundParams.FilterDescendantsInstances = {LocalPlayer.Character}
    NewGroundParams.IgnoreWater = true
    GroundParams = NewGroundParams

    PlayerInfo.Human.Died:Connect(function()
        if not PlayerInfo.Dead then
            PlayerInfo.Dead = true
            CharacterSetup = false
            Camera.CameraSubject = PlayerInfo.Root
            RagdollService:ToggleRagdoll(true)
        end
    end)

    PlayerInfo.Human.Running:Connect(function(Speed: number)
        if Speed > 0 then
            PlayerInfo.IsRunning = true
        else
            PlayerInfo.IsRunning = false
        end
    end)

    PlayerInfo.Human.StateChanged:Connect(function(_: Enum.HumanoidStateType, New: Enum.HumanoidStateType)
        if New == Enum.HumanoidStateType.Jumping or New == Enum.HumanoidStateType.Freefall then
            return
        end
    end)

    LocalPlayer.Character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
        local Toggle = LocalPlayer.Character:GetAttribute("Ragdoll")
        --Human.AutoRotate = not Toggle
        if Toggle then
            PlayerInfo.Human.AutoRotate = false
            PlayerInfo.Human:ChangeState(Enum.HumanoidStateType.Physics)
        else
            PlayerInfo.Human.AutoRotate = true
            PlayerInfo.Human:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)

    CameraController.SetCharacter()
    MainUIController.SetCharacter()
    AnimationController.LoadAnimations(LocalPlayer.Character, "PushAnimations", PushAnimationsList)

    PlayerInfo.UnitValues = LocalPlayer.Character:WaitForChild("UnitValues")

    PlayerInfo.UnitValues.States:GetAttributeChangedSignal("Stunned"):Connect(function()
        
    end)

    print("Main - Setting character complete.")
end

function MainController:RunHeartbeat()
    CheckGrounded()
    UpdateWalkSpeed()
	CheckNearNPCs()
end

function MainController:Init()
    UserGameSettings.RotationType = Enum.RotationType.MovementRelative
    MainController.ToggleBasicControls(true)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
		if not DeltaTime then return end
        MainController:RunHeartbeat()
    end)

	print("Main Controller Init...")
end

function MainController:Deferred()
    local GotControlModule = LocalPlayer:FindFirstChild("PlayerScripts"):FindFirstChild("PlayerModule"):FindFirstChild("ControlModule") :: ModuleScript
    if GotControlModule then
        ControlModule = require(GotControlModule)
    end

	--[[while true do
		task.wait()
		if not Remotes.Client.DataService or not Remotes.Client.PushService then continue end
		DataService = Remotes.Client.DataService
		PushService = Remotes.Client.PushService
		break
	end]]

	Utility.CheckRemotesLoaded({"DataService", "PushService"})

    DataService.FullDataUpdate:Connect(function(Data: any)
        PlayerInfo.Data = Data
        
        if PlayerInfo.CurrentLevel <= -1 then
            PlayerInfo.CurrentLevel = Data.Level
            PlayerInfo.CurrentMaxXP = Utility.LevelXPCurve.CalculateXPNeeded(Data.Level)
            PlayerInfo.CurrentXP = Data.XP
        end

		MainUIController.UpdateAllUI()

        print("Player Data: ", PlayerInfo.Data)
    end)

	DataService.MultiDataUpdate:Connect(function(UpdateList: {[string]: any})
		if not PlayerInfo.Data then return end

        --warn("UPDATED: ", UpdateList)
		
		-- Update the cached player data on the client
		for Entry, Value in UpdateList do
			if PlayerInfo.Data[Entry] == nil then continue end
            --warn(Entry, Value)
			PlayerInfo.Data[Entry] = Value
		end

        --warn("New Data: ", PlayerInfo.Data)
	end)

    DataService.SingleDataUpdate:Connect(function(Index: string | {}, Value: any)
        if not PlayerInfo.Data then return end

		-- Update the cached player data on the client
        if typeof(Index) == "string" then
            if not PlayerInfo.Data[Index] then return end
            PlayerInfo.Data[Index] = Value

        else
            local ThisData = PlayerInfo.Data
            for n = 1, #Index - 1 do
                if ThisData[Index[n]] == nil then continue end
                ThisData = ThisData[Index[n]]
            end

            ThisData[Index[#Index]] = Value

			--warn("CLIENT DATA: ", PlayerInfo.Data)
        end
    end)

	Camera:GetPropertyChangedSignal("CFrame"):Connect(function() 
		if not PlayerInfo.PushStarted then return end
		UpdatePushAim() 
	end)

    PushService.ScoreChanged:Connect(function(Points: number, Streak: number, Multipler: number)
		PlayerInfo.CurrentPoints = Points
		PlayerInfo.CurrentStreak = Streak
		PlayerInfo.CurrentMultiplier = Multipler
    end)

	print("Main Controller Deferred...")
end

return MainController