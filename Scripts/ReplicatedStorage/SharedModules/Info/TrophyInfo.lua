-- OmniRal

local TrophyInfo = {} :: {
	[string]: {
		Name: string, 
		Icon: number, 
		BadgeID: number, -- Roblox badge ID
		Description: string, 

		TimesToComplete: number, -- How many times an action needs to be done to get this trophy
		RewardType: "None" | "Coins", 
		RewardAmount: any, -- How many coins or other stuff should the player receive
		DisplayProgress: boolean
	}
}

TrophyInfo.TestTrophy = {
	Name = "Test Trophy",
    Icon = 15669481502,
    BadgeID = 2208951626055704,
    Description = "Just a test trophy",
    TimesToComplete = 3,
    RewardType = "Coins",
    RewardAmount = 1000,
    DisplayProgress = true,
}

TrophyInfo.Push5NPCs = {
	Name = "Push 5 Unique NPCs",
	Icon = 0,
	BadgeID = 0,
	TimesToComplete = 5,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Push10NPCs = {
	Name = "Push 10 Unique NPCs",
	Icon = 0,
	BadgeID = 0,
	TimesToComplete = 10,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Push25NPCs = {
	Name = "Push 25 Unique NPCs",
	Icon = 0,
	BadgeID = 0,
	TimesToComplete = 25,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

return TrophyInfo