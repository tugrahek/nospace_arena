extends GutTest

## UI Pass B1 regression coverage for the shared MainMenu navigation arena.

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const HUB_PATH: NodePath = NodePath("Center/Buttons/NavigationHub")
const NAVIGATION: Array[Dictionary] = [
	{"name": "StoreButton", "key": "MENU_STORE", "en": "Store", "tr": "Mağaza"},
	{"name": "MissionsButton", "key": "MENU_MISSIONS_SHORT", "en": "Missions", "tr": "Görevler"},
	{"name": "LeaderboardButton", "key": "MENU_LEADERBOARD", "en": "Leaderboard", "tr": "Liderlik"},
	{"name": "CreditsButton", "key": "MENU_CREDITS", "en": "Credits", "tr": "Künye"},
]
const DESTINATION_SCENES: Array[Dictionary] = [
	{"constant": "STORE_SCENE", "path": "res://scenes/ui/Store.tscn"},
	{"constant": "MISSIONS_SCENE", "path": "res://scenes/ui/Missions.tscn"},
	{"constant": "LEADERBOARD_SCENE", "path": "res://scenes/ui/Leaderboard.tscn"},
	{"constant": "CREDITS_SCENE", "path": "res://scenes/ui/Credits.tscn"},
]


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_navigation_hub_keeps_four_flat_destination_targets() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	var hub: Control = menu.get_node(HUB_PATH)
	assert_true(hub.custom_minimum_size.x >= 560.0, "hub retains a wide shared arena surface")
	assert_true(hub.custom_minimum_size.y >= 190.0, "hub retains a compact two-row layout")
	for entry in NAVIGATION:
		var button: Button = hub.get_node(entry["name"])
		assert_true(button.flat, "%s stays a transparent hub hit target" % entry["name"])
		assert_true(button.custom_minimum_size.x >= 260.0, "%s keeps a comfortable touch width" % entry["name"])
		assert_true(button.custom_minimum_size.y >= 88.0, "%s keeps a comfortable touch height" % entry["name"])
		assert_not_null(button.get_node_or_null("Icon"), "%s retains its procedural icon" % entry["name"])
		assert_not_null(button.get_node_or_null("Label"), "%s retains its localized label" % entry["name"])
	menu.free()


func test_navigation_handlers_and_localization_keys_remain_available() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	assert_true(menu.has_method("_on_store"), "Store keeps its destination handler")
	assert_true(menu.has_method("_on_missions"), "Missions keeps its destination handler")
	assert_true(menu.has_method("_on_credits"), "Credits keeps its destination handler")
	TranslationServer.set_locale("tr")
	for entry in NAVIGATION:
		assert_eq(tr(entry["key"]), entry["tr"], "TR label for %s" % entry["name"])
	TranslationServer.set_locale("en")
	for entry in NAVIGATION:
		assert_eq(tr(entry["key"]), entry["en"], "EN label for %s" % entry["name"])
	menu.free()


func test_destination_targets_and_scenes_remain_available() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	var targets: Dictionary = menu.get_script().get_script_constant_map()
	for entry in DESTINATION_SCENES:
		assert_eq(targets[entry["constant"]], entry["path"], "%s target is unchanged" % entry["constant"])
		var destination: PackedScene = load(entry["path"])
		assert_not_null(destination, "%s loads" % entry["path"])
		var screen: Control = destination.instantiate()
		assert_not_null(screen, "%s instantiates" % entry["path"])
		screen.free()
	menu.free()


func test_currency_pill_keeps_a_procedural_coin_and_localized_label() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	var coin_icon: Control = menu.get_node("CoinsPanel/Content/CoinIcon")
	var coins: Label = menu.get_node("CoinsPanel/Content/Coins")
	assert_not_null(coin_icon.get_script(), "currency pill owns a procedural coin drawing")
	assert_eq(coin_icon.mouse_filter, Control.MOUSE_FILTER_IGNORE, "coin never intercepts input")
	assert_not_null(coins, "currency label remains in the existing pill")
	TranslationServer.set_locale("tr")
	assert_eq(tr("HUD_CURRENCY"), "Para", "TR currency label remains localized")
	TranslationServer.set_locale("en")
	assert_eq(tr("HUD_CURRENCY"), "Coins", "EN currency label remains localized")
	menu.free()
