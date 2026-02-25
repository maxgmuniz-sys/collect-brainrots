-- init.client.luau
-- Client bootstrap: load all UI controllers

local MoneyUI = require(script.Controllers.MoneyUI)
local FoodStoreUI = require(script.Controllers.FoodStoreUI)
local BaseUI = require(script.Controllers.BaseUI)
local SellUI = require(script.Controllers.SellUI)
local WeatherUI = require(script.Controllers.WeatherUI)
local IndexUI = require(script.Controllers.IndexUI)
local LeaderboardUI = require(script.Controllers.LeaderboardUI)
local FusionUI = require(script.Controllers.FusionUI)

MoneyUI.Init()
FoodStoreUI.Init()
BaseUI.Init()
SellUI.Init()
WeatherUI.Init()
IndexUI.Init()
LeaderboardUI.Init()
FusionUI.Init()

-- Phase 9: Tutorial (must be last so all UIs exist for highlighting)
local TutorialUI = require(script.Controllers.TutorialUI)
TutorialUI.Init()

print("[Client] All controllers initialized.")
