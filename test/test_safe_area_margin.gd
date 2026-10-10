extends GutTest

## Focused coordinate/layout foundation checks; no production scene/save/gameplay mutation.
const SAFE_MARGIN = preload("res://scripts/ui/safe_area_margin.gd")
const PORTRAIT_SIZES: Array[Vector2] = [Vector2(720, 1280), Vector2(720, 1440),
	Vector2(720, 1560), Vector2(720, 1600), Vector2(720, 1680), Vector2(960, 1280)]


class SimulatedMargin:
	extends SafeAreaMargin
	var display_safe: Rect2 = Rect2()
	var local_to_display: Transform2D = Transform2D.IDENTITY


	func _get_display_safe_area() -> Rect2:
		return display_safe


	func _get_local_to_display() -> Transform2D:
		return local_to_display


func test_all_six_aspects_convert_insets_once_at_multiple_scales() -> void:
	for logical_size: Vector2 in PORTRAIT_SIZES:
		for factor: float in [0.75, 1.0, 1.5, 2.0]:
			var transform := Transform2D(Vector2(factor, 0), Vector2(0, factor), Vector2.ZERO)
			var safe := Rect2(Vector2(24, 96), logical_size * factor - Vector2(60, 144))
			var actual: Vector4i = SAFE_MARGIN.calculate_insets(safe, transform, logical_size)
			var expected := Vector4i(ceili(24.0 / factor), ceili(96.0 / factor),
				ceili(36.0 / factor), ceili(48.0 / factor))
			assert_eq(actual, expected, "aspect %s scale %s" % [logical_size, factor])


func test_zero_safe_rect_and_full_display_produce_zero_for_all_aspects() -> void:
	for logical_size: Vector2 in PORTRAIT_SIZES:
		var transform := Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2(80, 120))
		assert_eq(SAFE_MARGIN.calculate_insets(Rect2(), transform, logical_size), Vector4i.ZERO)
		assert_eq(SAFE_MARGIN.calculate_insets(transform * Rect2(Vector2.ZERO, logical_size),
			transform, logical_size), Vector4i.ZERO)


func test_system_inset_window_does_not_receive_insets_again() -> void:
	var safe := Rect2(24, 96, 1020, 2256)
	var transform := Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), safe.position)
	assert_eq(SAFE_MARGIN.calculate_insets(safe, transform, safe.size / 1.5), Vector4i.ZERO)


func test_partial_window_insets_only_apply_the_remainder() -> void:
	var safe := Rect2(24, 96, 1020, 2256)
	var transform := Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2(24, 60))
	assert_eq(SAFE_MARGIN.calculate_insets(safe, transform, Vector2(680, 1528)), Vector4i(0, 24, 0, 0))


func test_nested_safe_region_has_no_second_padding() -> void:
	var safe := Rect2(0, 120, 1080, 2208)
	var outer: Vector4i = SAFE_MARGIN.calculate_insets(safe,
		Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2.ZERO), Vector2(720, 1600))
	assert_eq(outer, Vector4i(0, 80, 0, 48))
	var inner := Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2(0, 120))
	assert_eq(SAFE_MARGIN.calculate_insets(safe, inner, Vector2(720, 1472)), Vector4i.ZERO)


func test_orientation_refresh_uses_new_display_axes() -> void:
	var landscape := Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2.ZERO)
	assert_eq(SAFE_MARGIN.calculate_insets(Rect2(96, 24, 2208, 1008), landscape,
		Vector2(1600, 720)), Vector4i(64, 16, 64, 32))


func test_fractional_rounding_and_outside_bounds_never_make_negative_margins() -> void:
	assert_eq(SAFE_MARGIN.calculate_insets(Rect2(1, 2, 1077, 2395),
		Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2.ZERO),
		Vector2(720, 1600)), Vector4i(1, 2, 2, 2))
	assert_eq(SAFE_MARGIN.calculate_insets(Rect2(-10, -20, 1100, 2440),
		Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2.ZERO), Vector2(720, 1600)), Vector4i.ZERO)
	assert_eq(SAFE_MARGIN.calculate_insets(Rect2(2000, 3000, 100, 100),
		Transform2D.IDENTITY, Vector2(720, 1280)), Vector4i(720, 1280, 0, 0))


