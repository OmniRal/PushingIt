-- OmniRal

local PointCounter = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TweenService = game:GetService("TweenService")

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

local LastScore = 0

local Indexes = {}

local Counter: CanvasGroup
local UpTween: Tween?
local DownTween: Tween?

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateCounter()
	local Score = Counter:GetAttribute("Score")
	local Len = string.len(Score)
	local Text = ""

	local LastLen = string.len(LastScore)
	local LastText = ""

	local Hop = false

	if Score > LastScore then
		Hop = true
	end

	if Len < 10 then
		for _ = 1, 10 - Len do Text = Text .. "0" end
	end

	if LastLen < 10 then
		for _ = 1, 10 - LastLen do LastText = LastText .. "0" end
	end

	Text = Text .. tostring(Score)
	LastText = LastText .. tostring(LastScore)

	if Hop then
		if UpTween then UpTween:Pause(); UpTween:Destroy(); UpTween = nil end
		if DownTween then DownTween:Pause(); DownTween:Destroy(); DownTween = nil end

		Counter.Position = UDim2.fromScale(0.05, 0.85)

		UpTween = TweenService:Create(Counter, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.05, 0.825)})
		DownTween = TweenService:Create(Counter, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.05, 0.85)})

		if not UpTween or not DownTween then return end -- Stupid LLP

		UpTween.Completed:Connect(function() DownTween:Play() end)
		DownTween.Completed:Connect(function() UpTween = nil; DownTween = nil end)

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
			TweenService:Create(Index.Container, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, -Pos)}):Play()
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function PointCounter.SetCounter(Gui: ScreenGui)
	if not Gui then return end

	Counter = Gui:FindFirstChild("Counter") :: CanvasGroup
	if not Counter then return end

	local Inner = Counter:FindFirstChild("Index")
	if not Inner then return end

	Counter:SetAttribute("Score", 0)
	Counter.Visible = true

	for x = 1, 10 do
		local Index = Inner.OG_Index:Clone()
		Index.Name = "Index_" .. x
		Index.Position = UDim2.fromScale((x / 10) - 0.1, 0)
		Index.Visible = true
		Index.Parent = Inner

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
		UpdateCounter()
	end)
end

return PointCounter
