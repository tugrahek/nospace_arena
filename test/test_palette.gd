extends GutTest

## Palette readability: neon accents + text must stand out against the void background.
## color_contrast reused from ThemeData (Step 08). Loads palette.tres at runtime.

const ThemeData = preload("res://scripts/meta/theme_data.gd")
const MIN_CONTRAST: float = 0.25


func test_palette_loads() -> void:
	assert_not_null(load("res://config/palette.tres"))


func test_accents_readable_on_void() -> void:
	var p = load("res://config/palette.tres")
	assert_gt(ThemeData.color_contrast(p.accent, p.void_bg), MIN_CONTRAST, "cyan accent")
	assert_gt(ThemeData.color_contrast(p.accent_alt, p.void_bg), MIN_CONTRAST, "magenta accent")
	assert_gt(ThemeData.color_contrast(p.text_primary, p.void_bg), MIN_CONTRAST, "text")
	assert_gt(ThemeData.color_contrast(p.coin, p.void_bg), MIN_CONTRAST, "coin")
