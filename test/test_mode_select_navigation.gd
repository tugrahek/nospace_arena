extends GutTest

## UI Pass B2 coverage: redesigned hit targets retain their mode wiring and boost presentation.

const MODE_SELECT_SCENE: PackedScene = preload("res://scenes/ui/ModeSelect.tscn")
const GRID_PATH: NodePath = NodePath("SafeArea/Bounds/Center/ModeGrid")
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
		var art: Control = row.get_node("Button/Content/Art")
		assert_true(button.flat, "%s stays a transparent hit target" % entry["row"])
		assert_not_null(art.get_script(), "%s keeps procedural presentation art" % entry["row"])
		assert_eq(art.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s art never intercepts input" % entry["row"])
		assert_not_null(button.get_node_or_null("Content/ModeLabel"), "%s keeps its title" % entry["row"])
		assert_not_null(button.get_node_or_null("Content/Desc"), "%s keeps its description" % entry["row"])
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
	screen._build_boost_strip()
	var none: Array[BoostData] = []
	screen._build_boost_strip_for(none)
	var strip: VBoxContainer = screen.get_node("SafeArea/Bounds/Center/BoostStrip")
	assert_false(strip.visible, "no owned boosts leaves no placeholder strip")
	var owned: Array[BoostData] = [ContentCatalog.boost_by_id(&"extra_life")]
	screen._build_boost_strip_for(owned)
	assert_true(strip.visible, "owned boost restores the arm strip")
	assert_eq(strip.get_child_count(), 1, "only the chip rail renders")
	var row: Control = strip.get_node("Boosts").get_child(0)
	var toggle: Button = row
	assert_true(toggle.toggle_mode, "owned boost retains its arm toggle")
	assert_eq(toggle.disabled, Economy.boost_count(&"extra_life") <= 0)
	assert_eq(toggle.text, "", "no Arm button text")
	assert_gte(toggle.custom_minimum_size.y, 108.0)


func test_compact_arm_control_preserves_charges_and_daily_policy() -> void:
	var original: Variant = Economy._data
	var path: String = Economy._save_path
	var fixture_path: String = "user://23f3_boost_strip_fixture.json"
	Economy._data = SaveData.new_default()
	Economy._save_path = fixture_path
	for boost: BoostData in ContentCatalog.BOOSTS:
		Economy._data.add_boost(boost.id, 2)
	var screen: Control = MODE_SELECT_SCENE.instantiate()
	add_child_autofree(screen)
	screen._build_boost_strip()
	var rail: HBoxContainer = screen.get_node("SafeArea/Bounds/Center/BoostStrip/Boosts")
	assert_eq(rail.get_child_count(), 3)
	var toggle: Button = rail.get_child(0)
	var id: StringName = ContentCatalog.BOOSTS[0].id
	toggle.button_pressed = true
	assert_true(Economy.is_boost_armed(id))
	assert_eq(Economy.boost_count(id), 2)
	assert_true(SaveStore.load_from(fixture_path).is_boost_armed(id))
	var selected: BoostLoadoutChip = screen.get_node("SafeArea/Bounds/Center/BoostStrip/Boosts").get_child(0)
	assert_true(selected._marker.visible)
	assert_eq(selected.get_theme_stylebox("normal").border_color, BoostLoadoutChip.PALETTE.accent)
	selected.button_pressed = false
	assert_false(Economy.is_boost_armed(id))
	assert_false((screen.get_node("SafeArea/Bounds/Center/BoostStrip/Boosts").get_child(0) as BoostLoadoutChip)._marker.visible)
	assert_false(BoostPolicy.boosts_allowed(SeedManager.Mode.DAILY))
	screen.free()
	Economy._data = original
	Economy._save_path = path
	_remove_fixture(fixture_path)


func _remove_fixture(fixture_path: String) -> void:
	for suffix: String in ["", SaveStore.TEMP_SUFFIX, SaveStore.BACKUP_SUFFIX]:
		if FileAccess.file_exists(fixture_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path + suffix))


func test_zero_inventory_chip_is_disabled_without_arm_intent() -> void:
	var chip := BoostLoadoutChip.new()
	chip.configure(ContentCatalog.boost_by_id(&"extra_life"), 0, true)
	add_child_autofree(chip)
	watch_signals(chip)
	assert_true(chip.disabled)
	assert_false(chip._marker.visible)
	assert_lt(chip.modulate.a, 1.0)
	chip.button_pressed = true
	assert_false(chip.button_pressed)
	assert_signal_not_emitted(chip, "armed_changed")


func test_coin_bonus_chip_uses_distinct_plus_accent_icon() -> void:
	var chip := BoostLoadoutChip.new()
	chip.configure(ContentCatalog.boost_by_id(&"coin_bonus"), 1, false)
	var icon: Control = chip.get_child(0).get_child(0)
	assert_eq(icon.get("effect"), 3)
	assert_ne(icon.get("effect"), BoostData.Effect.COIN_BONUS)
	chip.free()


func test_loadout_is_visible_after_every_previously_played_mode() -> void:
	var old_mode: int = SeedManager.mode
	for mode: int in [SeedManager.Mode.DAILY, SeedManager.Mode.FREE, SeedManager.Mode.LEVEL_ENDLESS, SeedManager.Mode.CAMPAIGN]:
		SeedManager.mode = mode
		var screen: Control = MODE_SELECT_SCENE.instantiate()
		add_child_autofree(screen)
		assert_true(screen.get_node("SafeArea/Bounds/Center/BoostStrip").visible)
		assert_eq(screen.get_node("SafeArea/Bounds/Center/BoostStrip/Boosts").get_child_count(), 3)
		screen.free()
	SeedManager.mode = old_mode
