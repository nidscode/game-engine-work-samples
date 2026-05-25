-- config.lua
--
-- Content scaling. Solar2D rescales the "content area" (logical coordinate
-- space we draw into) to fit the device screen. We target a portrait phone
-- — 720x1280 logical pixels with "letterbox" so wider devices get bars
-- rather than warping.

application = {
  content = {
    width  = 720,
    height = 1280,
    scale  = "letterbox",
    fps    = 60,
    imageSuffix = {
      ["@2x"] = 1.5,
      ["@4x"] = 3.0,
    },
  },
}
