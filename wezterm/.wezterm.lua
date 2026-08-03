local wezterm = require("wezterm")
local config = wezterm.config_builder()

config = {
	color_scheme = "Abernathy",
	font = wezterm.font("CommitMono Nerd Font Mono", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	font_size = 14,
	window_background_opacity = 1,
	animation_fps = 1,
	max_fps = 240,
	hide_tab_bar_if_only_one_tab = true,
	tab_bar_at_bottom = true,
}

return config
