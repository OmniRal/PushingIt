-- OmniRal

local TrophyInfo = {} :: {
	{
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

return TrophyInfo