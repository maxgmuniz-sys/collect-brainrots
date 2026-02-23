-- init.client.luau
-- Client bootstrap: load all UI controllers

local MoneyUI = require(script.Controllers.MoneyUI)
local FoodStoreUI = require(script.Controllers.FoodStoreUI)
local BaseUI = require(script.Controllers.BaseUI)
local SellUI = require(script.Controllers.SellUI)

MoneyUI.Init()
FoodStoreUI.Init()
BaseUI.Init()
SellUI.Init()

print("[Client] All controllers initialized.")
