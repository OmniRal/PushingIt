-- OmniRal

local BounceUmbrella = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CLEAN_TIME = 0.05
local COOLDOWN = 0.5

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function BounceUmbrella.Setup(Umbrella: BasePart)
	local Power = Umbrella:GetAttribute("Power") :: NumberRange
    local Debounce = false
    
    Umbrella:SetAttribute("Launched", false)

    Umbrella.Touched:Connect(function(Hit: BasePart)
        if Debounce then return end
        if not Hit then return end
        if not Hit.Parent then return end
        local Human, Root = Hit.Parent:FindFirstChild("Humanoid") :: Humanoid, Hit.Parent:FindFirstChild("HumanoidRootPart") :: BasePart
        if not Human or not Root then return end
        if Human.Health <= 0 then return end
		local RelativePos = Umbrella.CFrame:PointToObjectSpace(Root.Position)
		if RelativePos.Y < 0.5 then return end

        local RootAttachment = Root:FindFirstChild("RootAttachment")
        if not RootAttachment then return end

        Debounce = true
        Umbrella:SetAttribute("Launched", true)

        local LaunchPower = RNG:NextInteger(Power.Min, Power.Max)

		if Root:FindFirstChild("UmbrellaVelocity") then Root.UmbrellaVelocity:Destroy() end

        local UmbrellaVelocity = Instance.new("LinearVelocity")
        UmbrellaVelocity.Name = "UmbrellaVelocity"
        UmbrellaVelocity.MaxForce = 1000000
        UmbrellaVelocity.Attachment0 = RootAttachment
        UmbrellaVelocity.VectorVelocity = Umbrella.CFrame.UpVector * LaunchPower
        UmbrellaVelocity.Parent = Root

        Debris:AddItem(UmbrellaVelocity, CLEAN_TIME)

        task.delay(COOLDOWN, function()
            Umbrella:SetAttribute("Launched", false)
            Debounce = false
        end)
    end)
end

return BounceUmbrella