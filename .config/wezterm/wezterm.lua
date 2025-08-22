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
config.disable_default_key_bindings = true

-- Performance optimizations
config.max_fps = 120
config.enable_wayland = false

-- Better scrollback
config.scrollback_lines = 10000

-- Backgrounds you want to cycle through
local BACKGROUNDS = {
	"", -- None
	os.getenv("HOME") .. "/.config/wezterm/backgrounds/img1.png",
	os.getenv("HOME") .. "/.config/wezterm/backgrounds/img2.png",
	os.getenv("HOME") .. "/.config/wezterm/backgrounds/img3.png",
}

-- Helper to build a background layer table
local function bg_layer(path)
	if path == "" then
		return nil
	end
	return {
		{
			source = { File = path },
			-- Keep aspect ratio; fill window; crop overflow
			width = "Cover",
			height = "Cover",
			horizontal_align = "Center",
			vertical_align = "Middle",
			-- HSB tweaks for dimming
			hsb = { brightness = 0.05, hue = 1.0, saturation = 1.0 },
			opacity = 1.0,
		},
	}
end

-- Initialize with no background
config.background = nil

local function current_bg(window)
	local o = window:get_config_overrides()
	if
		o
		and o.background
		and o.background[1]
		and o.background[1].source
		and type(o.background[1].source) == "table"
		and o.background[1].source.File
	then
		return o.background[1].source.File
	end
	if
		config.background
		and config.background[1]
		and config.background[1].source
		and config.background[1].source.File
	then
		return config.background[1].source.File
	end
	return ""
end

wezterm.on("cycle-bg", function(window, _)
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
	overrides.background = bg_layer(next_path) -- nil clears background
	window:set_config_overrides(overrides)
end)

-- Key bindings
config.keys = {
	{ key = "Enter", mods = "CMD", action = wezterm.action.ToggleFullScreen },
	{ key = "=", mods = "CMD", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CMD", action = wezterm.action.DecreaseFontSize },
	{ key = "v", mods = "CMD", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "c", mods = "CMD", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "m", mods = "CMD|CTRL", action = wezterm.action.EmitEvent("cycle-bg") },
	{ key = "r", mods = "CMD|CTRL", action = wezterm.action.ReloadConfiguration },
}

return config
