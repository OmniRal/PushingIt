-- OmniRal

local ScoreDisplayUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Global = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ANIM_TIME = UI_Info.BaseAnimTime
local TWEEN_STYLE = UI_Info.BaseTweenStyle
local TWEEN_DIR = UI_Info.BaseTweenDir

local ON_POSITION = UDim2.fromScale(0.05, 0.8)
local OFF_POSITION = UDim2.fromScale(0.05, 1.1)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LastScore = 0
local LastStreak = 0
local LastMultiplier = 0

local Indexes: {Frame} = {}

local FinalizeScoreThread: thread?
local BounceThread: thread?

local StreakTween: any
local MultiplierTween: any

local Display: any

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function ToggleEnabled()
	local GoalPosition, GoalTransparency = ON_POSITION, 0
	local EasingStyle, EasingDirection = Enum.EasingStyle.Back, Enum.EasingDirection.Out
	
	if not Display:GetAttribute("Enabled") then
		GoalPosition = OFF_POSITION
		GoalTransparency = 1

		EasingStyle = TWEEN_STYLE
		EasingDirection = TWEEN_DIR
	end

	TweenService:Create(Display, TweenInfo.new(ANIM_TIME, EasingStyle, EasingDirection), {Position = GoalPosition}):Play()
	TweenService:Create(Display.Counter, TweenInfo.new(ANIM_TIME / 2, TWEEN_STYLE, TWEEN_DIR), {BackgroundTransparency = GoalTransparency}):Play()
end

-- Whenever the spinning attribute for this index changes
local function CheckShouldBounce()
	
	local TotalSpinning = 0
	for _, OtherIndex in Indexes do
		if not OtherIndex then continue end
		if not OtherIndex:GetAttribute("Spinning") then continue end
		-- check if other indexes are spinning
		TotalSpinning += 1
	end
	
	-- If 0 are spinning then no bouncing; otherwise bounce
	Display:SetAttribute("Bouncing", if TotalSpinning > 0 then true else false)
end

