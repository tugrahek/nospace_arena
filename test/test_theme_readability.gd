extends GutTest

# theme_data.gd is dependency-free (Resource + colors), safe to preload.
const ThemeData = preload("res://scripts/meta/theme_data.gd")

const MIN_CONTRAST: float = 0.25  # enemy/trail/glow must read against the void

const THEMES := [
	"res://resources/themes/theme_void.tres",
	"res://resources/themes/theme_ember.tres",
	"res://resources/themes/theme_frost.tres",
]
const CHARACTERS := [
	"res://resources/characters/char_pulse.tres",
	"res://resources/characters/char_drag.tres",
	"res://resources/characters/char_halt.tres",
]


func test_color_contrast_basic() -> void:
	assert_almost_eq(ThemeData.color_contrast(Color.BLACK, Color.WHITE), 1.0, 0.0001)
	assert_eq(ThemeData.color_contrast(Color.RED, Color.RED), 0.0)


func test_theme_elements_readable_on_void() -> void:
	for path in THEMES:
		var t = load(path)
		assert_gt(ThemeData.color_contrast(t.enemy_color, t.void_color), MIN_CONTRAST, "%s enemy" % path)
		assert_gt(ThemeData.color_contrast(t.trail_color, t.void_color), MIN_CONTRAST, "%s trail" % path)
		assert_gt(ThemeData.color_contrast(t.border_color, t.void_color), MIN_CONTRAST, "%s border" % path)


func test_character_glow_readable_on_every_theme() -> void:
	for cpath in CHARACTERS:
		var ch = load(cpath)
		for tpath in THEMES:
			var t = load(tpath)
			assert_gt(
				ThemeData.color_contrast(ch.accent_color, t.void_color),
				MIN_CONTRAST,
				"%s glow on %s" % [cpath, tpath]
			)
