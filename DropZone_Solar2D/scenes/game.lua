-- scenes/game.lua
--
-- Gameplay scene. Vertical scrolling: the world feels like it's moving
-- past the player, but in fact the player drifts left/right while
-- obstacles scroll down from the top of the screen.
--
-- Architecture:
--   * `parallax` runs the background star layers
--   * `pool` recycles obstacle display objects
--   * `player` is the controllable craft
--   * one `enterFrame` listener drives the whole simulation tick
--   * one screen-spanning touch listener feeds the player's target_x
--
-- Difficulty ramps over time by lowering the spawn interval and
-- increasing obstacle fall speed.

local composer  = require("composer")
local Pool      = require("modules.pool")
local Parallax  = require("classes.parallax")
local Player    = require("classes.player")
local Obstacle  = require("classes.obstacle")

local scene = composer.newScene()

-- ---------------------------------------------------------------------------
-- Tuning
-- ---------------------------------------------------------------------------
local START_FALL_SPEED   = 460     -- px/sec downward
local MAX_FALL_SPEED     = 900
local START_SPAWN_EVERY  = 0.85    -- seconds
local MIN_SPAWN_EVERY    = 0.32
local DIFFICULTY_RAMP    = 0.045   -- per second of survival
local POINTS_PER_SEC     = 10
local POINTS_PER_DODGE   = 25

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Cheap AABB overlap. With at most ~10 obstacles on screen, the O(n) loop
--- in the enterFrame is fine — we don't need spatial partitioning here.
local function overlaps(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
  return not (ax2 < bx1 or bx2 < ax1 or ay2 < by1 or by2 < ay1)
end

-- ---------------------------------------------------------------------------
-- Scene lifecycle
-- ---------------------------------------------------------------------------

function scene:create(event)
  local view = self.view

  -- Backdrop (so the cleared-color doesn't show if the device aspect is wider).
  local bg = display.newRect(view, display.contentCenterX, display.contentCenterY,
                             display.contentWidth, display.contentHeight)
  bg:setFillColor(0.04, 0.05, 0.10)

  self.bg_group       = display.newGroup(); view:insert(self.bg_group)
  self.obstacle_group = display.newGroup(); view:insert(self.obstacle_group)
  self.player_group   = display.newGroup(); view:insert(self.player_group)
  self.hud_group      = display.newGroup(); view:insert(self.hud_group)

  -- Parallax stars.
  self.parallax = Parallax.new(self.bg_group)

  -- Obstacle pool. The factory closes over our obstacle_group so newly
  -- built obstacles automatically land in the right layer.
  self.pool = Pool.new(function() return Obstacle.factory(self.obstacle_group) end, 8)
  self.active = {}     -- list of pool-owned obstacles currently on screen

  -- Player.
  self.player = Player.new(self.player_group)

  -- HUD: score top-left, multiplier top-right (room for expansion).
  self.score_label = display.newText({
    parent = self.hud_group, text = "0",
    x = display.contentCenterX, y = 60,
    font = native.systemFontBold, fontSize = 56,
  })
end

function scene:show(event)
  if event.phase ~= "did" then return end

  -- Reset per-run state.
  self.score        = 0
  self.elapsed      = 0
  self.spawn_timer  = 0
  self.dead         = false
  self.score_label.text = "0"

  -- Touch input — full screen. Drag-anywhere style: wherever your finger
  -- is, the player drifts toward that X. Smoother than zone-tapping for
  -- this kind of dodge game on mobile.
  self.touch_listener = function(event)
    if event.phase == "began" or event.phase == "moved" then
      self.player:set_target_x(event.x)
    end
    return true
  end
  Runtime:addEventListener("touch", self.touch_listener)

  -- Tick.
  self.frame_listener = function(event) self:_tick(event) end
  Runtime:addEventListener("enterFrame", self.frame_listener)
  self.last_t = system.getTimer()
end

function scene:hide(event)
  if event.phase == "will" then
    Runtime:removeEventListener("touch", self.touch_listener)
    Runtime:removeEventListener("enterFrame", self.frame_listener)
    self.touch_listener  = nil
    self.frame_listener  = nil
    -- Recycle all active obstacles so nothing leaks across scenes.
    for i = #self.active, 1, -1 do
      self.pool:release(self.active[i])
      self.active[i] = nil
    end
  end
end

function scene:destroy(event)
  if self.player    then self.player:destroy()   end
  if self.parallax  then self.parallax:destroy() end
  if self.pool      then self.pool:destroy()     end
end

-- ---------------------------------------------------------------------------
-- Per-frame
-- ---------------------------------------------------------------------------

function scene:_tick(event)
  local now = event.time / 1000          -- ms → s
  local dt  = math.min(1/30, now - (self.last_t / 1000))   -- clamp big frame gaps
  self.last_t = event.time

  if self.dead then return end

  self.elapsed = self.elapsed + dt

  -- Update background and player.
  self.parallax:update(dt)
  self.player:update(dt)

  -- Difficulty curve: speed ramps linearly with elapsed time, capped.
  local speed = math.min(MAX_FALL_SPEED,
                         START_FALL_SPEED + self.elapsed * 14)
  local spawn_every = math.max(MIN_SPAWN_EVERY,
                               START_SPAWN_EVERY - self.elapsed * DIFFICULTY_RAMP)

  -- Spawn timer.
  self.spawn_timer = self.spawn_timer + dt
  if self.spawn_timer >= spawn_every then
    self.spawn_timer = self.spawn_timer - spawn_every
    local x = 80 + math.random() * (display.contentWidth - 160)
    local obj = self.pool:acquire()
    self.obstacle_group:insert(obj)     -- ensure correct draw layer
    Obstacle.spawn(obj, { x = x, speed = speed })
    table.insert(self.active, obj)
  end

  -- Tick obstacles; release any that scrolled off.
  local px1, py1, px2, py2 = self.player:bounds()
  for i = #self.active, 1, -1 do
    local o = self.active[i]
    local off_screen = Obstacle.update(o, dt)
    if off_screen then
      self.pool:release(o)
      table.remove(self.active, i)
      self.score = self.score + POINTS_PER_DODGE
    else
      -- Collision check.
      local ox1, oy1, ox2, oy2 = Obstacle.bounds(o)
      if overlaps(px1, py1, px2, py2, ox1, oy1, ox2, oy2) then
        self:_die()
        break
      end
    end
  end

  -- Survival score.
  self.score = self.score + POINTS_PER_SEC * dt
  self.score_label.text = tostring(math.floor(self.score))
end

function scene:_die()
  self.dead = true
  self.player:kill()
  -- Stop ticking input so the player can't keep moving the dying ship.
  if self.touch_listener then
    Runtime:removeEventListener("touch", self.touch_listener)
    self.touch_listener = nil
  end
  -- Brief delay so the death animation lands before the scene swap.
  timer.performWithDelay(450, function()
    composer.gotoScene("scenes.gameover", {
      effect = "fade", time = 240,
      params = { score = math.floor(self.score) },
    })
  end)
end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
