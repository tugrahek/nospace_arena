extends GutTest

## Isolated UI geometry with zero/nonzero platform insets; no gameplay or save changes.
const INSETS: Vector4i = Vector4i(24, 96, 24, 48)
var _original_data: Variant

class SimulatedSafeArea:
	extends SafeAreaMargin
	var platform_rect: Rect2
	func _get_display_safe_area() -> Rect2:
		return platform_rect
	func _get_local_to_display() -> Transform2D:
		return Transform2D.IDENTITY

func before_each() -> void:
	_original_data = Economy._data
	var fixture := SaveData.new_default()
	fixture.tutorial_seen = true
	Economy._data = fixture

func after_each() -> void:
	Economy._data = _original_data
	TranslationServer.set_locale("en")

func _mount(path: String, dimensions: Vector2i, insets: Vector4i, areas: Array[String]) -> Node:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var scene: Node = load(path).instantiate()
	for area_path: String in areas:
		var safe: SafeAreaMargin = scene.get_node(area_path)
		var padding: Vector4i = safe.content_padding
		safe.set_script(SimulatedSafeArea)
		safe.content_padding = padding
		safe.set("platform_rect", Rect2(Vector2(insets.x, insets.y),
			Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w)))
	viewport.add_child(scene)
	await wait_process_frames(10)
	return scene

func test_missions_only_shrinks_when_safe_width_requires_it() -> void:
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(640, 1280), Vector2i(960, 1280)]:
		for insets: Vector4i in [Vector4i.ZERO, INSETS]:
			var scene: Control = await _mount("res://scenes/ui/Missions.tscn", dimensions, insets, ["SafeArea"])
			var bounds: Control = scene.get_node("SafeArea/Bounds")
			var layout: Control = bounds.get_node("Layout")
			assert_almost_eq(layout.size.x, minf(664.0, bounds.size.x), 0.1)
			assert_true(bounds.get_global_rect().encloses(layout.get_global_rect()))
			assert_eq(scene.get_node("SafeArea/Bounds/Layout/Scroll/List").get_child_count(), 3)
			print("MISSIONS_SAFE viewport=%s safe_width=%s layout_width=%s" % [dimensions, bounds.size.x, layout.size.x])
			scene.get_viewport().free()

func test_all_tutorial_pages_fit_narrow_scrolling_content_and_resize() -> void:
	for locale: String in ["tr", "en"]:
		TranslationServer.set_locale(locale)
		var scene: Control = await _mount("res://scenes/ui/HowToPlay.tscn", Vector2i(720, 1600), INSETS, ["SafeArea"])
		for dimensions: Vector2i in [Vector2i(720, 1600), Vector2i(600, 960), Vector2i(720, 1280)]:
			var safe: SimulatedSafeArea = scene.get_node("SafeArea")
			safe.platform_rect.size = Vector2(dimensions) - Vector2(INSETS.x + INSETS.z, INSETS.y + INSETS.w)
			scene.get_viewport().size = dimensions
			for index: int in 4:
				scene._show(index)
				await wait_process_frames(10)
				var scroll: ScrollContainer = scene.get_node("SafeArea/Bounds/MainVBox/ContentScroll")
				assert_true(scene.get_node("SafeArea/Bounds").get_global_rect().encloses(scroll.get_global_rect()), "tutorial scroll fits effective safe width")
				for child: Control in [scene._art, scene._body]:
					assert_gte(child.global_position.x, scroll.global_position.x - 0.1)
					assert_lte(child.get_global_rect().end.x, scroll.get_global_rect().end.x + 0.1)
				assert_almost_eq(scene._art.size.x / scene._art.size.y, 540.0 / 350.0, 0.01)
				assert_lte(scene._body.get_minimum_size().y, scene._body.size.y + 0.1)
				assert_true(scene.get_node("SafeArea/Bounds").get_global_rect().encloses(scene._next.get_global_rect()))
				var navigation: Control = scene.get_node("SafeArea/Bounds/MainVBox/NavigationRow")
				assert_almost_eq(navigation.global_position.y - scroll.get_global_rect().end.y,
					float(scene._main_vbox.get_theme_constant("separation")), 0.1, "navigation follows content without spare vertical space")
				if scroll.get_v_scroll_bar().max_value <= scroll.get_v_scroll_bar().page:
					assert_almost_eq(scroll.size.y, scene._page_content.get_combined_minimum_size().y, 0.1,
						"short tutorial pages use only their content height")
			print("TUTORIAL_SAFE viewport=%s art=%s body_width=%s" % [dimensions, scene._art.size, scene._body.size.x])
		scene.get_viewport().free()

func test_hud_pause_and_currency_follow_safe_insets_without_zero_inset_drift() -> void:
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(640, 1280)]:
		for insets: Vector4i in [Vector4i.ZERO, INSETS]:
			var hud: HUD = await _mount("res://scenes/ui/HUD.tscn", dimensions, insets, ["TopSafeArea", "CoinSafeArea"])
			var pause: CanvasLayer = await _mount("res://scenes/ui/PauseOverlay.tscn", dimensions, insets, ["PauseSafeArea"])
			var button: Button = pause.get_node("PauseSafeArea/Bounds/PauseButton")
			var coins: Label = hud.get_node("CoinSafeArea/Bounds/CurrencyLabel")
			assert_true(pause.get_node("PauseSafeArea/Bounds").get_global_rect().encloses(button.get_global_rect()))
			assert_true(hud.get_node("CoinSafeArea/Bounds").get_global_rect().encloses(coins.get_global_rect()))
			assert_false(button.get_global_rect().intersects(hud.get_node("TopSafeArea/InfoStack").get_global_rect()))
			assert_almost_eq(button.global_position.y, float(insets.y + 16), 0.1)
			assert_almost_eq(coins.get_global_rect().end.y, float(dimensions.y - insets.w - 12), 0.1)
			assert_almost_eq(coins.global_position.x, float(insets.x + 16), 0.1)
			if insets == Vector4i.ZERO:
				assert_almost_eq(button.global_position.x, float(dimensions.x - 84), 0.1)
			pause.get_viewport().free()
			hud.get_viewport().free()
