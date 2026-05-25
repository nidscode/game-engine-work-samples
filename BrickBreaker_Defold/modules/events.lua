-- modules/events.lua
--
-- Centralized message hashes. Defold encourages msg.post(receiver, name) calls;
-- pre-hashing the names here gives us:
--   * one place to audit the messaging contract between modules
--   * cheap (cached) hash lookups instead of hashing per send
--   * IDE autocompletion via the module table
--
-- Pattern: anything posted with msg.post or matched in on_message should
-- live in this file. Strings used inline in only one place are still hashed
-- on the spot — this module is for cross-module events.

local M = {}

-- Gameplay
M.brick_hit       = hash("brick_hit")        -- ball -> brick   (no payload)
M.brick_destroyed = hash("brick_destroyed")  -- brick -> controller {points}
M.ball_lost       = hash("ball_lost")        -- ball -> controller
M.life_lost       = hash("life_lost")        -- controller -> hud {lives}
M.score_changed   = hash("score_changed")    -- controller -> hud {score}
M.level_cleared   = hash("level_cleared")    -- controller -> hud
M.game_over       = hash("game_over")        -- controller -> hud
M.reset_request   = hash("reset_request")    -- hud / input -> controller

-- Ball lifecycle
M.attach_to_paddle = hash("attach_to_paddle") -- controller -> ball {paddle_id}
M.launch_ball      = hash("launch_ball")      -- controller -> ball {direction}

-- Built-in Defold messages we react to (not posted) — listed here for clarity.
M.contact_point_response = hash("contact_point_response")
M.collision_response     = hash("collision_response")

return M
