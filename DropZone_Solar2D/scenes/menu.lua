-- scenes/menu.lua
--
-- Main menu. Shows title, current best score, and a Play button. We use
-- the composer scene lifecycle (create → show → hide → destroy) rather
-- than ad-hoc setup/teardown so cleanup happens automatically when we
-- navigate away.

local composer  = require("composer")
local highscore = require("modules.highscore")

local scene = composer.newScene()

local function go_play()
  composer.gotoScene("scenes.game", {
    effect = "fade",
    time   = 240,
  })
end

function scene:create(event)
  local view = self.view

  -- Background.
  local bg = display.newRect(view, display.contentCenterX, display.contentCenterY,
                             display.contentWidth, display.contentHeight)
  bg:setFillColor(0.04, 0.05, 0.10)

  -- Title.
  local title = display.newText({
    parent = view,
    text   = "DROP\nZONE",
    x = display.contentCenterX,
    y = display.contentCenterY - 220,
    font = native.systemFontBold,
    fontSize = 110,
    align = "center",
  })
  title:setFillColor(0.95, 0.95, 1.0)

  -- Best score (loaded once at scene create; refreshed each show).
  self.best_label = display.newText({
    parent = view, text = "",
    x = display.contentCenterX, y = display.contentCenterY,
    font = native.systemFont, fontSize = 38,
  })
  self.best_label:setFillColor(1, 1, 1, 0.85)

  -- Play "button" — just a tappable rounded rect + label.
  local btn = display.newRoundedRect(view, display.contentCenterX,
                                     display.contentCenterY + 240,
                                     360, 120, 28)
  btn:setFillColor(0.35, 0.95, 0.85)
  btn.strokeWidth = 2
  btn:setStrokeColor(1, 1, 1, 0.5)
  local btn_label = display.newText({
    parent = view, text = "TAP TO PLAY",
    x = btn.x, y = btn.y, font = native.systemFontBold, fontSize = 44,
  })
  btn_label:setFillColor(0.04, 0.05, 0.10)

  -- A 'touch' listener on the button itself. Returning true claims the
  -- event so it doesn't bubble. Trigger on "ended" so a press-and-drag-off
  -- doesn't launch the scene.
  local function on_touch(event)
    if event.phase == "ended" then go_play() end
    return true
  end
  btn:addEventListener("touch", on_touch)
  btn_label:addEventListener("touch", on_touch)

  -- Subtle pulse on the button — a designer-tweakable feel detail.
  transition.to(btn, {
    time = 700, xScale = 1.04, yScale = 1.04,
    transition = easing.inOutSine,
    iterations = 0, reflect = true,
  })
end

function scene:show(event)
  if event.phase ~= "did" then return end
  local data = highscore.load()
  self.best_label.text = "BEST  " .. tostring(data.best or 0)
end

function scene:hide(event) end

function scene:destroy(event) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
