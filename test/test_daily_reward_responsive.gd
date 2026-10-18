extends GutTest

## D1-only layout fixtures: no canonical claim or user save is called.
const MENU: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const BOX: String = "SafeArea/Bounds/Box"
const BODY: String = "SafeArea/Bounds/Box/Scroll/Body/Content"
const SIZES: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1440), Vector2i(720, 1560),
	Vector2i(720, 1600), Vector2i(720, 1680), Vector2i(960, 1280)]


class SimulatedSafeArea:
	extends SafeAreaMargin
	var display_rect: Rect2


	func _get_display_safe_area() -> Rect2:
		return display_rect


	func _get_local_to_display() -> Transform2D:
		return get_global_transform_with_canvas()


func after_each() -> void:
	TranslationServer.set_locale("en")


func _mount(dimensions: Vector2i, insets: Vector4i, day: int, available: bool) -> DailyRewardPopup:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var menu: Control = MENU.instantiate()
	var popup: DailyRewardPopup = menu.get_node("RewardPopup")
	menu.remove_child(popup)
	menu.free()
	popup.claim_action = func() -> Dictionary: return Economy.login_reward_spec(day)
	popup.entrance_duration = 0.0
	var original: SafeAreaMargin = popup.get_node("SafeArea")
	var safe := SimulatedSafeArea.new()
	safe.name = "ReplacementSafeArea"
	popup.add_child(safe)
	safe.content_padding = original.content_padding
	safe.display_rect = Rect2(Vector2(insets.x, insets.y), Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w))
	var bounds: Control = original.get_node("Bounds")
	bounds.owner = null
	original.remove_child(bounds)
	safe.add_child(bounds)
	popup.remove_child(original)
	original.free()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(popup)
	popup.present({"claimable": available, "new_streak": day}, true)
	await wait_process_frames(7)
	return popup


func _inside(actual: Rect2, outer: Rect2, context: String) -> void:
	assert_true(actual.position.x >= outer.position.x - 0.1 and actual.position.y >= outer.position.y - 0.1
		and actual.end.x <= outer.end.x + 0.1 and actual.end.y <= outer.end.y + 0.1,
		"%s: %s within %s" % [context, actual, outer])


func _check(popup: DailyRewardPopup, day: int, available: bool) -> void:
	var safe: SafeAreaMargin = popup.get_node("SafeArea")
	var margin: Vector4i = safe.safe_insets() + safe.content_padding
	var area := Rect2(Vector2(margin.x, margin.y), popup.size - Vector2(margin.x + margin.z, margin.y + margin.w))
	_inside(popup._box.get_global_rect(), area, "bounded popup")
	assert_lte(popup._box.size.x, 760.0)
	assert_gt(popup._scroll.size.y, 0.0)
	for path: String in ["RewardTitle", "Scroll", "Footer"]:
		_inside(popup.get_node(BOX + "/" + path).get_global_rect(), area, path)
	for action: Button in [popup._claim, popup._close]:
		if action.visible:
			_inside(action.get_global_rect(), area, "footer action")
			assert_gte(action.size.x * 320.0 / 720.0, 48.0)
			assert_gte(action.size.y * 320.0 / 720.0, 48.0)
	assert_eq(popup._claim.visible, available)
	assert_eq(popup.current_day, day)
	assert_eq(popup._route.current_day, day)
	assert_eq(popup._route.completed_days, day - 1 if available else day)
	assert_eq(popup._route.checkpoints.size(), 10)
	assert_eq(popup._route_scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
	assert_eq(popup._route_scroll.scroll_horizontal, 0)
	for checkpoint: Button in popup._route.checkpoints:
		_inside(checkpoint.get_global_rect(), popup._route_scroll.get_global_rect(), "all ten days visible together")
		_inside(checkpoint.get_child(0).get_global_rect(), checkpoint.get_global_rect(), "day number fits target")
		assert_gte(checkpoint.size.x * 320.0 / 720.0, 48.0)
		assert_gte(checkpoint.size.y * 320.0 / 720.0, 48.0)
		assert_eq(checkpoint.get_child(0).text, str(checkpoint.get_index() + 1))
	assert_eq(popup.get_node("Dim").size, popup.size)


func test_six_aspects_locales_insets_days_and_claimed_available_states() -> void:
	var original: Dictionary = Economy._data.to_dict().duplicate(true)
	for dimensions: Vector2i in SIZES:
		for locale: String in LocaleUtil.SUPPORTED:
			TranslationServer.set_locale(locale)
			for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
				for day: int in [1, 7, 10]:
					for available: bool in [false, true]:
						var popup: DailyRewardPopup = await _mount(dimensions, insets, day, available)
						_check(popup, day, available)
						var bar: VScrollBar = popup._scroll.get_v_scroll_bar()
						assert_lte(bar.max_value - bar.page, 0.1, "ordinary rewards need no vertical scrolling")
						_inside(popup._route.get_global_rect(), popup._scroll.get_global_rect(), "entire calendar visible in body")
						assert_eq(popup.preview_spec, Economy.login_reward_spec(day))
						popup.get_parent().free()
	assert_eq(Economy._data.to_dict(), original)


func test_first_middle_last_checkpoints_are_accessible_without_scrolling() -> void:
	for dimensions: Vector2i in SIZES:
		var popup: DailyRewardPopup = await _mount(dimensions, Vector4i(24, 96, 24, 48), 7, true)
		for day: int in [1, 5, 10]:
			popup._route.checkpoints[day - 1].pressed.emit()
			await wait_process_frames(3)
			_inside(popup._route.checkpoints[day - 1].get_global_rect(), popup._scroll.get_global_rect(), "checkpoint visible without scrolling")
			assert_eq(popup._route_scroll.scroll_horizontal, 0)
			assert_eq(popup._scroll.scroll_vertical, 0)
			assert_eq(popup.selected_day, day)
			assert_eq(popup.current_day, 7)
			assert_true(popup._claim.visible)
		_inside(popup._close.get_global_rect(), popup._box.get_global_rect(), "close stays reachable")
		popup.get_parent().free()


func test_five_columns_two_rows_fit_a_narrower_phone() -> void:
	var popup: DailyRewardPopup = await _mount(Vector2i(640, 1280), Vector4i(24, 96, 24, 48), 10, true)
	for index: int in 10:
		var checkpoint: Button = popup._route.checkpoints[index]
		_inside(checkpoint.get_global_rect(), popup._scroll.get_global_rect(), "narrow phone calendar")
		assert_gte(checkpoint.size.x * 320.0 / 640.0, 48.0, "narrow phone touch width")
		assert_gte(checkpoint.size.y * 320.0 / 640.0, 48.0, "narrow phone touch height")
		if index < 5:
			assert_almost_eq(checkpoint.position.y, 0.0, 0.1)
		else:
			assert_gt(checkpoint.position.y, popup._route.checkpoints[index - 5].get_rect().end.y)
	assert_almost_eq(popup._route.checkpoints[0].position.x, popup._route.checkpoints[5].position.x, 0.1)
	assert_eq(popup._route_scroll.scroll_horizontal, 0)
	assert_eq(popup._scroll.scroll_vertical, 0)
	_inside(popup._claim.get_global_rect(), popup._box.get_global_rect(), "narrow phone claim")
	_inside(popup._close.get_global_rect(), popup._box.get_global_rect(), "narrow phone back")


func test_long_reward_labels_scroll_without_clipping_footer() -> void:
	for locale: String in LocaleUtil.SUPPORTED:
		TranslationServer.set_locale(locale)
		var popup: DailyRewardPopup = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48), 7, true)
		popup._currency.text = "A longer localized reward name with readable complete details. ".repeat(4)
		await wait_process_frames(7)
		assert_lte(popup._currency.get_minimum_size().y, popup._currency.size.y)
		popup._scroll.ensure_control_visible(popup._currency)
		await wait_process_frames(2)
		_inside(popup._currency.get_global_rect(), popup._scroll.get_global_rect(), "long name fully reachable")
		_check(popup, 7, true)
		popup.get_parent().free()


