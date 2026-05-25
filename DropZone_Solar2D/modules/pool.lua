-- modules/pool.lua
--
-- Generic display-object pool. On a phone, allocating and freeing display
-- objects is the largest avoidable cost in a game with churn (bullets,
-- particles, obstacles). The pool hands out a recycled instance via
-- `acquire` and takes it back via `release`. Callers are responsible for
-- positioning/configuring the acquired object.
--
-- Usage:
--   local Pool = require("modules.pool")
--   local p = Pool.new(function() return display.newRect(0, 0, 32, 32) end, 16)
--   local obj = p:acquire()
--   ...
--   p:release(obj)
--
-- Pool is intentionally agnostic about display groups — the caller can
-- insert the acquired object wherever it wants. The pool only stashes
-- inactive ones in its own internal group so they're not rendered.

local M = {}
M.__index = M

--- Create a new pool. `factory` is a function that builds one instance
--- when the pool needs to grow. `initial_size` items are built up front.
function M.new(factory, initial_size)
  local self = setmetatable({
    factory  = factory,
    free     = {},
    stash    = display.newGroup(),
  }, M)
  self.stash.isVisible = false
  for i = 1, (initial_size or 0) do
    self:_grow()
  end
  return self
end

function M:_grow()
  local obj = self.factory()
  self.stash:insert(obj)
  obj.isVisible = false
  table.insert(self.free, obj)
end

--- Return an inactive instance. Growing the pool if necessary.
function M:acquire()
  if #self.free == 0 then
    self:_grow()
  end
  local obj = table.remove(self.free)
  obj.isVisible = true
  return obj
end

--- Hand an instance back. The caller must have already detached any
--- per-acquire transforms or listeners it added.
function M:release(obj)
  if not obj or obj.removeSelf == nil then return end
  obj.isVisible = false
  -- Reparent to the stash so it stops drawing on whatever group it was in.
  self.stash:insert(obj)
  table.insert(self.free, obj)
end

--- Free everything. Call on scene destroy to avoid leaking display objects.
function M:destroy()
  for i = #self.free, 1, -1 do
    local obj = self.free[i]
    if obj and obj.removeSelf then obj:removeSelf() end
    self.free[i] = nil
  end
  if self.stash and self.stash.removeSelf then
    self.stash:removeSelf()
  end
  self.stash = nil
end

return M
