extends GutTest

const DYNA_PUFF: FontFile = preload("res://assets/fonts/dynapuff/dynapuff-variable.ttf")
const RUBIK: FontFile = preload("res://assets/fonts/rubik/rubik-variable.ttf")
const NUNITO_SANS: FontFile = preload("res://assets/fonts/nunitosans/nunitosans-variable.ttf")
const UI_THEME: Theme = preload("res://theme/ui_theme.tres")
const WORDMARK_GLYPHS: String = "NoSpaceABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,:!?%+()-'"
const UI_GLYPHS: String = "ÇĞİÖŞÜçğıiöşüABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,:!?%+()-'"
const TARGET_SCENES: Array[String] = [
	"res://scenes/main/MainMenu.tscn",
	"res://scenes/ui/Missions.tscn",
	"res://scenes/ui/Store.tscn",
]


func test_production_fonts_have_required_glyphs() -> void:
	_assert_glyphs(DYNA_PUFF, WORDMARK_GLYPHS, "DynaPuff wordmark")
	_assert_glyphs(RUBIK, UI_GLYPHS, "Rubik headings")
	_assert_glyphs(NUNITO_SANS, UI_GLYPHS, "Nunito Sans UI")


func test_production_font_roles_are_bound_directly() -> void:
	var title_font: Font = UI_THEME.get_font(&"font", &"Title")
	var heading_font: Font = UI_THEME.get_font(&"font", &"Heading")
	var display_font: Font = UI_THEME.get_font(&"font", &"Display")
	assert_true(title_font is FontVariation, "Title uses the Rubik medium variation")
	assert_true(heading_font is FontVariation, "Heading uses the Rubik medium variation")
	assert_eq((title_font as FontVariation).base_font, RUBIK)
	assert_eq((heading_font as FontVariation).base_font, RUBIK)
	assert_eq(display_font, RUBIK, "Display preserves the Rubik ARENA treatment")
	var main_menu: Control = load(TARGET_SCENES[0]).instantiate()
	var wordmark: Label = main_menu.get_node("Center/Title")
	var wordmark_font: Font = wordmark.get_theme_font(&"font")
	assert_true(wordmark_font is FontVariation, "NoSpace owns a dedicated brand variation")
	assert_eq((wordmark_font as FontVariation).base_font, DYNA_PUFF)
	main_menu.free()


func test_production_typography_scenes_load() -> void:
	for scene_path in TARGET_SCENES:
		var scene: PackedScene = load(scene_path)
		assert_not_null(scene, scene_path)
		var screen: Control = scene.instantiate()
		assert_not_null(screen, scene_path)
		screen.free()


func _assert_glyphs(font: FontFile, glyphs: String, label: String) -> void:
	for glyph in glyphs:
		assert_true(font.has_char(glyph.unicode_at(0)), "%s must include %s" % [label, glyph])
