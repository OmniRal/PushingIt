-- OmniRal

export type NPCRariry = "Common" | "Rare" | "Epic" | "Legendary" | "Mythical"
export type NPCMovement = "Roam" | "Stationary"

local SkinTones = {
    
}

local NPCInfo: {
    [string]: {
        [string]: {
            FirstName: string,
            LastName: string,
            FlavorText: string,
            Rarity: NPCRariry, -- Common, Rare, Epic, Legendary, Mythical

            VoiceLines: {
                Normal: {
                    {Line: string, SoundID: number}
                },
                OnPushed: {
                    {Line: string, SoundID: number}
                },
                Ragdolling: {
                    {Line: string, SoundID: number}
                },
            },

            IdleAnimID: number,
            WalkAnimID: number,
            RunAnimID: number,
            
            SkinColor: Color3,
            
            HeadColor: Color3?,
            TorsoColor: Color3?,
            LeftArmColor: Color3?,
            RightArmColor: Color3?,
            LeftLegColor: Color3?,
            RightLegColor: Color3?,

            FaceID: number,
            
            Hat: string?,
            Hair: string?,
            Face: string?,
            Neck: string?,
            Shoulder: string?,
            Front: string?,
            Back: string?,
            Waist: string?,            

            Shirt: number?,
            Pants: number?,

            Movement: NPCMovement,
        }
    }
} = {}

NPCInfo["Common"] = {
    ["John"] = {
        FirstName = "John",
        LastName = "Dink",

        FlavorText = "Nothing",
        Rarity = "Common",

        VoiceLines = {
            Normal = {},
            OnPushed = {},
            Ragdolling = {},
        },

        IdleAnimID = 0,
        WalkAnimID = 0,
        RunAnimID = 0,
        
        SkinColor = Color3.fromRGB(255, 214, 101),

        FaceID = 7074786,
        
        Hat = "101487993528040",
        Hair = "133599348957886",
        Face = "76460337150367,82220168227309",
        Neck = "",
        Shoulder = "",
        Front = "",
        Back = "",
        Waist = "",

        Shirt = 109896445568652,
        Pants = 91543195374013,

        Movement = "Roam",
	},
	
	["Oog"] = {
		FirstName = "Oog",
		LastName = "Doogt",

		FlavorText = "A neanderthal",
		Rarity = "Common",

		VoiceLines = {
			Normal = {},
			OnPushed = {},
			Ragdolling = {},
		},

		IdleAnimID = 0,
		WalkAnimID = 0,
		RunAnimID = 0,

		SkinColor = Color3.fromRGB(198, 169, 141),

		FaceID = 144075659,

		Hat = "",
		Hair = "5829924026",
		Face = "127753091840810,132236343725708,17268256320",
		Neck = "",
		Shoulder = "",
		Front = "",
		Back = "",
		Waist = "",

		Shirt = 105780963067603,
		Pants = 82094953407006,

		Movement = "Roam",
	},
	["Felipe"] = {
		FirstName = "Felipe",
		LastName = "Santiago",

		FlavorText = "Drinks frappé' while he takes a crappé'",
		Rarity = "Common",

		VoiceLines = {
			Normal = {},
			OnPushed = {},
			Ragdolling = {},
		},

		IdleAnimID = 0,
		WalkAnimID = 0,
		RunAnimID = 0,

		SkinColor = Color3.fromRGB(255, 232, 187),

		FaceID = 7074864,

		Hat = "12894437793",
		Hair = "",
		Face = "76460337150367",
		Neck = "",
		Shoulder = "",
		Front = "",
		Back = "",
		Waist = "",

		Shirt = 135589353230600,
		Pants = 87716520120018,

		Movement = "Roam",
	},
}

NPCInfo["Rare"] = {

}

NPCInfo["Epic"] = {
    
}

NPCInfo["Legendary"] = {
    
}

NPCInfo["Mythical"] = {
    
}

return NPCInfo