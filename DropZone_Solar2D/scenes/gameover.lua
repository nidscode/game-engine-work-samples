-- scenes/gameover.lua
--
-- Game-over screen. Receives the final score via composer.params, submits
-- it to the high score store, and lets the player tap to retry or back
-- out to the menu.

local composer  = require("composer")
local highscore = require("modules.highscore")

local scene = composer.newScene()

local function go_menu()
  composer.gotoScene("scenes.menu", { effect = "fade", time = 200 })
end

local function go_retry()
  composer.gotoScene("scenes.game", { effect = "fade", time = 200 })
end

function scene:create(event)
  local view = self.view

  local bg = display.newRect(view, display.contentCenterX, display.contentCenterY,
                             display.contentWidth, display.contentHeight)
  bg:setFillColor(0.04, 0.05, 0.10)

  -- Built once; text content is set in show() using params.
  self.title = display.newText({
    parent = view, text = "GAME OVER",
    x = display.contentCenterX, y = display.contentCenterY - 240,
    font = native.systemFontBold, fontSize = 88,
  })
  self.score_label = display.newText({
    parent = view, text = "",
    x = display.contentCenterX, y = display.contentCenterY - 100,
    font = native.systemFont, fontSize = 56,
  })
  self.best_label = display.newText({
    parent = view, text = "",
    x = display.contentCenterX, y = display.contentCenterY - 30,
    font = native.systemFont, fontSize = 40,
  })

  local function make_button(text, y, on_tap, fill_r, fill_g, fill_b)
    local btn = display.newRoundedRect(view, display.contentCenterX, y, 360, 110, 24)
    btn:setFillColor(fill_r, fill_g, fill_b)
    local label = display.newText({
      parent = view, text = text, x = btn.x, y = btn.y,
      font = native.systemFontBold, fontSize = 42,
    })
    label:setFillColor(0.04, 0.05, 0.10)
    local function on_touch(ev)
      if ev.phase == "ended" then on_tap() end
      return true
    end
    btn:addEventListener("touch", on_touch)
    label:addEventListener("touch", on_touch)
  end

  make_button("RETRY", display.contentCenterY + 160, go_retry, 0.35, 0.95, 0.85)
  make_button("MENU",  display.contentCenterY + 310, go_menu,  0.85, 0.85, 0.95)
end

function scene:show(event)
  if event.phase ~= "did" then return end
  local score = (event.params and event.params.score) or 0

  -- Persist score and pull back the new "best" (may be unchanged).
  local best, is_new = highscore.submit(score)

  self.score_label.text = "SCORE  " .. tostring(score)
  if is_new then
    self.best_label.text = "NEW BEST!"
    self.best_label:setFillColor(0.95, 0.75, 0.35)
    -- Quick pulse on a new high score.
    transition.from(self.best_label, { time = 320, xScale = 1.4, yScale = 1.4, alpha = 0 })
  else
    self.best_label.text = "BEST   " .. tostring(best)
    self.best_label:setFillColor(1, 1, 1, 0.7)
  end
end

function scene:hide(event) end
function scene:destroy(event) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
