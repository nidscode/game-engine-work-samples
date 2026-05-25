-- classes/player.lua
--
-- The player craft. A horizontally-moving display object that drifts
-- toward a target X each frame. Touch input on the play scene updates
-- target_x; the player handles the smoothing here so input scenes don't
-- need to know about easing curves.
--
-- We expose a tiny OO surface: Player.new(parent_group) returns an
-- instance, and the instance owns its own display object lifetime.

local M = {}
M.__index = M

local PLAYER_WIDTH   = 64
local PLAYER_HEIGHT  = 80
local MAX_SPEED      = 1100        -- pixels per second
local SMOOTH_K       = 16          -- larger = snappier
local START_Y_RATIO  = 0.78        -- fraction of screen height

local function build_shape(parent_group)
  -- Triangular spaceship using a Polygon for a sharper silhouette than a
  -- box. Polygon points are relative to the polygon's center.
  local poly = display.newPolygon(parent_group, 0, 0, {
    0, -PLAYER_HEIGHT * 0.5,
   -PLAYER_WIDTH * 0.5, PLAYER_HEIGHT * 0.5,
    0, PLAYER_HEIGHT * 0.25,
    PLAYER_WIDTH * 0.5, PLAYER_HEIGHT * 0.5,
  })
  poly:setFillColor(0.35, 0.95, 0.85)
  poly.strokeWidth = 2
  poly:setStrokeColor(1, 1, 1, 0.4)
  return poly
end

--- Create a new player in the given display group.
function M.new(parent_group)
  local self = setmetatable({}, M)
  self.body = build_shape(parent_group)
  self.body.x = display.contentCenterX
  self.body.y = display.contentHeight * START_Y_RATIO
  self.target_x = self.body.x
  self.alive = true
  return self
end

function M:set_target_x(x)
  -- Clamp inside the play area with a margin so the player can't slip
  -- under the wall colliders we draw at the edges.
  local margin = PLAYER_WIDTH * 0.6
  if x < margin then x = margin end
  if x > display.contentWidth - margin then x = display.contentWidth - margin end
  self.target_x = x
end

function M:update(dt)
  if not self.alive then return end
  -- Frame-rate-independent smoothing toward the touch target.
  local k = 1 - math.exp(-SMOOTH_K * dt)
  self.body.x = self.body.x + (self.target_x - self.body.x) * k
  -- A subtle bank — the ship leans into its motion.
  local lean = (self.target_x - self.body.x) * 0.6
  self.body.rotation = math.max(-25, math.min(25, lean))
end

--- AABB used by the game scene for cheap overlap checks.
function M:bounds()
  return self.body.x - PLAYER_WIDTH * 0.45,
         self.body.y - PLAYER_HEIGHT * 0.45,
         self.body.x + PLAYER_WIDTH * 0.45,
         self.body.y + PLAYER_HEIGHT * 0.45
end

function M:kill()
  self.alive = false
  -- A quick scale-up + fade out. transition.to is Solar2D's tween engine.
  transition.to(self.body, {
    time = 280, alpha = 0, xScale = 1.6, yScale = 1.6, rotation = 0,
  })
end

function M:destroy()
  if self.body and self.body.removeSelf then self.body:removeSelf() end
  self.body = nil
end

return M
