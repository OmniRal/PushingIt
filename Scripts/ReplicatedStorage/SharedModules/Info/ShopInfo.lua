-- OmniRal

type CategoryType = "GlobalEvents" | "Coins"

local ShopInfo: {
	[string]: { -- Item name
		Category: CategoryType,
		DisplayName: string,
		DevProductID: number,
		RobuxCost: number,
		Icon: number,
		Description: string?,
		OtherDetails: {}?,
	}
} = {}

ShopInfo["RainBananaPeels"] = {
	Category = "GlobalEvents",
	DevProductID = 3710662134,
	DisplayName = "Rain Banana Peels!",
	RobuxCost = 50,
	Icon = 108754125315510,
}

return ShopInfo