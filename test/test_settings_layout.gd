extends GutTest

## All Settings pages must fit without any scrollable ancestor, including UMP access.
const SETTINGS: PackedScene = preload("res://scenes/ui/Settings.tscn")
const VIEW_ROOT: String = "SafeArea/Bounds/Center/Views/"
var _saved_language: String


func before_each() -> void:
	_saved_language = AudioManager.settings().language


func after_each() -> void:
	AdsService.privacy_options_changed.emit(false, false)
	AudioManager.set_language(_saved_language)
	TranslationServer.set_locale("en")


func test_all_locales_main_and_subviews_fit_small_safe_viewports() -> void:
	for viewport_size in [Vector2i(360, 640), Vector2i(393, 852)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		add_child_autofree(viewport)
		var panel: Control = SETTINGS.instantiate()
		viewport.add_child(panel)
		# Authored 16 px padding plus simulated 24 px native top/bottom insets.
		panel.get_node("SafeArea").content_padding = Vector4i(16, 40, 16, 40)
		AdsService.privacy_options_changed.emit(true, false)
		assert_eq(panel.find_children("*", "ScrollContainer", true, false).size(), 0,
			"Settings pages contain no ScrollContainer; only the separate language picker may scroll")
		for locale: String in LocaleUtil.SUPPORTED:
			panel.call("_on_language", locale)
			await _settle()
			_assert_main(panel)
			for page in ["Audio", "Controls"]:
				panel.get_node(VIEW_ROOT + "Main/" + page + "Button").pressed.emit()
				await _settle()
				_assert_subview(panel, page)
				panel.get_node("SafeArea/Bounds/Center/Header/BackButton").pressed.emit()
				await _settle()
				assert_true(panel.get_node(VIEW_ROOT + "Main").is_visible_in_tree())
				assert_eq(panel.get_node("SafeArea/Bounds/Center/Header/Title").text, tr("SETTINGS_TITLE"))
		viewport.queue_free()
		await get_tree().process_frame


func _assert_main(panel: Control) -> void:
	_assert_bounds(panel, panel.get_node("SafeArea/Bounds/Center/Header/Title"))
	_assert_bounds(panel, panel.get_node("SafeArea/Bounds/Center/Header/BackButton"))
	assert_eq(panel.get_node("SafeArea/Bounds/Center/Header/BackButton").text, "›" if TranslationServer.get_locale() == "ar" else "‹")
	for path in ["Main/LanguageRow/LanguageButton", "Main/AudioButton", "Main/ControlsButton"]:
		var button: Button = panel.get_node(VIEW_ROOT + path)
		_assert_bounds(panel, button)
		assert_gte(button.size.y, 72.0, "main touch target remains large")
	for path in ["LegalFooter/Copyright", "LegalFooter/LicensesButton", "LegalFooter/PrivacyButton"]:
		_assert_bounds(panel, panel.get_node("SafeArea/Bounds/Bottom/" + path))
	var center: Control = panel.get_node("SafeArea/Bounds/Center")
	var bottom: Control = panel.get_node("SafeArea/Bounds/Bottom")
	assert_false(center.get_global_rect().intersects(bottom.get_global_rect()),
		"navigation %s (min %s) does not overlap footer %s (%s)" % [center.get_global_rect(), center.get_combined_minimum_size(), bottom.get_global_rect(), TranslationServer.get_locale()])


func _assert_subview(panel: Control, page: String) -> void:
	assert_false(panel.get_node(VIEW_ROOT + "Main").is_visible_in_tree())
	assert_false(panel.get_node("SafeArea/Bounds/Bottom/LegalFooter").is_visible_in_tree())
	assert_eq(panel.get_node("SafeArea/Bounds/Center/Header/Title").text, tr("SETTINGS_" + page.to_upper()))
	var paths: Array = ["MasterRow", "SfxRow", "MusicRow", "MuteRow"] if page == "Audio" else ["Segment/SwipeButton", "Segment/TapButton", "Segment/DpadButton"]
	for path: String in paths:
		var control: Control = panel.get_node(VIEW_ROOT + page + "/" + path)
		_assert_bounds(panel, control)
		assert_lte(control.get_global_rect().end.y, panel.get_node("SafeArea/Bounds/Bottom").get_global_rect().position.y)
	_assert_bounds(panel, panel.get_node("SafeArea/Bounds/Center/Header/BackButton"))


func _assert_bounds(panel: Control, control: Control) -> void:
	var bounds: Rect2 = panel.get_node("SafeArea/Bounds").get_global_rect().grow(0.1)
	assert_true(control.is_visible_in_tree(), control.name + " is visible")
	assert_true(bounds.encloses(control.get_global_rect()), "%s fits safe bounds (%s, %s): %s inside %s" % [control.name, TranslationServer.get_locale(), panel.size, control.get_global_rect(), bounds])
	assert_gte(control.size.x + 0.1, control.get_combined_minimum_size().x, control.name + " text fits horizontally")
	if control is Button:
		assert_gte(control.size.y, 48.0, "button preserves a full touch target")


func _settle() -> void:
	for frame in 3:
		await get_tree().process_frame