func test_zero_size_and_singular_transform_are_safe() -> void:
	assert_eq(SAFE_MARGIN.calculate_insets(Rect2(0, 20, 720, 1260),
		Transform2D.IDENTITY, Vector2.ZERO), Vector4i.ZERO)
	assert_eq(SAFE_MARGIN.calculate_insets(Rect2(0, 20, 720, 1260),
		Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO), Vector2(720, 1280)), Vector4i.ZERO)


func test_native_container_is_idempotent_and_preserves_authored_padding() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1600)
	add_child_autofree(viewport)
	var margin := SimulatedMargin.new()
	margin.content_padding = Vector4i(12, 16, 20, 24)
	margin.local_to_display = Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2.ZERO)
	margin.display_safe = Rect2(0, 120, 1080, 2208)
	viewport.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := Control.new()
	margin.add_child(content)
	await get_tree().process_frame
	margin.refresh_safe_area()
	margin.refresh_safe_area()
	await get_tree().process_frame
	assert_eq(margin.safe_insets(), Vector4i(0, 80, 0, 48))
	assert_eq(content.position, Vector2(12, 96))
	assert_eq(content.size, Vector2(688, 1432))
	assert_eq(margin.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	viewport.size = Vector2i(960, 1280)
	margin.display_safe = Rect2(0, 48, 1440, 1824)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(margin.safe_insets(), Vector4i(0, 32, 0, 32), "resize re-reads platform bounds")
	assert_eq(content.position, Vector2(12, 48))
	assert_eq(content.size, Vector2(928, 1176))


func test_desktop_ignores_work_area_and_clamps_negative_content_padding() -> void:
	var margin: SafeAreaMargin = SAFE_MARGIN.new()
	margin.content_padding = Vector4i(-1, 10, -4, 12)
	add_child_autofree(margin)
	margin.size = Vector2(720, 1280)
	margin.refresh_safe_area()
	assert_eq(margin.safe_insets(), Vector4i.ZERO)
	assert_eq(margin.content_padding, Vector4i(0, 10, 0, 12))
	assert_eq(margin.get_theme_constant(&"margin_top"), 10)


func test_real_window_screen_transform_includes_expand_stretch_once() -> void:
	var window := Window.new()
	window.content_scale_size = Vector2i(720, 1280)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size = Vector2i(1080, 2400)
	add_child_autofree(window)
	var margin: SafeAreaMargin = SAFE_MARGIN.new()
	window.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for logical_size: Vector2 in PORTRAIT_SIZES:
		window.size = Vector2i(logical_size * 1.5)
		await get_tree().process_frame
		assert_eq(margin.size, logical_size)
		var transform: Transform2D = margin.get_screen_transform()
		assert_almost_eq(transform.x.x, 1.5, 0.001)
		assert_almost_eq(transform.y.y, 1.5, 0.001)
		var display_rect: Rect2 = transform * Rect2(Vector2.ZERO, margin.size)
		var safe := Rect2(display_rect.position + Vector2(0, 120), display_rect.size - Vector2(0, 192))
		assert_eq(SAFE_MARGIN.calculate_insets(safe, transform, margin.size), Vector4i(0, 80, 0, 48))


func test_focus_and_resume_refresh_without_viewport_resize() -> void:
	var margin := SimulatedMargin.new()
	add_child_autofree(margin)
	margin.size = Vector2(720, 1280)
	await get_tree().process_frame
	margin.display_safe = Rect2(0, 40, 720, 1200)
	margin.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await get_tree().process_frame
	assert_eq(margin.safe_insets(), Vector4i(0, 40, 0, 40))
	margin.display_safe = Rect2(0, 80, 720, 1160)
	margin.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await get_tree().process_frame
	assert_eq(margin.safe_insets(), Vector4i(0, 80, 0, 40))


func test_reparent_reconnects_only_to_current_viewport() -> void:
	var first := SubViewport.new()
	first.size = Vector2i(720, 1280)
	var second := SubViewport.new()
	second.size = Vector2i(960, 1280)
	add_child_autofree(first)
	add_child_autofree(second)
	var margin := SimulatedMargin.new()
	first.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	assert_true(first.size_changed.is_connected(margin._queue_refresh))
	first.remove_child(margin)
	assert_false(first.size_changed.is_connected(margin._queue_refresh))
	margin.refresh_safe_area()
	margin.display_safe = Rect2(0, 32, 960, 1216)
	second.add_child(margin)
	await get_tree().process_frame
	assert_true(second.size_changed.is_connected(margin._queue_refresh))
	assert_eq(margin.safe_insets(), Vector4i(0, 32, 0, 32))
