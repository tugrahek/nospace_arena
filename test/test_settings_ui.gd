extends GutTest

## Settings UI wiring: panel instantiates, reflects current settings, and slider changes
## apply to AudioManager. (Actual audibility is verified by Tuğra once assets land.)

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/Settings.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const PALETTE: PaletteData = preload("res://config/palette.tres")

var _saved_settings: Dictionary


func before_each() -> void:
	_saved_settings = AudioManager.settings().to_dict()


func after_each() -> void:
	var saved: AudioSettings = AudioSettings.from_dict(_saved_settings)
	AudioManager.apply_master(saved.master)
	AudioManager.apply_sfx(saved.sfx)
	AudioManager.apply_music(saved.music)
	AudioManager.set_muted(saved.muted)
	AudioManager.set_control_scheme(saved.control_scheme)
	AudioManager.set_language(saved.language)
	AudioManager.commit_settings()
	TranslationServer.set_locale("en")

func test_shipped_languages_select_persist_and_refresh_settings() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	panel.call("_open_language_selector")
	var selector: SettingsLanguageSelector = panel.get("_language_overlay")
	assert_eq(selector.options.size(), LocaleUtil.SUPPORTED.size() + 1)
	for index in range(3, selector.options.size()):
		var button: Button = selector.get("_buttons")[index]
		button.pressed.emit()
		var code: String = selector.options[index]["code"]
		assert_eq(AudioManager.settings().language, code)
		assert_eq(TranslationServer.get_locale(), code)
		assert_eq(SettingsStore.load_from(AudioManager.SETTINGS_PATH).language, code)
		assert_eq(panel.get_node("SafeArea/Bounds/Center/Title").text, tr("SETTINGS_TITLE"))
		assert_eq(panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton").text,
			tr(selector.options[index]["key"]))
		await get_tree().process_frame
		assert_eq(panel.is_layout_rtl(), code == "ar", "UI follows active locale direction")
		var language_button: Button = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton")
		assert_gte(language_button.size.x, language_button.get_combined_minimum_size().x, "endonym fits")
		selector.scroll.ensure_control_visible(button)
		await get_tree().process_frame
		assert_true(selector.scroll.get_global_rect().intersects(button.get_global_rect()), "last choices are reachable")


func test_panel_instantiates_and_reflects_settings() -> void:
	var panel: Node = load("res://scenes/ui/Settings.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	var master: HSlider = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/MasterRow/Slider")
	assert_almost_eq(master.value, AudioManager.settings().master, 0.0001)
	for entry in [
		{"name": "MasterRow", "value": AudioManager.settings().master},
		{"name": "SfxRow", "value": AudioManager.settings().sfx},
		{"name": "MusicRow", "value": AudioManager.settings().music},
	]:
		var label: Label = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/%s/Header/ValueLabel" % entry["name"])
		assert_eq(label.text, "%d%%" % roundi(float(entry["value"]) * 100.0))


func test_main_menu_and_standalone_back_keep_settings_route() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	assert_eq(menu.get_script().get_script_constant_map()["SETTINGS_SCENE"], "res://scenes/ui/Settings.tscn")
	assert_not_null(menu.get_node("SafeArea/Bounds/Frame/Header/SettingsButton"))
	menu.free()
	var panel: Control = SETTINGS_SCENE.instantiate()
	assert_eq(panel.get_script().get_script_constant_map()["MENU_SCENE"], "res://scenes/main/MainMenu.tscn")
	assert_false(panel.embedded)
	assert_not_null(panel.get_node("SafeArea/Bounds/Bottom/BackButton"))
	panel.free()


func test_slider_change_applies_to_audiomanager() -> void:
	var panel: Node = load("res://scenes/ui/Settings.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	var sfx: HSlider = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/SfxRow/Slider")
	sfx.value = 0.25
	await get_tree().process_frame
	assert_almost_eq(AudioManager.settings().sfx, 0.25, 0.0001)
	# restore so other tests/sessions aren't affected by this in-memory change
	sfx.value = 1.0


