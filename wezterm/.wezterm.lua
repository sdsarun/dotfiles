local wezterm = require("wezterm")
local config = wezterm.config_builder()

config = {
	color_scheme = "Argonaut (Gogh)",
	font = wezterm.font("Hack Nerd Font Mono", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	font_size = 14,
	window_background_opacity = 1,
	animation_fps = 1,
	max_fps = 120,
}

return config
