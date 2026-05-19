-- OmniRal

export type NPCRariry = "Common" | "Rare"

local SkinTones = {
    
}

local NPCInfo: {
    [string]: {
        [string]: {
            Name: string,
            FaceID: number,

            SkinColor: Color3,

            HeadColor: Color3?,
            TorsoColor: Color3?,
            LeftArmColor: Color3?,
            RightArmColor: Color3?,
            LeftLegColor: Color3?,
            RightLegColor: Color3?,

            Hat: number?,
            Hair: number?,
            Shirt: number?,
            Pants: number?,
        }
    }
} = {}

NPCInfo["Common"] = {
    ["John"] = {
        Name = "John",
        FaceID = 7074786,
        SkinColor = Color3.fromRGB(255, 214, 101),
        Hat = 101487993528040,
        Hair = 133599348957886,
        Shirt = 109896445568652,
        Pants = 91543195374013,
    }
}

return NPCInfo