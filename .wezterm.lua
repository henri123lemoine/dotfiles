local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Config preferences
-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28
-- or, changing the font size and color scheme.
config.font_size = 10
config.color_scheme = "AdventureTime"
-- End of config

return config
