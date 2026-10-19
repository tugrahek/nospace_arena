extends "res://test/helpers/supply_acquisition_fixture.gd"

## Isolated presentation records; physical device/profile and canonical RNG are never touched.
const SCENE: PackedScene = preload("res://scenes/ui/SupplyPopup.tscn")
const FRAME: String = "SafeArea/Bounds/Frame"
const SIZES: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1440), Vector2i(720, 1560),
	Vector2i(720, 1600), Vector2i(720, 1680), Vector2i(960, 1280)]
const CASES: Array[String] = ["ad", "coin", "tomorrow", "busy", "unavailable", "failure", "odds",
	"coins", "slow_start", "coin_bonus", "extra_life", "save_retry"]


class SimulatedSafeArea:
	extends SafeAreaMargin
	var display_rect: Rect2


	func _get_display_safe_area() -> Rect2:
		return display_rect


	func _get_local_to_display() -> Transform2D:
		return get_global_transform_with_canvas()


func after_each() -> void:
	TranslationServer.set_locale("en")
	super.after_each()


func _prepare_case(case_name: String) -> void:
	_economy._data.supply_boxes.clear()
	_economy._data.supply_acquisition_days.clear()
	_economy._data.currency = 0 if case_name == "unavailable" else 500
	_economy.fail_at = -1
	var available: bool = case_name not in ["coin", "unavailable", "failure"]
	_ads.set_requests_allowed(available)
	if available and not _ads.is_rewarded_available():
		if _ads.state != AdsScript.State.LOADING:
			_ads.preload_rewarded()
		_fake.complete_load(_fake.load_tokens.back())
	if case_name == "tomorrow":
		_economy._data.supply_acquisition_days[str(_day[0])] = {"coin_count": 2, "rewarded_count": 1}
	if case_name in ["coins", "slow_start", "coin_bonus", "extra_life", "save_retry"]:
		var type: String = "coins" if case_name == "save_retry" else case_name
		_economy._data.supply_boxes["layout"] = {"box_id": "layout", "source": "layout_fixture",
			"context": "layout_fixture", "table_key": "layout_fixture", "table_version": 1,
			"state": "delivered", "reward_type": type, "amount": 200 if type == "coins" else 1, "presented": false}
	_acquisition._config = SupplyBoxAcquisition.CONFIG


func _mount(dimensions: Vector2i, insets: Vector4i, case_name: String, modal: bool = false) -> SupplyPopup:
	_prepare_case(case_name)
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var popup: SupplyPopup = SCENE.instantiate()
	popup.economy = _economy
	popup.ads = _ads
	popup.core = _economy.supply_boxes()
	popup.acquisition = _acquisition
	popup.reveal_duration = 0.0
	var original: SafeAreaMargin = popup.get_node("SafeArea")
	var safe := SimulatedSafeArea.new()
	safe.name = "ReplacementSafeArea"
	popup.add_child(safe)
	safe.content_padding = original.content_padding
	safe.display_rect = Rect2(Vector2(insets.x, insets.y),
		Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w))
	var bounds: Control = original.get_node("Bounds")
	bounds.owner = null
	original.remove_child(bounds)
	safe.add_child(bounds)
	popup.remove_child(original)
	original.free()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(popup)
	if modal:
		popup.size = Vector2(640, 600)
		popup.position = (Vector2(dimensions) - popup.size) * 0.5
	else:
		popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.present()
	_apply_case(popup, case_name)
	await wait_process_frames(7)
	return popup


func _apply_case(popup: SupplyPopup, case_name: String) -> void:
	if case_name == "busy":
		popup.state = SupplyPopup.State.BUSY
		popup._ad_token = 77
		popup.refresh()
	elif case_name in ["unavailable", "failure"]:
		popup._feedback.text = tr("SUPPLY_AD_UNAVAILABLE" if case_name == "unavailable" else "SUPPLY_AD_FAILED")
		popup.refresh()
	elif case_name == "odds":
		popup.show_odds()
	elif case_name == "save_retry":
		_economy.fail_at = _economy.writes + 1
		popup._continue.pressed.emit()


func _inside(actual: Rect2, outer: Rect2, context: String) -> void:
	assert_true(actual.position.x >= outer.position.x - 0.1 and actual.position.y >= outer.position.y - 0.1
		and actual.end.x <= outer.end.x + 0.1 and actual.end.y <= outer.end.y + 0.1,
		"%s: %s within %s" % [context, actual, outer])


