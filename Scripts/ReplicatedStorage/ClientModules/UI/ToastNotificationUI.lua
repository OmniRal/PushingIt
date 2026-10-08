-- OmniRal

local ToastNotification = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)
local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DEFAULT_ICON = 0
local NOTIFICATION_DURATION = 5

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DataService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- For all the incoming toast notifications
local Queue: {
	{Type: string, Title: string, Description: string, Icon: number, Active: boolean}
} = {}

local AnimTime = UI_Info.BaseAnimTime

local Template_Notification: any

local UISounds = ReplicatedStorage.Assets.Sounds.UISounds

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Visual stats for the toast
local function UpdateToastVisuals(Button: any, Container: any)
	local Hover, Pressed = Button:GetAttribute("Hover"), Button:GetAttribute("Pressed")

	if not Hover or not Pressed then
		TweenService:Create(Container, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
	
	elseif Hover and not Pressed then
		TweenService:Create(Container, TweenInfo.new(AnimTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1.1, 1.1)}):Play()
		UISounds.Hover:Play()

	elseif Pressed then
		TweenService:Create(Container, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 0.7)}):Play()
		UISounds.Pressed:Play()
	end
end

-- Load the first from the queue as a new toast notification
local function CheckLoadNotification()
	local First = Queue[1]
	if not First or not Template_Notification then return end
	if First.Active then return end

	First.Active = true

	local NewToast = Template_Notification:Clone()
	NewToast.Container.InfoBox.Title.Text = First.Title
	NewToast.Container.InfoBox.Description.Text = First.Description
	NewToast.Container.IconBox.Icon.Image = "rbxassetid://" .. First.Icon
	NewToast.Visible = true
	NewToast.Parent = Template_Notification.Parent

	BasicInteractions.AddButton(NewToast.Button)
	BasicInteractions.ConnectFXInteractionsFN(NewToast.Button, UpdateToastVisuals, false, false, false, false, NewToast.Container)

	NewToast:SetAttribute("Clean", false)
	NewToast:GetAttributeChangedSignal("Clean"):Connect(function()
		if not NewToast:GetAttribute("Clean") then return end

		Queue[1].Active = false
		table.remove(Queue, 1)

		local ClearTween = TweenService:Create(NewToast, TweenInfo.new(AnimTime / 2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(1.25, 0.5)})
		ClearTween.Completed:Connect(function()
			NewToast:Destroy()
			CheckLoadNotification()
		end)
		ClearTween:Play()
	end)

	NewToast.Button.Activated:Connect(function()
		NewToast.Button.Visible = false
		NewToast:SetAttribute("Clean", true)
	end)

	task.delay(AnimTime, function()
		NewToast.Button.Visible = true -- Allow notification to be cleared

		task.wait(NOTIFICATION_DURATION) -- Wait to clear on its own
		NewToast:SetAttribute("Clean", true)
	end)

	TweenService:Create(NewToast, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.99, 0.5)}):Play()
	UISounds.ToastNotification:Play()
end

local function AddToQueue(Type: string, ...)
	if not Type then return end
	local Details = {...}

	local NewEntry = {Type = Type, Title = "", Description = "", Icon = DEFAULT_ICON, Active = false}

	if Type == "NPCs" then
		NewEntry.Title = "New NPC!"
		NewEntry.Description = "Pushed " .. Details[1] .. "!"
	end

	table.insert(Queue, NewEntry)

	CheckLoadNotification()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function ToastNotification.Setup(Gui: ScreenGui)
	if not Gui then return end

	Template_Notification = Gui:FindFirstChild("Template_ToastNotification")
	if not Template_Notification then return end

	Template_Notification.Position = UDim2.fromScale(1.25, 0.5)
	Template_Notification.Visible = false
end

function ToastNotification:Deferred()
	Utility.CheckRemotesLoaded({"DataService", "PushService"})
	DataService = Remotes.Client.DataService

	DataService.Notify:Connect(function(Type: string, ...)
		AddToQueue(Type, ...)
	end)
end

return ToastNotification