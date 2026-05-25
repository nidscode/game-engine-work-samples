-- modules/highscore.lua
--
-- High-score persistence. Solar2D apps can only write into the
-- DocumentsDirectory (sandboxed on iOS/Android). We store the score as a
-- single integer in a tiny JSON file. JSON because:
--   * trivial to extend later (settings, unlocks, multiple modes)
--   * human-readable when debugging on device
--   * Solar2D ships `json` in its core, no plugin needed

local json = require("json")

local M = {}

local FILE_NAME = "highscore.json"
local DEFAULT   = { best = 0 }

local function path()
  return system.pathForFile(FILE_NAME, system.DocumentsDirectory)
end

--- Load the saved data. Returns the default table on first run or on
--- any read error — never returns nil so callers don't have to nil-check.
function M.load()
  local file, err = io.open(path(), "r")
  if not file then
    return { best = DEFAULT.best }
  end
  local raw = file:read("*a")
  file:close()
  local ok, data = pcall(json.decode, raw)
  if not ok or type(data) ~= "table" or type(data.best) ~= "number" then
    -- Corrupt file; fall back rather than crashing.
    return { best = DEFAULT.best }
  end
  return data
end

--- Persist a candidate score. Returns the new best and whether it changed.
function M.submit(score)
  local data = M.load()
  if score <= data.best then
    return data.best, false
  end
  data.best = score
  local file, err = io.open(path(), "w")
  if not file then
    -- Silently degrade — high score won't survive restart, but the run
    -- it just happened in still completes cleanly.
    return data.best, true
  end
  file:write(json.encode(data))
  file:close()
  return data.best, true
end

return M
