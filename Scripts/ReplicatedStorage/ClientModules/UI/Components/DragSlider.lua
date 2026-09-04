-- OmniRal

local DragSlider = {}

-- Sets up the horizontal (and vertical in future?) draggable sliders

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetNearestFixedPosition(FixedPositions: {number}, CurrentPosition: number): number
	local NewPosition = 0
	local LastDistance = math.huge

	for _, FPosition: number in ipairs(FixedPositions) do
		local Distance = math.abs(CurrentPosition - FPosition)
		if Distance >= LastDistance then continue end

		LastDistance = Distance
		NewPosition = FPosition
	end
	
	return NewPosition
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- @Slider = The slider to set up
-- @Fn = This runs whenever the slider gets moved
-- @Range = The min and max value that the slider represents
-- @Increments = How many pieces Range (must exist) should be cut up in
-- @StartValue = Moves the slider to this start value
function DragSlider.Set(Slider: Frame, Fn: (number, ...any) -> (...any), Range: NumberRange, Increments: number?, StartValue: number?, EndFn: (...any) -> (...any)?, IntegersOnly: boolean?)
	local Bar = Slider:FindFirstChild("Bar") :: Frame
	if not Bar then warn("Missing Bar in Slider!") return end
	
	local Line, Button = Bar:FindFirstChild("Line") :: Frame, Bar:FindFirstChild("Button") :: ImageButton
	if not Line or not Button then warn("Missing Line or Button in Slider!") return end
	
	local FixedPositions: {number} = {}
	local TextBar = Slider:FindFirstChild("TextBar")
	
	local function UpdateFixedPositions()
		if not Range or not Increments then return end
		
		-- Cut the line into increments here
		FixedPositions = {0}

		local Inc = 1 / Increments

		for x = 1, Increments do
			local NewPosition = (Line.AbsoluteSize.X) * (Inc * x)
			table.insert(FixedPositions, NewPosition)
		end
	end
	
	local function CalculateSliderPosition(ElementPosition: UDim2, StartPosition: Vector3, CurrentPosition: Vector3)
		local Delta = CurrentPosition - StartPosition
		
		if not Range or not Increments then
			-- Free sliding
			Button.Position = UDim2.new(0, math.clamp(ElementPosition.X.Offset + Delta.X, 0, math.round(Line.AbsoluteSize.X)), 0.5, 0)

		else
			-- Fixed sliding
			local DraggingPosition = math.clamp(ElementPosition.X.Offset + Delta.X, 0, math.round(Line.AbsoluteSize.X))
			local NewPosition = GetNearestFixedPosition(FixedPositions, DraggingPosition)

			Button.Position = UDim2.new(0, NewPosition, 0.5, 0)
		end
	end
	
	local function MoveSliderHere(ThisValue: number)
		local Percent = ThisValue / Range.Max
		local Pos = math.round(Line.AbsoluteSize.X) * Percent
		if not Range or not Increments then
			Button.Position = UDim2.new(0, Pos, 0.5, 0)
		else
			Button.Position = UDim2.new(0, GetNearestFixedPosition(FixedPositions, Pos), 0.5, 0)
		end
	end
	
	local function FinalizeCalculations(IgnoreReturn: boolean?, OverrideValue: number?)
		local Percent = Button.Position.X.Offset / math.round(Line.AbsoluteSize.X) -- What gets sent back when no Range is given
		local FinalValue = OverrideValue or Percent

		if Range then
			-- If Range, calculate
			FinalValue = OverrideValue or Range.Min + ((Range.Max - Range.Min) * Percent)
			if IntegersOnly and not OverrideValue then FinalValue = math.round(FinalValue) end
			if TextBar then
				TextBar.Box.Text = FinalValue
				TextBar.Box.PlaceholderText = FinalValue
			end
		end

		Slider:SetAttribute("CurrentVal", FinalValue)

		if IgnoreReturn then return end
		Fn(FinalValue)
	end
	
	if TextBar and Range then
		-- Update slider when text bar changes
		TextBar.Box.PlaceholderColor3 = Color3.fromRGB(200, 200, 200)
		TextBar.Box.PlaceholderText = StartValue or 0
		
		TextBar.Box.FocusLost:Connect(function()
			local Val = tonumber(TextBar.Box.Text)
			local Revert = false

			if not Val then Revert = true; end
			if Val and (Val < Range.Min or Val > Range.Max) then Revert = true; end
			if IntegersOnly and string.match(TextBar.Box.Text, "^%d+$") then Revert = true; end

			if not Revert then
				-- Make sure it's a number with no decimals
				MoveSliderHere(Val)
				FinalizeCalculations(false, Val)
				
			else
				-- Revert text to what it was before
				FinalizeCalculations(true)
			end
		end)
	end
	
	BasicInteractions.AddButton(Button, false, false, Button,
		nil, 
		UpdateFixedPositions, 
		function(ElementPosition: UDim2, StartPosition: Vector3, CurrentPosition: Vector3)
			CalculateSliderPosition(ElementPosition, StartPosition, CurrentPosition)
			FinalizeCalculations()
		end, 
		EndFn or nil
	)
	
	Slider:SetAttribute("CurrentVal", StartValue or 0)
	Slider:SetAttribute("SetVal", StartValue or 0) -- Change the value externally
	Slider:GetAttributeChangedSignal("SetVal"):Connect(function()
		local Val = Slider:GetAttribute("SetVal")
		if Val == Slider:GetAttribute("CurrentVal") then return end

		local Revert = false
		if Val and (Val < Range.Min or Val > Range.Max) then Revert = true; end
		if IntegersOnly and string.match(TextBar.Box.Text, "^%d+$") then Revert = true; end

		if not Revert then
			MoveSliderHere(Val)
			Slider:SetAttribute("CurrentVal", Val)
		else
			-- Revert SetVal back to what it was before
			Slider:SetAttribute("SetVal", Slider:GetAttribute("CurrentVal"))
		end
		
		if not TextBar then return end
		TextBar.Box.Text = Slider:GetAttribute("CurrentVal")
		TextBar.Box.PlaceholderText = Slider:GetAttribute("CurrentVal")
	end)
	
	-- Update where the slider is
	Slider:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		MoveSliderHere(Slider:GetAttribute("CurrentVal") :: number)
	end)
	
	if not StartValue then return end
	
	UpdateFixedPositions()
	MoveSliderHere(StartValue)
	
	if not TextBar then return end
	TextBar.Box.Text = StartValue
end

return DragSlider