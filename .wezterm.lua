local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font and appearance
-- config.font = wezterm.font("JetBrains Mono Nerd Font")
config.font_size = 12
-- config.color_scheme = "Ayu Dark (Gogh)"
config.color_scheme = "Material Darker (base16)"

-- Window settings
config.initial_cols = 120
config.initial_rows = 28
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- Better tmux compatibility
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.disable_default_key_bindings = false

-- macOS polish
config.window_background_opacity = 0.97
config.macos_window_background_blur = 15

-- Performance optimizations
config.max_fps = 120
config.enable_wayland = false

-- Better scrollback
config.scrollback_lines = 10000

-- Key bindings
config.keys = {
	{ key = "Enter", mods = "CMD", action = wezterm.action.ToggleFullScreen },
	{ key = "=", mods = "CMD", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CMD", action = wezterm.action.DecreaseFontSize },
}

return config
