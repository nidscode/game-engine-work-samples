-- classes/obstacle.lua
--
-- Obstacle (debris) flying upward past the player. Obstacles are pooled —
-- this module exposes:
--   * Obstacle.factory(parent_group)  — builds a fresh display object
--                                       suitable for the pool's factory arg
--   * Obstacle.spawn(obj, opts)       — re-initialize a pooled instance for
--                                       a new appearance on screen
--   * Obstacle.update(obj, dt)        — per-frame movement; returns true
--                                       when the obstacle has scrolled off
--                                       the top and should be released
--
-- Keeping the API as free functions over a plain display object (rather
-- than a table-with-display-child) means the pool can use the display
-- object directly as the pooled value with no wrapper overhead.

local M = {}

local OBSTACLE_SIZE = 92

--- Build a fresh obstacle display object. Used as the pool factory.
function M.factory(parent_group)
  local rect = display.newRect(parent_group, 0, 0, OBSTACLE_SIZE, OBSTACLE_SIZE)
  rect:setFillColor(0.95, 0.4, 0.5)
  rect.strokeWidth = 2
  rect:setStrokeColor(1, 1, 1, 0.35)
  -- Store size on the object so spawn/update don't need to reach for constants.
  rect.half_w = OBSTACLE_SIZE * 0.5
  rect.half_h = OBSTACLE_SIZE * 0.5
  rect.vy = 0
  rect.spin = 0
  return rect
end

--- Configure for a new appearance. `opts.speed` and `opts.x` are required.
function M.spawn(obj, opts)
  obj.x = opts.x
  obj.y = -obj.half_h - 4               -- just off the top edge
  obj.vy = opts.speed                   -- downward velocity (px/sec)
  obj.spin = (math.random() < 0.5 and -1 or 1) * (60 + math.random() * 180)
  obj.rotation = math.random() * 360
  obj.xScale, obj.yScale = 1, 1
  obj.alpha = 1
end

--- Returns true when the obstacle has scrolled past the bottom and is
--- ready to be released back to the pool.
function M.update(obj, dt)
  obj.y = obj.y + obj.vy * dt
  obj.rotation = obj.rotation + obj.spin * dt
  return obj.y > display.contentHeight + obj.half_h + 16
end

--- AABB used for the cheap-overlap collision check.
function M.bounds(obj)
  return obj.x - obj.half_w, obj.y - obj.half_h,
         obj.x + obj.half_w, obj.y + obj.half_h
end

return M
