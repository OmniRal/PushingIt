-- OmniRal

local ShopService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

--local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)
local ShopInfo = require(ReplicatedStorage.Source.SharedModules.Info.ShopInfo)

local EventService = require(ServerScriptService.Source.ServerModules.General.EventService)

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


local function ProcessReceipt(Info)
	if not Info then return end

	local ThisPlayer = Players:GetPlayerByUserId(Info.PlayerId)
	if not ThisPlayer then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Check which category the item is
	for Name, Data in ShopInfo do
		if not Name or not Data then continue end
		if Data.Category == "GlobalEvents" then
			EventService.RunEvent(Name)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function ShopService:Init()
	MarketplaceService.ProcessReceipt = ProcessReceipt

    Remotes.Server:CreateToServer("RequestBuyCoins", {"number"}, "Returns", function(Player: Player, Option: number)
        MarketplaceService:PromptProductPurchase(Player, ShopInfo.BuyCoins[Option].DevProductID)
    end)

	Remotes.Server:CreateToServer("RequestBuyGlobalEvent", {"string"}, "Returns", function(Player: Player, ItemName: string)
		if not ShopInfo[ItemName] then return false end
		MarketplaceService:PromptProductPurchase(Player, ShopInfo[ItemName].DevProductID)

		return true
	end)
end

function ShopService:Deferred()

end

return ShopService