func test_settings_locale_keys() -> void:
	assert_eq(tr("SETTINGS_TITLE"), "Settings")
	assert_eq(tr("SETTINGS_AUDIO"), "Audio")
	assert_eq(tr("SETTINGS_MUTE"), "Mute")
	assert_eq(tr("SETTINGS_STATE_OFF"), "Off")
	assert_eq(tr("SETTINGS_LANGUAGE"), "Language")


func test_legal_footer_is_separate_bottom_safe_region() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(720, 1280)
	add_child_autofree(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	var footer: Control = panel.get_node("SafeArea/Bounds/Bottom/LegalFooter")
	assert_false(panel.has_node("SafeArea/Bounds/Center/LegalFooter"))
	assert_eq(panel.get_node("SafeArea/Bounds/Bottom").anchor_bottom, 1.0)
	assert_eq(panel.get_node("SafeArea/Bounds/Bottom").offset_bottom, -24.0)
	assert_almost_eq(footer.get_global_rect().position.y - panel.get_node("SafeArea/Bounds/Bottom/BackButton").get_global_rect().end.y, 40.0, 0.5)
	assert_not_null(footer.get_node("Copyright"))
	assert_not_null(footer.get_node("LicensesButton"))


func test_privacy_choices_follow_ump_availability_busy_state_and_locale() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	var button: Button = panel.get_node("SafeArea/Bounds/Bottom/LegalFooter/PrivacyButton")
	assert_false(button.visible, "desktop/no UMP requirement has no misleading action")
	assert_eq(button.text, "Privacy choices")
	AdsService.privacy_options_changed.emit(true, true)
	assert_true(button.visible)
	assert_true(button.disabled)
	AdsService.privacy_options_changed.emit(true, false)
	assert_false(button.disabled)
	await get_tree().process_frame
	assert_lte(button.get_global_rect().end.y, 1280.0)
	assert_gte(button.size.x, button.get_combined_minimum_size().x)
	panel.call("_on_language", "tr")
	assert_eq(button.text, "Gizlilik tercihleri")
	await get_tree().process_frame
	assert_lte(button.get_global_rect().end.y, 1280.0)
	assert_gte(button.size.x, button.get_combined_minimum_size().x)
	AdsService.privacy_options_changed.emit(false, false)
	assert_false(button.visible)


func test_language_pick_applies_locale_and_refreshes_panel() -> void:
	# Godot's translation notification updates both live roots; Back/scene entry is not required.
	var saved: String = AudioManager.settings().language
	var original_data: Variant = Economy._data
	var fixture := SaveData.new_default()
	fixture.tutorial_seen = true
	fixture.last_claim_epoch_day = SeedManager.today_epoch()
	Economy._data = fixture
	AudioManager.set_language("en")
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var panel: Node = load("res://scenes/ui/Settings.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton").pressed.emit()
	var selector: SettingsLanguageSelector = panel.get("_language_overlay")
	var tr_button: Button = selector.get("_buttons")[2]
	tr_button.pressed.emit()
	assert_true(TranslationServer.get_locale().begins_with("tr"), "locale switched to tr")
	var title: Label = panel.get_node("SafeArea/Bounds/Center/Title")
	assert_eq(title.text, "Ayarlar", "panel re-labeled itself in the new language")
	assert_eq(menu.get_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/StoreButton/Content/Label").text, "Mağaza", "live Main Menu label translated")
	assert_eq(menu.get_node("SafeArea/Bounds/Frame/Header/CoinsPanel/Content/Coins").text, "Jeton: 0", "live Main Menu dynamic text translated")
	panel.call("_on_language", "en")
	assert_eq(title.text, "Settings", "Settings refreshes to English immediately")
	assert_eq(menu.get_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/StoreButton/Content/Label").text, "Store", "Main Menu refreshes to English immediately")
	Economy._data = original_data
	# Restore persisted preference + test locale.
	AudioManager.set_language(saved)
	TranslationServer.set_locale("en")


func test_all_audio_sliders_keep_range_and_persist_on_drag_end() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	for entry in [
		{"name": "MasterRow", "field": "master"},
		{"name": "SfxRow", "field": "sfx"},
		{"name": "MusicRow", "field": "music"},
	]:
		var slider: HSlider = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/%s/Slider" % entry["name"])
		assert_eq(slider.min_value, 0.0)
		assert_eq(slider.max_value, 1.0)
		assert_eq(slider.step, 0.01)
		slider.value = 0.37
		var value_label: Label = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/%s/Header/ValueLabel" % entry["name"])
		assert_eq(value_label.text, "37%", "visible value follows the real slider setting")
		slider.drag_ended.emit(true)
		assert_almost_eq(float(AudioManager.settings().get(entry["field"])), 0.37, 0.0001)
		var saved: AudioSettings = SettingsStore.load_from(AudioManager.SETTINGS_PATH)
		assert_almost_eq(float(saved.get(entry["field"])), 0.37, 0.0001)


func test_mute_state_and_all_control_choices_keep_saved_semantics() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	var mute: Button = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/MuteRow")
	var mute_state: Label = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/MuteRow/Content/StateLabel")
	var next_state: bool = not AudioManager.settings().muted
	mute.button_pressed = next_state
	assert_eq(AudioManager.settings().muted, next_state)
	assert_eq(SettingsStore.load_from(AudioManager.SETTINGS_PATH).muted, next_state)
	assert_eq(mute_state.text, tr("SETTINGS_STATE_ON") if next_state else tr("SETTINGS_STATE_OFF"))
	assert_true(mute_state.get_theme_stylebox("normal") is StyleBoxFlat)
	for entry in [
		{"name": "TapButton", "id": 0},
		{"name": "SwipeButton", "id": 1},
		{"name": "DpadButton", "id": 2},
	]:
		var button: Button = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/ControlsRow/Segment/%s" % entry["name"])
		button.button_pressed = true
		button.pressed.emit()
		assert_eq(AudioManager.settings().control_scheme, entry["id"])
		assert_eq(SettingsStore.load_from(AudioManager.SETTINGS_PATH).control_scheme, entry["id"])
		assert_eq(button.get_theme_color("font_pressed_color"), PALETTE.accent)


func test_language_choices_persist_and_refresh_both_locales() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	var title: Label = panel.get_node("SafeArea/Bounds/Center/Title")
	panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton").pressed.emit()
	var selector: SettingsLanguageSelector = panel.get("_language_overlay")
	assert_not_null(selector)
	for entry in [
		{"index": 2, "value": "tr", "title": "Ayarlar"},
		{"index": 1, "value": "en", "title": "Settings"},
		{"index": 0, "value": "", "title": ""},
	]:
		var button: Button = selector.get("_buttons")[entry["index"]]
		button.pressed.emit()
		assert_eq(AudioManager.settings().language, entry["value"])
		assert_eq(SettingsStore.load_from(AudioManager.SETTINGS_PATH).language, entry["value"])
		if entry["title"] != "":
			assert_eq(title.text, entry["title"])
	panel.call("_on_back")
	await get_tree().process_frame
	assert_null(panel.get("_language_overlay"))
	assert_true(is_instance_valid(panel), "language Back preserves Settings")


func test_sections_and_language_labels_fit_720_by_1280() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		panel.call("_apply_texts")
		await get_tree().process_frame
		for path in ["SafeArea/Bounds/Center/Title", "SafeArea/Bounds/Center/Scroll/Content/Rows", "SafeArea/Bounds/Center/Scroll/Content/ControlsRow", "SafeArea/Bounds/Center/Scroll/Content/LanguageRow", "SafeArea/Bounds/Bottom/BackButton"]:
			var section: Control = panel.get_node(path)
			assert_gte(section.get_global_rect().position.y, 0.0)
			assert_lte(section.get_global_rect().end.y, 1280.0)
		for row_name in ["MasterRow", "SfxRow", "MusicRow"]:
			var name_label: Label = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/%s/Header/NameLabel" % row_name)
			var value_label: Label = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/Rows/%s/Header/ValueLabel" % row_name)
			assert_lte(name_label.get_global_rect().end.x, value_label.get_global_rect().position.x)
			assert_gte(name_label.size.x, name_label.get_combined_minimum_size().x)
			assert_gte(value_label.size.x, value_label.get_combined_minimum_size().x)
		var segment: Control = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/ControlsRow/Segment")
		for child in segment.get_children():
			assert_true(segment.get_global_rect().encloses(child.get_global_rect()))
			assert_gte(child.size.x, child.get_combined_minimum_size().x)
		var language_button: Button = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton")
		assert_gte(language_button.size.x, language_button.get_combined_minimum_size().x)


func test_initial_language_row_is_visible_at_compact_and_standard_sizes() -> void:
	for viewport_size in [Vector2(360, 640), Vector2(393, 852)]:
		var panel: Control = SETTINGS_SCENE.instantiate()
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.size = viewport_size
		add_child_autofree(panel)
		await get_tree().process_frame
		await get_tree().process_frame
		var scroll: ScrollContainer = panel.get_node("SafeArea/Bounds/Center/Scroll")
		var language_row: Control = panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow")
		var label: Label = language_row.get_node("NameLabel")
		var language_button: Button = language_row.get_node("LanguageButton")
		var scroll_rect: Rect2 = scroll.get_global_rect()
		assert_gte(label.get_global_rect().position.y, scroll_rect.position.y, "language label starts in the initial viewport at %s" % viewport_size)
		assert_lte(language_button.get_global_rect().end.y, scroll_rect.end.y, "language selector is visible without scrolling at %s" % viewport_size)
		assert_gte(language_row.get_global_rect().position.x, scroll_rect.position.x)
		assert_lte(language_row.get_global_rect().end.x, scroll_rect.end.x, "language row has no horizontal overflow")
		assert_gte(language_button.size.y, 72.0, "language touch target remains unchanged")
		var back_button: Button = panel.get_node("SafeArea/Bounds/Bottom/BackButton")
		var footer: Control = panel.get_node("SafeArea/Bounds/Bottom/LegalFooter")
		assert_lte(back_button.get_global_rect().end.y, viewport_size.y - 24.0, "Back remains above the safe-area edge")
		assert_lte(footer.get_global_rect().end.y, viewport_size.y - 24.0, "legal footer remains visible above the safe-area edge")
		assert_gte(back_button.size.y, 56.0)
		panel.queue_free()
		await get_tree().process_frame


func test_language_selector_small_and_long_lists_keep_scroll_behavior() -> void:
	for count in [3, 10]:
		var selector := SettingsLanguageSelector.new()
		if count == 3:
			selector.options = selector.options.slice(0, count)
		if count == 10:
			selector.options.clear()
			for i in count:
				selector.options.append({"code": "mock%d" % i, "key": "LANG_EN"})
		add_child_autofree(selector)
		await get_tree().process_frame
		await get_tree().process_frame
		var buttons: Array = selector.get("_buttons")
		assert_eq(buttons.size(), count)
		for button in buttons:
			assert_gte(button.size.y, SettingsLanguageSelector.ROW_HEIGHT)
		selector.scroll.scroll_vertical = 10000
		await get_tree().process_frame
		if count == 10:
			assert_gt(selector.scroll.scroll_vertical, 0)
			assert_lte(buttons.back().get_global_rect().end.y, selector.scroll.get_global_rect().end.y + 1.0)
		else:
			assert_eq(selector.scroll.scroll_vertical, 0)
		selector.queue_free()
		await get_tree().process_frame


func test_language_selector_repeated_open_close_keeps_one_live_instance() -> void:
	var panel: Control = SETTINGS_SCENE.instantiate()
	add_child_autofree(panel)
	for i in 3:
		panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton").pressed.emit()
		var selector: SettingsLanguageSelector = panel.get("_language_overlay")
		panel.get_node("SafeArea/Bounds/Center/Scroll/Content/LanguageRow/LanguageButton").pressed.emit()
		assert_same(panel.get("_language_overlay"), selector)
		assert_eq(selector.language_selected.get_connections().size(), 1)
		panel.call("close")
		await get_tree().process_frame
		assert_null(panel.get("_language_overlay"))
		assert_true(is_instance_valid(panel))
