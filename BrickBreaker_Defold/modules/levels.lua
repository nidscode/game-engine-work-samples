-- modules/levels.lua
--
-- Level layouts as strings. A row of '.' is empty, digits are brick HP.
-- Designers can drop in a new layout without touching gameplay code.
--
-- Coordinate convention: layout[1] is the TOP row. The controller flips
-- this when spawning so brick world-y decreases for each subsequent row.

local M = {}

M.brick_size   = vmath.vector3(56, 22, 0)   -- pixel size of one brick incl. spacing
M.brick_gap    = vmath.vector3(4, 4, 0)
M.brick_origin = vmath.vector3(80, 600, 0)  -- top-left of brick grid (in world coords)

M.levels = {
  -- Level 1 — gentle intro
  {
    "..1111111111..",
    "..1222222221..",
    "..1233333321..",
    "..1234444321..",
  },
  -- Level 2 — denser and tougher in the middle
  {
    "11111111111111",
    "12222222222221",
    "12333333333321",
    "12344444444321",
    "12333333333321",
    "..2..2..2..2..",
  },
}

--- Convert a layout to a flat list of {x, y, hp} spawn descriptors.
function M.unpack(layout_index)
  local layout = M.levels[layout_index]
  if not layout then return nil end
  local spec = {}
  local stride_x = M.brick_size.x + M.brick_gap.x
  local stride_y = M.brick_size.y + M.brick_gap.y
  for row_idx, row in ipairs(layout) do
    for col_idx = 1, #row do
      local ch = row:sub(col_idx, col_idx)
      local hp = tonumber(ch)
      if hp and hp > 0 then
        spec[#spec + 1] = {
          x = M.brick_origin.x + (col_idx - 1) * stride_x,
          y = M.brick_origin.y - (row_idx - 1) * stride_y,
          hp = hp,
        }
      end
    end
  end
  return spec
end

function M.count(layout_index)
  local spec = M.unpack(layout_index)
  return spec and #spec or 0
end

return M
