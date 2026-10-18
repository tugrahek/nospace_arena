extends GutTest

const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const STORE_SCENE: PackedScene = preload("res://scenes/ui/Store.tscn")

var _original_economy: Variant


func before_each() -> void:
	_original_economy = Economy._data
	var profile := SaveData.new_default()
	profile.currency = 2468
	Economy._data = profile
	TranslationServer.set_locale("en")


func after_each() -> void:
	Economy._data = _original_economy
	TranslationServer.set_locale("en")


func test_hud_menu_and_store_numeric_labels_use_locale_templates() -> void:
	var hud: HUD = HUD_SCENE.instantiate()
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	var store: Control = STORE_SCENE.instantiate()
	add_child_autofree(hud)
	add_child_autofree(menu)
	add_child_autofree(store)
	await get_tree().process_frame
	hud.setup(3)
	hud.set_daily(true, 20261010)
	hud.set_best(987654)
	hud.call("_on_score_changed", 123456, 3)
	var score: Label = hud.get_node("TopSafeArea/InfoStack/TopBar/ScoreLabel")
	var combo: Label = hud.get_node("TopSafeArea/InfoStack/ActivityRow/ComboLabel")
	var daily: Label = hud.get_node("TopSafeArea/InfoStack/MetaRow/DailyLabel")
	var best: Label = hud.get_node("TopSafeArea/InfoStack/MetaRow/BestLabel")
	var hud_currency: Label = hud.get_node("CoinSafeArea/Bounds/CurrencyLabel")
	var menu_currency: Label = menu.get_node("SafeArea/Bounds/Frame/Header/CoinsPanel/Content/Coins")
	var store_currency: Label = store.get_node("SafeArea/Bounds/Frame/Header/Coins")
	for locale: String in LocaleUtil.SUPPORTED:
		TranslationServer.set_locale(locale)
		store.call("_refresh")
		await get_tree().process_frame
		assert_eq(score.text, tr("HUD_SCORE_VALUE") % 123456)
		assert_eq(combo.text, tr("HUD_COMBO_VALUE") % 4)
		assert_eq(daily.text, tr("HUD_DAILY_VALUE") % DailySeed.date_string(20261010))
		assert_eq(best.text, tr("HUD_BEST_VALUE") % 987654)
		assert_eq(hud_currency.text, tr("HUD_CURRENCY_VALUE") % 2468)
		assert_eq(menu_currency.text, tr("HUD_CURRENCY_VALUE") % 2468)
		assert_eq(store_currency.text, tr("HUD_CURRENCY_VALUE") % 2468)