func test_claim_preview_returns_to_today_and_animation_stays_in_reserved_hero_area() -> void:
	var popup: DailyRewardPopup = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48), 7, true)
	var calls := [0]
	popup.claim_action = func() -> Dictionary: calls[0] += 1; return {"coins": 0, "boost_ids": [&"extra_life"]}
	popup.preview_day(10)
	popup._claim.pressed.emit()
	assert_eq(calls[0], 1)
	assert_eq(popup.selected_day, 7)
	assert_eq(popup.state, DailyRewardPopup.State.CLAIMED)
	for tick: int in 5:
		await wait_seconds(0.06)
		var icon: Control = popup._active_reward_icon
		_inside(icon.get_global_rect(), popup._hero.get_global_rect(), "pulse fits reserved hero")
		var center: Vector2 = icon.global_position + icon.size * 0.5
		var radius: float = icon.size.x * (0.55 + 0.2 * popup._ring_progress)
		_inside(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), popup._hero.get_global_rect(), "ring fits hero")
		_inside(popup._hero.get_global_rect(), popup._scroll.get_global_rect(), "hero revealed before claim feedback")
	popup._claim.pressed.emit()
	assert_eq(calls[0], 1)


func test_close_inspection_emits_once_without_claim() -> void:
	var popup: DailyRewardPopup = await _mount(Vector2i(960, 1280), Vector4i.ZERO, 10, false)
	watch_signals(popup)
	popup.claim_action = func() -> Dictionary: fail_test("inspection must not claim"); return {}
	popup._close.pressed.emit()
	await wait_for_signal(popup.dismissed, 1.0)
	assert_eq(popup.state, DailyRewardPopup.State.HIDDEN)
	assert_signal_emit_count(popup, "dismissed", 1)


func test_animated_entrance_finishes_with_day_ten_target_and_highlight_fully_visible() -> void:
	var popup: DailyRewardPopup = await _mount(Vector2i(720, 1280), Vector4i.ZERO, 10, true)
	popup.entrance_duration = 0.20
	popup.present({"claimable": true, "new_streak": 10})
	await wait_seconds(0.30)
	_inside(popup._route.checkpoints[9].get_global_rect(), popup._route_scroll.get_global_rect(), "initial day ten target")
	var center: Vector2 = popup._route.get_global_transform() * popup._route.checkpoint_center(9)
	var radius: float = popup._route.checkpoint_radius * popup._route.endpoint_scale
	_inside(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0),
		popup._route_scroll.get_global_rect(), "day ten diamond after entry scale")
