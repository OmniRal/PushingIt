-- OmniRal

local MainUIController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)


local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)
local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)

--local GeneralUILibrary = require(ReplicatedStorage.Source.SharedModules.UI.GeneralUILibrary)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local VisualService = Remotes.VisualService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MainUIController.Menu = "None"

local LocalPlayer = Players.LocalPlayer

local Gui: ScreenGui

local Counter: any

local DraggingUI: {Base: GuiObject?, Element: GuiObject?, Dragging: boolean, DragStart: Vector3?, PositionElement: UDim2?} = {
    Base = nil,
    Element = nil,
    Dragging = false,
    DragStart = nil,
    PositionElement = nil,
}

local Events = ReplicatedStorage.Events
local Assets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CreateNewGui()
    Gui = Assets.UIs.MainGui:Clone()
    Gui.Parent = LocalPlayer.PlayerGui

    task.spawn(function()
        for x = 1, 20 do
            task.wait(0.2)
            for _, OldGui in LocalPlayer.PlayerGui:GetChildren() do
                if not OldGui then continue end
                if OldGui.Name == "MainGui" and OldGui ~= Gui then
                    OldGui:Destroy()
                end
            end
        end
    end)
end

local function SetCounter()
    if not Gui then return end

    local ThisCounter = Gui:FindFirstChild("Counter")
    if not ThisCounter then return end

    Counter = ThisCounter

    Counter:SetAttribute("Score", 0)
    local LastScore = 0

    local UpTween
    local DownTween

    Counter.Visible = true

    local Indexes = {}
    for x = 1, 10 do
        local Index = Counter.Inner.OG_Index:Clone()
        Index.Name = "Index_" .. x
        Index.Position = UDim2.fromScale((x / 10) - 0.1, 0)
        Index.Visible = true
        Index.Parent = Counter.Inner

        for y = 1, 9 do
            local Num = Index.Container.Num:Clone()
            Num.Text = y
            Num.Position = UDim2.fromScale(0, y)
            Num.Parent = Index.Container
        end

        local SpinThread: thread?

        Index:SetAttribute("Goal", -1)
        Index:GetAttributeChangedSignal("Goal"):Connect(function()
            local Goal = Index:GetAttribute("Goal")
            if Goal < 0 then
                return 
            end

            Index:SetAttribute("Goal", -1)

            if SpinThread then
                task.cancel(SpinThread)
            end

            SpinThread = task.spawn(function()
                for _ = 1, 10 do
                    TweenService:Create(Index.Container, TweenInfo.new(0.03, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0, -9)}):Play()
                    task.wait(0.03)
                    Index.Container.Position = UDim2.fromScale(0, 0)
                end
                TweenService:Create(Index.Container, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, -Goal)}):Play()
            end)
        end)

        table.insert(Indexes, Index)
    end

    Counter:GetAttributeChangedSignal("Score"):Connect(function()
        local Score = Counter:GetAttribute("Score")
        local Len = string.len(Score)
        local Text = ""

        local LastLen = string.len(LastScore)
        local LastText = ""

        local Hop = false

        if Score > LastScore then
            --Hop = true
        end

        if Len < 10 then
            for _ = 1, 10 - Len do
                Text = Text .. "0"
            end
        end

        if LastLen < 10 then
            for _ = 1, 10 - LastLen do
                LastText = LastText .. "0"
            end
        end

        Text = Text .. tostring(Score)
        LastText = LastText .. tostring(LastScore)

        if Hop then
            if UpTween then UpTween:Pause() UpTween:Destroy() UpTween = nil end
            if DownTween then DownTween:Pause() DownTween:Destroy() DownTween = nil end

            Counter.Position = UDim2.fromScale(0.05, 0.85)
            UpTween = TweenService:Create(Counter, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.05, 0.825)})
            DownTween = TweenService:Create(Counter, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.05, 0.85)})

            UpTween.Completed:Connect(function()
                DownTween:Play()
            end)

            DownTween.Completed:Connect(function()
                UpTween = nil
                DownTween = nil
            end)

            UpTween:Play()
        end

        for n, Index in ipairs(Indexes) do
            
            local ThisNumFromLast = string.sub(Text, n - 1, n - 1)
            local NextNumFromLast = string.sub(LastText, n - 1, n - 1)
            local ThisNum = string.sub(Text, n, n)
            local Pos = tonumber(ThisNum)

            local Spin = false
            if ThisNumFromLast and NextNumFromLast and ThisNumFromLast ~= NextNumFromLast then
                Spin = true
            end

            if Spin then
                Index:SetAttribute("Goal", Pos)
            else
                Index:SetAttribute("Goal", -1)
                TweenService:Create(Index.Container, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Position = UDim2.fromScale(0, -Pos)
                }):Play()
            end
        end
    end)
end

local function SetGui()
    SetCounter()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainUIController.SetCounter(To: number)
    Counter:SetAttribute("Score", To)
end

function MainUIController.SetCharacter()
    print("Main UI - Setting character started.")
    if LocalPlayer.Character then

        print("Main UI - Setting character complete.")
    end
end

function MainUIController.RunHeartbeat(DeltaTime: number)
end

function MainUIController:Init()
    CreateNewGui()
end

function MainUIController:Deferred()
    SetGui()

    DeviceController.CurrentDevice:Connect(function()
        print("Main UI Controller Device ", DeviceController.CurrentDevice:Get())
    end)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
        MainUIController.RunHeartbeat(DeltaTime)
    end)
end

return MainUIController