-- OmniRal

local ServerGlobalValues = {}

ServerGlobalValues["AdminList"] = {
    {Name = "OmniRal", ID = 267421},
    {Name = "Blotnik", ID = 266280},
    {Name = "bennult", ID = 424583710},
}

ServerGlobalValues["PlayerTestList"] = {
    {Name = "Player1", ID = -1},
    {Name = "Player2", ID = -2},
}

local List_1 = {ServerGlobalValues.AdminList[1]}
local List_2 = {ServerGlobalValues.AdminList[1], ServerGlobalValues.AdminList[2]}
local List_3 = ServerGlobalValues.AdminList
local List_4 = ServerGlobalValues.PlayerTestList

--------------------------------------------------------------------------------------------

ServerGlobalValues["CleanupAssetDump"] = true

ServerGlobalValues["NPCs_StandStill"] = true -- If TRUE, NPCs won't move around anywhere
ServerGlobalValues["NPCs_TestMode"] = true -- When true, NPCs will reposition themselves to their original position after a push
-- (If this is TRUE, StandStill will automatically be true, too)

--------------------------------------------------------------------------------------------

return ServerGlobalValues