local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Title bar
config.window_decorations = "RESIZE"

-- Font and appearance
-- config.font = wezterm.font("JetBrains Mono Nerd Font")
config.font_size = 12
-- config.color_scheme = "Ayu Dark (Gogh)"
config.color_scheme = "Material Darker (base16)"
-- NOTE: These color-scheme changes will only apply on closing-reopening of the window. Cmd-r is insufficient.

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

-- Performance optimizations
config.max_fps = 120
config.enable_wayland = false

-- Better scrollback
config.scrollback_lines = 10000

-- Backgrounds you want to cycle through
local BACKGROUNDS = {
	"", -- None
	"os.getenv("HOME") .. "/.config/wezterm/backgrounds/img1.png"",
	"os.getenv("HOME") .. "/.config/wezterm/backgrounds/img2.png"",
	"os.getenv("HOME") .. "/.config/wezterm/backgrounds/img3.png"",
}

local function current_bg(window)
	-- Prefer live overrides; fall back to the base/effective config
	local o = window:get_config_overrides()
	if o and o.window_background_image ~= nil then
		return o.window_background_image or ""
	end
	return window:effective_config().window_background_image or ""
end

wezterm.on("cycle-bg", function(window, pane)
	local cur = current_bg(window)
	local idx = 1
	for i, path in ipairs(BACKGROUNDS) do
		if path == cur then
			idx = i
			break
		end
	end
	local next_idx = (idx % #BACKGROUNDS) + 1
	local next_path = BACKGROUNDS[next_idx]
	local overrides = window:get_config_overrides() or {}
	overrides.window_background_image = (next_path ~= "" and next_path) or nil
	window:set_config_overrides(overrides)
	local label = (next_path == "" and "None") or (next_path:match("([^/]+)$") or next_path)
	window:toast_notification("WezTerm", "Background: tuheirh" .. label, nil, 2000)
end)

config.window_background_image = "os.getenv("HOME") .. "/.config/wezterm/backgrounds/img3.png""
config.window_background_image_hsb = {
	brightness = 0.05,
	hue = 1.,
	saturation = 1.,
}
config.window_background_opacity = 1.0

-- Key bindings
config.keys = {
	{ key = "Enter", mods = "CMD", action = wezterm.action.ToggleFullScreen },
	{ key = "=", mods = "CMD", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CMD", action = wezterm.action.DecreaseFontSize },
	{ key = "n", mods = "CMD|CTRL", action = wezterm.action.EmitEvent("cycle-bg") },
}

return config
