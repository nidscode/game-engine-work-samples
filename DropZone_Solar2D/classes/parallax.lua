-- classes/parallax.lua
--
-- A two-layer parallax starfield. Far stars move slowly, near stars
-- faster — gives a parallax depth cue without any actual depth.
--
-- Each "star" is a small display.newCircle. We pre-allocate a fixed pool
-- of them at construction and recycle by snapping wrapped-around ones to
-- the top edge — no allocation during gameplay.

local M = {}
M.__index = M

local LAYERS = {
  { count = 70,  size_min = 1, size_max = 2, speed = 60,  alpha = 0.5 },
  { count = 40,  size_min = 1, size_max = 3, speed = 140, alpha = 0.85 },
}

local function build_layer(parent_group, spec)
  local group = display.newGroup()
  parent_group:insert(group)
  local stars = {}
  for i = 1, spec.count do
    local r = spec.size_min + math.random() * (spec.size_max - spec.size_min)
    local star = display.newCircle(group, 0, 0, r)
    star.x = math.random() * display.contentWidth
    star.y = math.random() * display.contentHeight
    star.alpha = spec.alpha * (0.6 + math.random() * 0.4)
    stars[i] = star
  end
  return { group = group, stars = stars, speed = spec.speed }
end

--- Build a parallax background. `parent_group` is where the two layer
--- groups will be inserted.
function M.new(parent_group)
  local self = setmetatable({}, M)
  self.layers = {}
  for _, spec in ipairs(LAYERS) do
    table.insert(self.layers, build_layer(parent_group, spec))
  end
  return self
end

function M:update(dt)
  local h = display.contentHeight
  for _, layer in ipairs(self.layers) do
    local dy = layer.speed * dt
    for i = 1, #layer.stars do
      local s = layer.stars[i]
      s.y = s.y + dy
      if s.y > h then
        s.y = s.y - h
        s.x = math.random() * display.contentWidth
      end
    end
  end
end

function M:destroy()
  for _, layer in ipairs(self.layers) do
    if layer.group and layer.group.removeSelf then
      layer.group:removeSelf()
    end
  end
  self.layers = nil
end

return M
