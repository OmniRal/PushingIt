-- OmniRal

local SoundController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

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

local Sounds = ReplicatedStorage.Assets.Sounds

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Put all the sounds in their correct sound groups
local function AssignSoundGroups()
	for _, Sound in Sounds:GetDescendants() do
		if not Sound:IsA("Sound") then continue end
		local ThisGroup = Sound:GetAttribute("SoundGroup")
		if not ThisGroup then continue end
		if not SoundService:FindFirstChild(ThisGroup) then continue end
		Sound.SoundGroup = SoundService[ThisGroup]
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Makes a copy of a sound, plays it, and destroys it once the sound has completed playing
function SoundController.PlayCopyAndClean(ThisSound: Sound, PlaybackSpeedVariation: NumberRange?)
	if not ThisSound then return end

	local Copy = ThisSound:Clone()
	Copy.Name = ThisSound.Name .. "_Copy"
	if PlaybackSpeedVariation then
		Copy.PlaybackSpeed = RNG:NextNumber(PlaybackSpeedVariation.Min, PlaybackSpeedVariation.Max)
	end
	Copy.Parent = ThisSound.Parent
	Copy:Play()

	Copy.Ended:Connect(function()
		Debris:AddItem(0.2, Copy) -- Buffer for a cleaner transition
	end)
end

-- Play a sound but add variation to its playback speed
function SoundController.PlaySoundWithRNG(ThisSound: Sound, PlaybackSpeedVariation: NumberRange, Delay: number?, Volume: number?)
    if not ThisSound then return end
    if Volume then  ThisSound.Volume = Volume; end

	ThisSound.PlaybackSpeed = RNG:NextNumber(PlaybackSpeedVariation.Min, PlaybackSpeedVariation.Max)

    if Delay then
        task.delay(Delay, function()
            ThisSound:Play()
        end)
    else
        ThisSound:Play()
    end
end

-- @GoalVolume = Desired volume
-- @TweenTime = How long should it take
-- @ReturnToOriginalVolumeAfter = How many seconds before the sound returns to its original volume
-- @ReturnTime = How many seconds should the return to original volume tween be
-- @StopSoundAtZero = Stop playing the sound when its volume reaches zero
function SoundController.TweenSoundVolume(ThisSound: Sound, GoalVolume: number, TweenTime: number, ReturnToOriginalVolumeAfter: number?, ReturnTime: number?, StopSoundAtZero: boolean?)
    if not ThisSound then return end
    
    local OriginalVolume = ThisSound.Volume

	-- Make sure the sound is playing first
    if GoalVolume > 0 and not ThisSound.IsPlaying then ThisSound:Play(); end

    local SoundTween = TweenService:Create(ThisSound, TweenInfo.new(TweenTime, Enum.EasingStyle.Linear), {Volume = GoalVolume})
    SoundTween.Completed:Connect(function()
        SoundTween = nil

        if ReturnToOriginalVolumeAfter then
			TweenService:Create(ThisSound, TweenInfo.new(ReturnTime or 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, ReturnToOriginalVolumeAfter), 
			{Volume = OriginalVolume}):Play() 
		end

        if StopSoundAtZero and GoalVolume <= 0 then ThisSound:Stop(); end
    end)

    SoundTween:Play()
end

function SoundController:Init()
	Sounds.Music.Theme.Looped = true
	Sounds.Music.Theme:Play()

	AssignSoundGroups()
end

return SoundController