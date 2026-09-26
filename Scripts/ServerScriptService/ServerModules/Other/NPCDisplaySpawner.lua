local NPCDisplaySpawner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

function NPCDisplaySpawner.SpawnAllInRow()
	local Plate = Workspace.NPCDisplayPlate
	
	-- Clean up any existing NPCs
	for _, OldNPC in Plate:GetChildren() do
		if not OldNPC:IsA("Model") then continue end
		OldNPC:Destroy()
	end
	
	-- Add new ones
	local NPCInfo_Module = ReplicatedStorage.Source.SharedModules.Info:FindFirstChild("NPCInfo") :: ModuleScript
	if not NPCInfo_Module then return end
	
	local NPCInfo = require(NPCInfo_Module)

	local Offset = 0
	
	for Rarity, List in NPCInfo do
		for Name, Info in List do
			local NewNPC = ReplicatedStorage.Assets.Other.BaseNPC_R6:Clone()
			NewNPC.Name = Name .. "_" .. Rarity
			
			local Description = Instance.new("HumanoidDescription")
			
			Description.HeadColor = Info.HeadColor or Info.SkinColor
			Description.TorsoColor = Info.TorsoColor or Info.SkinColor
			Description.LeftArmColor = Info.LeftArmColor or Info.SkinColor
			Description.RightArmColor = Info.RightArmColor or Info.SkinColor
			Description.LeftLegColor = Info.LeftLegColor or Info.SkinColor
			Description.RightLegColor = Info.RightLegColor or Info.SkinColor
			
			Description.Face = Info.FaceID
			
			Description.HatAccessory = Info.Hat or 0
			Description.HairAccessory = Info.Hair or 0
			Description.FaceAccessory = Info.Face or 0
			Description.NeckAccessory = Info.Neck or 0
			Description.ShouldersAccessory = Info.Shoulder or 0
			Description.FrontAccessory = Info.Front or 0
			Description.BackAccessory = Info.Back or 0
			Description.WaistAccessory = Info.Waist or 0
			
			Description.Shirt = Info.Shirt or 0
			Description.Pants = Info.Pants or 0
			
			Description.Parent = NewNPC
			NewNPC:AddTag("DisplayNPC")
			NewNPC.Parent = Plate
			
			local Success, Error = pcall(function() 
				NewNPC.Humanoid:ApplyDescriptionAsync(Description)
			end)
			
			if not Success then
				warn(Error)
				return
			end
			
			NewNPC:PivotTo(Plate.CFrame * CFrame.new(Offset, 2.5, 0))
			Offset -= 4
		end
	end
end

return NPCDisplaySpawner