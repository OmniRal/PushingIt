-- OmniRal

local TrophyInfo = {} :: {
	[string]: {
		DisplayName: string, 
		Icon: number, -- Icon for the badge
		BadgeID: number, -- Roblox badge ID
		Description: string, -- The description for this trophy (same as the badge description)

		ScoreNeeded: number?, -- If the player needs a specific amount of a certain score to make progress
		TimesToComplete: number, -- How many times an action needs to be done to get this trophy
		RewardType: "None" | "Coins", 
		RewardAmount: any, -- How many coins or other stuff should the player receive
		DisplayProgress: boolean,
	}
}

TrophyInfo.PushNPCs_5 = {
	DisplayName = "Pushed 5",
	Icon = 101686338045377,
	BadgeID = 192131054738749,
	Description = "Push 5 unique NPCs.",

	TimesToComplete = 5,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.PushNPCs_10 = {
	DisplayName = "Pushed 10",
	Icon = 139407920834248,
	BadgeID = 1383040244964199,
	Description = "Push 10 unique NPCs.",

	TimesToComplete = 10,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.PushNPCs_25 = {
	DisplayName = "Pushed 25",
	Icon = 90556246340756,
	BadgeID = 3187290148495443,
	Description = "Push 25 unique NPCs.",
	
	TimesToComplete = 25,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Score_500 = {
	DisplayName = "500 Points",
	Icon = 122405473491963,
	BadgeID = 3183326057186525,
	Description = "Score 500 points in a single chain.",

	ScoreNeeded = 500,
	TimesToComplete = 1,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Score_1000 = {
	DisplayName = "Score 1000",
	Icon = 117698505005166,
	BadgeID = 758579611649057,
	Description = "Score 1000 points in a single chain.",

	ScoreNeeded = 1000,
	TimesToComplete = 1,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Score_10000 = {
	DisplayName = "Score 10000",
	Icon = 112765955517951,
	BadgeID = 323840876923723230,
	Description = "Score 10,000 points in a single chain.",

	ScoreNeeded = 10000,
	TimesToComplete = 1,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Timer_90 = {
	DisplayName = "Timer 90",
	Icon = 110348304714729,
	BadgeID = 3986721867804333,
	Description = "Don't get pushed by another player for 90 seconds.",

	ScoreNeeded = 9,
	TimesToComplete = 1,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Timer_300 = {
	DisplayName = "Timer 300",
	Icon = 88063537595368,
	BadgeID = 3027689214204257,
	Description = "Don't get pushed by another player for 300 (5 minutes) seconds.",

	ScoreNeeded = 30,
	TimesToComplete = 1,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

TrophyInfo.Timer_600 = {
	DisplayName = "Timer 600",
	Icon = 87271872398846,
	BadgeID = 3154599178816483,
	Description = "Don't get pushed by another player for 600 (10 minutes) seconds.",

	ScoreNeeded = 60,
	TimesToComplete = 1,
	RewardType = "None",
	RewardAmount = 0,
	DisplayProgress = false,
}

return TrophyInfo