extends GutTest

## Match the actual canvas_items stretch, rather than treating output pixels as UI units.
const SETTINGS: PackedScene = preload("res://scenes/ui/Settings.tscn")
var _saved_language: String

func before_each() -> void:
	_saved_language = AudioManager.settings().language

func after_each() -> void:
	AdsService.privacy_options_changed.emit(false, false)
	AudioManager.set_language(_saved_language)
	TranslationServer.set_locale("en")

func test_original_single_page_fits_all_locales_with_safe_areas() -> void:
	for output in [Vector2i(360, 640), Vector2i(393, 852), Vector2i(720, 1280)]:
		var host := SubViewportContainer.new()
		host.size = Vector2(output)
		add_child_autofree(host)
		var viewport := SubViewport.new()
		viewport.size = output
		viewport.size_2d_override = Vector2i(720, ceili(720.0 * output.y / output.x))
		viewport.size_2d_override_stretch = true
		host.add_child(viewport)
		var panel: Control = SETTINGS.instantiate()
		viewport.add_child(panel)
		var inset: int = ceili(24.0 * 720.0 / output.x)
		panel.get_node("SafeArea").content_padding = Vector4i(24, 24 + inset, 24, 24 + inset)
		for button: Button in panel.find_children("*", "Button", true, false):
			# Simulate the Android guard's 48 dp floor at the explicit output scale.
			# Offscreen host transforms are unrelated to the desktop's physical DPI.
			button.custom_minimum_size = button.custom_minimum_size.max(Vector2.ONE * ceilf(48.0 * 720.0 / output.x))
		AdsService.privacy_options_changed.emit(true, false)
		assert_eq(panel.find_children("*", "ScrollContainer", true, false).size(), 0)
		assert_false(panel.has_node("SafeArea/Bounds/Center/Views"), "no subpages or navigation cards")
		for locale: String in LocaleUtil.SUPPORTED:
			panel.call("_on_language", locale)
			for frame in 4:
				await get_tree().process_frame
			_assert_composition(panel, viewport)
		host.queue_free()
		await get_tree().process_frame

func _assert_composition(panel: Control, viewport: SubViewport) -> void:
	var center: Control = panel.get_node("SafeArea/Bounds/Center")
	var bottom: Control = panel.get_node("SafeArea/Bounds/Bottom")
	var bounds: Rect2 = panel.get_node("SafeArea/Bounds").get_global_rect().grow(0.1)
	assert_lte(center.get_global_rect().end.y, bottom.get_global_rect().position.y, "content/footer separation")
	assert_almost_eq(bottom.get_global_rect().position.y - center.get_global_rect().end.y, 24.0, 0.1, "no expanding empty gap before Back")
	var previous_end: float = bounds.position.y
	for section in ["Center/Title", "Center/Rows", "Center/ControlsRow", "Center/LanguageRow", "Bottom"]:
		var node: Control = panel.get_node("SafeArea/Bounds/" + section)
		assert_true(bounds.encloses(node.get_global_rect()), "%s fits %s/%s: %s in %s" % [section, viewport.size, TranslationServer.get_locale(), node.get_global_rect(), bounds])
		assert_gte(node.get_global_rect().position.y + 0.1, previous_end, "original vertical order")
		previous_end = node.get_global_rect().end.y
	for control: Control in panel.find_children("*", "Control", true, false):
		if control is Button or control is HSlider or control is Label:
			_assert_control(control, viewport, bounds)
	assert_true(panel.get_node("SafeArea/Bounds/Center/ControlsRow/Segment") is HBoxContainer)
	for row in ["MasterRow", "SfxRow", "MusicRow"]:
		var audio_row: Control = panel.get_node("SafeArea/Bounds/Center/Rows/" + row)
		var header: Control = audio_row.get_node("Header")
		var slider: HSlider = audio_row.get_node("Slider")
		assert_gte(slider.size.y, 54.0)
		assert_true(audio_row.get_global_rect().grow(0.1).encloses(header.get_global_rect()), "audio header stays in its row")
		assert_lte(header.get_global_rect().end.y, slider.get_global_rect().position.y, "audio label stays above its slider")

func _assert_control(control: Control, viewport: SubViewport, bounds: Rect2) -> void:
	assert_true(control.is_visible_in_tree(), control.name + " is on the single page")
	assert_true(bounds.encloses(control.get_global_rect()), "%s fits safe area in %s" % [control.name, TranslationServer.get_locale()])
	assert_gte(control.size.x + 0.1, control.get_combined_minimum_size().x, control.name + " text width")
	assert_gte(control.size.y + 0.1, control.get_combined_minimum_size().y, control.name + " text height")
	if control is Button:
		var pixels: Vector2 = control.size * Vector2(viewport.size) / Vector2(viewport.size_2d_override)
		assert_gte(pixels.x + 0.1, 48.0, "button width at 160 dpi")
		assert_gte(pixels.y + 0.1, 48.0, "button height at 160 dpi")
