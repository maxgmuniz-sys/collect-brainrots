-- init.client.luau
-- Client bootstrap: load all UI controllers

local MoneyUI = require(script.Controllers.MoneyUI)
local FoodStoreUI = require(script.Controllers.FoodStoreUI)
local BaseUI = require(script.Controllers.BaseUI)

MoneyUI.Init()
FoodStoreUI.Init()
BaseUI.Init()

print("[Client] All Phase 1 controllers initialized.")
