-- main.lua
--
-- Entry point. Solar2D auto-runs main.lua on launch. We do the small bit
-- of one-off global setup (hide status bar, set anchor defaults, seed RNG)
-- and then immediately hand control to the composer scene system.

display.setStatusBar(display.HiddenStatusBar)
display.setDefault("background", 0.04, 0.05, 0.10)
-- Drawing at the center of objects is almost always what we want; the
-- top-left default tends to surprise people coming from web/CSS.
display.setDefault("anchorX", 0.5)
display.setDefault("anchorY", 0.5)

math.randomseed(os.time())

local composer = require("composer")
composer.recycleOnSceneChange = true   -- free a scene's display objects on hide
composer.gotoScene("scenes.menu")