local function UpdateBouncing()
	if BounceThread  then
		task.cancel(BounceThread)
		BounceThread = nil
	end
	
	if Display:GetAttribute("Bouncing") then
		BounceThread = task.spawn(function()
			while true do
				TweenService:Create(Display.Counter, TweenInfo.new(ANIM_TIME / 8, TWEEN_STYLE, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 0.45)}):Play()
				task.wait(ANIM_TIME / 8)
				TweenService:Create(Display.Counter, TweenInfo.new(ANIM_TIME / 4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
				task.wait(ANIM_TIME / 4)
				
				CheckShouldBounce()
			end
		end)
	else
		TweenService:Create(Display.Counter, TweenInfo.new(ANIM_TIME / 2, TWEEN_STYLE, TWEEN_DIR), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	end
end

local function UpdatePoints()
	local Score = Display:GetAttribute("Score")
	local Len, LastLen = string.len(Score), string.len(LastScore)
	local Text, LastText = "", ""
	
	if Len < 10 then
		for _ = 1, 10 - Len do Text = Text .. "0" end
	end
	
	if LastLen < 10 then
		for _ = 1, 10 - LastLen do LastText = LastText .. "0" end
	end
	
	Text = Text .. tostring(Score)
	LastText = LastText .. tostring(LastScore)
	
	-- Start changing the numbers in each column
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
			TweenService:Create(Index.Container, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, -Pos)}):Play()
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Init
function ScoreDisplayUI.Setup(Gui: ScreenGui)
	
	Display = Gui:FindFirstChild("ScoreDisplay") :: Frame
	if not Display then return end
	
	Display:SetAttribute("Enabled", false)
	Display:SetAttribute("Bouncing", false)
	Display:SetAttribute("Score", 0)
	Display:SetAttribute("Streak", 0)
	Display:SetAttribute("Multiplier", 0)
	
	Display.Position = OFF_POSITION
	Display.Visible = true

	for x = 1, 10 do
		-- Add individual number columns
		local Index = Display.Counter.Inner.OG_Index:Clone()
		Index.Name = "Index_" .. x
		Index.Position = UDim2.fromScale((x / 10) - 0.1, 0)
		Index.Visible = true
		Index.Parent = Display.Counter.Inner
		
		-- Make sure each column has 0 - 9
		for y = 1, 9 do
			local Num = Index.Container.Num:Clone()
			Num.Text = y
			Num.Position = UDim2.fromScale(0, y)
			Num.Parent = Index.Container
		end
		
		local SpinThread: thread? -- Gives the appearence of the column Bouncing like a slot machine
		
		Index:SetAttribute("Goal", -1)
		Index:SetAttribute("Spinning", false)
		
		Index:GetAttributeChangedSignal("Goal"):Connect(function()
			local Goal = Index:GetAttribute("Goal")
			if Goal < 0 then return end
			
			Index:SetAttribute("Goal", -1)
			Index:SetAttribute("Spinning", true)
			
			if SpinThread then task.cancel(SpinThread) end
			SpinThread = task.spawn(function()
				for _ = 1, 10 do
					TweenService:Create(Index.Container, TweenInfo.new(0.03, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0, -9)}):Play()
					task.wait(0.03)
					Index.Container.Position = UDim2.fromScale(0, 0)
				end
				
				TweenService:Create(Index.Container, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, -Goal)}):Play()
				Index:SetAttribute("Spinning", false)
			end)
		end)
		
		Index:GetAttributeChangedSignal("Spinning"):Connect(function()
			CheckShouldBounce()
		end)
		
		table.insert(Indexes, Index)
	end
	
	Display:GetAttributeChangedSignal("Enabled"):Connect(function()
		ToggleEnabled()
	end)
	
	-- Whole display bounces up a little really quick
	Display:GetAttributeChangedSignal("Bouncing"):Connect(function()
		UpdateBouncing()
	end)
	
	Display:GetAttributeChangedSignal("Score"):Connect(function()
		UpdatePoints()
	end)

	Display:GetAttributeChangedSignal("Streak"):Connect(function()
		local Streak = Display:GetAttribute("Streak")
		
		if Streak > LastStreak then
			if StreakTween then StreakTween:Pause(); StreakTween:Destroy(); StreakTween = nil end
			
			Display.Streak.Num.Position = UDim2.fromScale(0, -0.3)
			StreakTween = TweenService:Create(Display.Streak.Num, TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
			{Position = UDim2.fromScale(0, 0)}):Play()
		end
		
		Display.Streak.Num.Text = Streak
		LastStreak = Streak
	end)

	Display:GetAttributeChangedSignal("Multiplier"):Connect(function()
		local Multiplier = Display:GetAttribute("Multiplier")
		
		if Multiplier > LastMultiplier then
			if MultiplierTween then MultiplierTween:Pause(); MultiplierTween:Destroy(); MultiplierTween = nil end
			
			Display.Multiplier.Num.Position = UDim2.fromScale(0, -0.3)
			MultiplierTween = TweenService:Create(Display.Multiplier.Num, TweenInfo.new(ANIM_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
			{Position = UDim2.fromScale(0, 0)}):Play()
		end
		
		Display.Multiplier.Num.Text = Multiplier .. "x"
		LastMultiplier = Multiplier
	end)

	Display.Counter:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		Display.Counter.Inner.GroupTransparency = Display.Counter.BackgroundTransparency
		Display.Counter.Stroke.Transparency = Display.Counter.BackgroundTransparency
	end)
end

-- Change the number
function ScoreDisplayUI.UpdateScore(Points: number, Streak: number, Multiplier: number)
	if Points <= 0 then return end

	if FinalizeScoreThread then
		task.cancel(FinalizeScoreThread)
	end

	FinalizeScoreThread = task.delay(Global.ScoreFinalizeTime, function()
		Display:SetAttribute("Enabled", false)
		Display:SetAttribute("Score", 0)
		Display:SetAttribute("Streak", 0)
		Display:SetAttribute("Multiplier", 0)
	end)
	
	Display:SetAttribute("Enabled", true)
	Display:SetAttribute("Score", Points)
	Display:SetAttribute("Streak", Streak)
	Display:SetAttribute("Multiplier", Multiplier)
end

return ScoreDisplayUI