func _check_view(popup: SupplyPopup, case_name: String) -> void:
	var safe: SafeAreaMargin = popup.get_node("SafeArea")
	var margin: Vector4i = safe.safe_insets() + safe.content_padding
	var area := Rect2(popup.global_position + Vector2(margin.x, margin.y),
		popup.size - Vector2(margin.x + margin.z, margin.y + margin.w))
	var name: String = "OddsView" if case_name == "odds" else "RevealView" if popup.state == SupplyPopup.State.REVEAL else "Surface"
	var view: VBoxContainer = popup.get_node(FRAME + "/" + name)
	for child: String in ["Title", "Scroll", "Footer"]:
		_inside(view.get_node(child).get_global_rect(), area, case_name + child)
	assert_gt(view.get_node("Scroll").size.y, 0.0, "body has a usable viewport")
	assert_lte(popup._frame.size.x, 800.0)
	for action: SupplyActionButton in view.get_node("Footer").get_children():
		if action.is_visible_in_tree():
			_inside(action.get_global_rect(), area, case_name + " footer action")
			assert_gte(action.size.x * 320.0 / 720.0, 48.0)
			assert_gte(action.size.y * 320.0 / 720.0, 48.0)
	if name == "RevealView":
		var continue_button: SupplyActionButton = view.get_node("Footer/Continue")
		assert_true(continue_button.is_visible_in_tree(), case_name + " Continue action visible")
		_inside(continue_button.get_global_rect(), area, case_name + " Continue action")
	var body: Control = view.get_node("Scroll/Body")
	for item: Control in view.get_node("Scroll/Body/Content").get_children():
		if item.is_visible_in_tree():
			_inside(item.get_global_rect(), body.get_global_rect(), case_name + " body item")
	if name == "Surface":
		var action: SupplyActionButton = popup._ad if popup._ad.get_parent().visible else popup._coin
		assert_gte(action.size.y * 320.0 / 720.0, 48.0)
		if case_name in ["busy", "tomorrow", "unavailable"]:
			assert_true(action.disabled)
	if name == "OddsView":
		var rows: VBoxContainer = view.get_node("Scroll/Body/Content/Rows")
		assert_eq(rows.get_child_count(), 4)
		assert_eq(rows.get_child(0).get_node("Probability").text, "35%")
	if case_name == "save_retry":
		assert_false(view.get_node("Scroll/Body/Content/Feedback").text.is_empty())


func test_all_six_ratios_locales_insets_and_supply_states() -> void:
	for dimensions: Vector2i in SIZES:
		for locale: String in ["en", "tr"]:
			TranslationServer.set_locale(locale)
			for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
				for case_name: String in CASES:
					var popup: SupplyPopup = await _mount(dimensions, insets, case_name)
					var snapshot: Dictionary = _economy._data.to_dict().duplicate(true)
					var rng: int = _economy.supply_boxes()._rng.state
					_check_view(popup, case_name)
					assert_eq(_economy._data.to_dict(), snapshot)
					assert_eq(_economy.supply_boxes()._rng.state, rng)
					popup.get_parent().free()


func test_a1_localized_supply_copy_fits_representative_portrait_views() -> void:
	for locale: String in ["de", "fr", "es", "pt_BR", "it"]:
		TranslationServer.set_locale(locale)
		for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280)]:
			for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
				for case_name: String in ["odds", "coins", "slow_start", "extra_life", "tomorrow"]:
					var popup: SupplyPopup = await _mount(dimensions, insets, case_name)
					_check_view(popup, case_name)
					popup.get_parent().free()


func test_shared_small_dialog_and_scroll_keep_actions_accessible() -> void:
	for case_name: String in ["ad", "odds", "coins", "extra_life", "save_retry"]:
		var popup: SupplyPopup = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48), case_name, true)
		_check_view(popup, case_name)
		var name: String = "OddsView" if case_name == "odds" else "RevealView" if popup.state == SupplyPopup.State.REVEAL else "Surface"
		var scroll: ScrollContainer = popup.get_node(FRAME + "/" + name + "/Scroll")
		var content: VBoxContainer = scroll.get_node("Body/Content")
		var last: Control
		if name == "OddsView":
			last = content.get_node("Rows").get_child(3)
		elif name == "RevealView":
			last = content.get_node("Feedback") if case_name == "save_retry" else popup._reward
		else:
			last = popup._ad if popup._ad.get_parent().visible else popup._coin
		scroll.ensure_control_visible(last)
		await wait_process_frames(2)
		_inside(last.get_global_rect(), scroll.get_global_rect(), "last content reachable")
		popup.get_parent().free()


func test_long_cta_feedback_odds_and_reward_labels_wrap_without_overlap() -> void:
	for case_name: String in ["ad", "odds", "coins"]:
		var popup: SupplyPopup = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48), case_name, true)
		var long_text: String = "A complete longer localized label with several readable words. ".repeat(3)
		if case_name == "ad":
			popup._ad.set_caption(long_text)
			popup._feedback.text = long_text
			popup._feedback.visible = true
		elif case_name == "odds":
			popup.get_node(FRAME + "/OddsView/Scroll/Body/Content/Rows").get_child(0).get_node("Name").text = long_text
		else:
			popup._reward.text = long_text
			popup.get_node(FRAME + "/RevealView/Scroll/Body/Content/Feedback").text = long_text
		await wait_process_frames(8)
		_check_view(popup, case_name)
		popup.get_parent().free()


func test_reveal_animation_envelope_stays_inside_scroll_without_model_mutation() -> void:
	var popup: SupplyPopup = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48), "coins", true)
	popup.reveal_duration = 0.55
	var snapshot: Dictionary = _economy._data.to_dict().duplicate(true)
	var rng: int = _economy.supply_boxes()._rng.state
	popup._animate_reveal()
	var scroll: ScrollContainer = popup.get_node(FRAME + "/RevealView/Scroll")
	for tick: int in 8:
		scroll.ensure_control_visible(popup._cube)
		await wait_process_frames(1)
		_inside(popup._cube.get_global_rect(), scroll.get_global_rect(), "animated cube")
		await wait_seconds(0.07)
	assert_eq(_economy._data.to_dict(), snapshot)
	assert_eq(_economy.supply_boxes()._rng.state, rng)
