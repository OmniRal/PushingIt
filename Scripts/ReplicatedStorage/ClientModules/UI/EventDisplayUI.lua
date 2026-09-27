-- OmniRal

local EventDisplayUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local EventTracker
local Display

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateEventFrame(Ref: Configuration, Frame: Frame)
	local State = Ref:GetAttribute("State")
	Frame.Visible = if State == "Active" then true else false

	if State == "Active" then
		local Now = Workspace:GetServerTimeNow()
		local TimePassed = math.abs(Ref:GetAttribute("TimeStartedAt") - Now)
		local Duration = Ref:GetAttribute("Duration")
		local TimeBar = Frame:FindFirstChild("TimeBar")

		TimeBar.Size = UDim2.fromScale(1 - math.clamp(TimePassed / Duration, 0, 1), 1)
		TweenService:Create(TimeBar, TweenInfo.new(math.clamp(Duration - TimePassed, 0, Duration), Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)}):Play()
	end
end

local function WireEventRefs()
	for _, Ref in EventTracker:GetChildren() do
		if not Ref then return end

		-- Create the UI frame for the event
		local Frame = Display.OG:Clone()
		Frame.Name = Ref.Name
		Frame.BackgroundColor3 = Ref:GetAttribute("Color")
		Frame.Icon.Image = "rbxassetid://" .. Ref:GetAttribute("Icon")
		Frame.Visible = false
		Frame.Parent = Display

		Ref:GetAttributeChangedSignal("State"):Connect(function() UpdateEventFrame(Ref, Frame) end)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function EventDisplayUI.Setup(Gui: ScreenGui)
	Display = Gui:FindFirstChild("EventDisplay")
	if not Display then warn("EventDisplay is missing!"); return end

	EventTracker = ReplicatedStorage:WaitForChild("EventTracker", 3)
	Display.OG.Visible = false

	WireEventRefs()
end

return EventDisplayUI