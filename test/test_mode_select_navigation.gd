extends GutTest

## UI Pass B2 coverage: redesigned hit targets retain their mode wiring and boost presentation.

const MODE_SELECT_SCENE: PackedScene = preload("res://scenes/ui/ModeSelect.tscn")
const GRID_PATH: NodePath = NodePath("Center/ModeGrid")
const MODES: Array[Dictionary] = [
	{"row": "DailyRow", "key": "MENU_DAILY", "en": "Daily", "tr": "Günlük"},
	{"row": "FreeRow", "key": "MENU_FREE", "en": "Free", "tr": "Serbest"},
	{"row": "LevelRow", "key": "MENU_LEVEL", "en": "Endless", "tr": "Sonsuz"},
	{"row": "CampaignRow", "key": "MENU_CAMPAIGN", "en": "Campaign", "tr": "Macera"},
]


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_mode_grid_keeps_four_flat_usable_targets() -> void:
	var screen: Control = MODE_SELECT_SCENE.instantiate()
	var grid: Control = screen.get_node(GRID_PATH)
	assert_true(grid.custom_minimum_size.x >= 560.0, "grid keeps a wide shared surface")
	assert_true(grid.custom_minimum_size.y >= 340.0, "grid keeps two comfortable rows")
	for entry in MODES:
		var row: Control = grid.get_node(entry["row"])
		var button: Button = row.get_node("Button")
		var art: Control = row.get_node("Art")
		assert_true(button.flat, "%s stays a transparent hit target" % entry["row"])
		assert_not_null(art.get_script(), "%s keeps procedural presentation art" % entry["row"])
		assert_eq(art.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s art never intercepts input" % entry["row"])
		assert_not_null(button.get_node_or_null("ModeLabel"), "%s keeps its title" % entry["row"])
		assert_not_null(button.get_node_or_null("Desc"), "%s keeps its description" % entry["row"])
	screen.free()


func test_mode_destinations_and_localized_names_are_preserved() -> void:
	var screen: Control = MODE_SELECT_SCENE.instantiate()
	var targets: Dictionary = screen.get_script().get_script_constant_map()
	assert_eq(targets["GAME_SCENE"], "res://scenes/main/Game.tscn")
	assert_eq(targets["MENU_SCENE"], "res://scenes/main/MainMenu.tscn")
	assert_eq(targets["LEVEL_SELECT_SCENE"], "res://scenes/ui/LevelSelect.tscn")
	assert_true(screen.has_method("_start"), "Daily, Free, and Endless retain their start handler")
	TranslationServer.set_locale("tr")
	for entry in MODES:
		assert_eq(tr(entry["key"]), entry["tr"], "TR label for %s" % entry["row"])
	TranslationServer.set_locale("en")
	for entry in MODES:
		assert_eq(tr(entry["key"]), entry["en"], "EN label for %s" % entry["row"])
	screen.free()


func test_boost_strip_supports_hidden_and_owned_presentations() -> void:
	var screen: Control = MODE_SELECT_SCENE.instantiate()
	add_child_autofree(screen)
	var none: Array[BoostData] = []
	screen._build_boost_strip_for(none)
	var strip: VBoxContainer = screen.get_node("Center/BoostStrip")
	assert_false(strip.visible, "no owned boosts leaves no placeholder strip")
	var owned: Array[BoostData] = [ContentCatalog.boost_by_id(&"extra_life")]
	screen._build_boost_strip_for(owned)
	assert_true(strip.visible, "owned boost restores the arm strip")
	assert_eq(strip.get_child_count(), 3, "header, note, and one arm row render")
	var row: Control = strip.get_child(2)
	var toggle: Button = row.get_child(2)
	assert_true(toggle.toggle_mode, "owned boost retains its arm toggle")
