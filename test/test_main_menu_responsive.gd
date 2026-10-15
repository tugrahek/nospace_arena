extends GutTest

## Bounds and touch regressions for actual MainMenu instances; no production save mutation.
const MENU: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const FRAME: String = "SafeArea/Bounds/Frame"
const SIZES: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1440), Vector2i(720, 1560),
	Vector2i(720, 1600), Vector2i(720, 1680), Vector2i(960, 1280)]
const NAV: Array[String] = ["StoreButton", "MissionsButton", "LeaderboardButton", "HowToButton"]
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
	fixture.last_claim_epoch_day = SeedManager.today_epoch()
	fixture.streak_day = 10
	fixture.currency = 805
	Economy._data = fixture


func after_each() -> void:
	Economy._data = _original_data
	TranslationServer.set_locale("en")


func _mount(dimensions: Vector2i, insets: Vector4i = Vector4i.ZERO) -> Control:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var menu: Control = MENU.instantiate()
	var original: SafeAreaMargin = menu.get_node("SafeArea")
	var safe := SimulatedSafeArea.new()
	safe.name = "ReplacementSafeArea"
	menu.add_child(safe)
	safe.content_padding = original.content_padding
	safe.platform_rect = Rect2(Vector2(insets.x, insets.y),
		Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w))
	var bounds: Control = original.get_node("Bounds")
	bounds.owner = null
	original.remove_child(bounds)
	safe.add_child(bounds)
	menu.remove_child(original)
	original.free()
	safe.name = "SafeArea"
	menu.move_child(safe, 1)
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(menu)
	await wait_process_frames(5)
	return menu


func _content_rect(menu: Control) -> Rect2:
	var safe: SafeAreaMargin = menu.get_node("SafeArea")
	var margins: Vector4i = safe.safe_insets() + safe.content_padding
	return Rect2(Vector2(margins.x, margins.y),
		menu.size - Vector2(margins.x + margins.z, margins.y + margins.w))


func _assert_inside(control: Control, outer: Rect2, context: String) -> void:
	var rect: Rect2 = control.get_global_rect()
	assert_true(rect.position.x >= outer.position.x - 0.1 and rect.position.y >= outer.position.y - 0.1
		and rect.end.x <= outer.end.x + 0.1 and rect.end.y <= outer.end.y + 0.1,
		"%s: %s within %s" % [context, rect, outer])


func test_six_aspects_safe_and_zero_insets_in_both_locales() -> void:
	for dimensions: Vector2i in SIZES:
		for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
			for locale: String in ["en", "tr"]:
				TranslationServer.set_locale(locale)
				var menu: Control = await _mount(dimensions, insets)
				var safe: Rect2 = _content_rect(menu)
				var context: String = "%s %s %s" % [dimensions, insets, locale]
				for path: String in ["Header", "Header/SettingsButton", "Header/RewardEntry", "Header/CoinsPanel",
						"ContentGroup/Center/Emblem", "ContentGroup/Center/Title", "ContentGroup/Center/Subtitle", "ContentGroup/Footer", "ContentGroup/Footer/Buttons/PlayButton",
						"ContentGroup/Footer/Buttons/NavigationHub"]:
					_assert_inside(menu.get_node(FRAME + "/" + path), safe, context + " " + path)
				var hub: Control = menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/NavigationHub")
				for name: String in NAV:
					var button: Button = hub.get_node(name)
					_assert_inside(button, safe, context + " " + name)
					_assert_inside(button.get_node("Content"), button.get_global_rect(), context + " content")
					var label: Label = button.get_node("Content/Label")
					assert_lte(label.get_minimum_size().x, label.size.x + 0.1, context + " localized nav fits")
					assert_lte(label.get_minimum_size().y, label.size.y + 0.1, context + " nav label height fits")
				_assert_header_order(menu)
				assert_eq(menu.get_node(FRAME + "/Header/RewardEntry/Content/Labels/Progress").text, "10/10")
				assert_false(menu.get_node("RewardPopup").visible)
				assert_eq(Economy.balance(), 805)
				menu.get_parent().free()


func _assert_header_order(menu: Control) -> void:
	var settings: Control = menu.get_node(FRAME + "/Header/SettingsButton")
	var reward: Control = menu.get_node(FRAME + "/Header/RewardEntry")
	var coins: Control = menu.get_node(FRAME + "/Header/CoinsPanel")
	assert_lt(settings.get_global_rect().end.x, reward.global_position.x)
	assert_lt(reward.get_global_rect().end.x, coins.global_position.x)


func test_practical_phone_touch_targets_and_square_artwork() -> void:
	var menu: Control = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48))
	var controls: Array[Control] = [menu.get_node(FRAME + "/Header/SettingsButton"),
		menu.get_node(FRAME + "/Header/RewardEntry"), menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/PlayButton")]
	var hub: Control = menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/NavigationHub")
	for name: String in NAV:
		controls.append(hub.get_node(name))
		var icon: Control = hub.get_node(name + "/Content/Icon")
		assert_eq(icon.size.x, icon.size.y, "icon artwork remains square")
	for control: Control in controls:
		assert_gte(control.size.x * 320.0 / 720.0, 48.0, "320dp phone touch width")
		assert_gte(control.size.y * 320.0 / 720.0, 48.0, "320dp phone touch height")
	var emblem: Control = menu.get_node(FRAME + "/ContentGroup/Center/Emblem")
	assert_eq(emblem.size.x, emblem.size.y)


func test_long_balance_and_claimed_counter_remain_visible() -> void:
	Economy._data.currency = 999999999
	for locale: String in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var menu: Control = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48))
		_assert_header_order(menu)
		_assert_inside(menu.get_node(FRAME + "/Header"), _content_rect(menu), "long balance header")
		var label: Label = menu.get_node(FRAME + "/Header/CoinsPanel/Content/Coins")
		assert_lte(label.get_minimum_size().x, label.size.x)
		assert_true(label.text.contains("999999999"))
		assert_gte(menu.get_node(FRAME + "/Header/RewardEntry").modulate.a, 0.8)
		menu.get_parent().free()


func test_tall_screen_increases_content_and_tablet_width_is_bounded() -> void:
	var compact: Control = await _mount(Vector2i(720, 1280))
	var tall: Control = await _mount(Vector2i(720, 1680))
	assert_gt(tall.get_node(FRAME + "/ContentGroup/Center/Emblem").size.y, compact.get_node(FRAME + "/ContentGroup/Center/Emblem").size.y)
	var compact_play: Control = compact.get_node(FRAME + "/ContentGroup/Footer/Buttons/PlayButton")
	var compact_hub: Control = compact.get_node(FRAME + "/ContentGroup/Footer/Buttons/NavigationHub")
	var tall_play: Control = tall.get_node(FRAME + "/ContentGroup/Footer/Buttons/PlayButton")
	var tall_hub: Control = tall.get_node(FRAME + "/ContentGroup/Footer/Buttons/NavigationHub")
	assert_almost_eq(tall_hub.size.y, compact_hub.size.y, 0.1)
	assert_lte(compact_hub.global_position.y - compact_play.get_global_rect().end.y, 30.0)
	assert_lte(tall_hub.global_position.y - tall_play.get_global_rect().end.y, 30.0)
	var tablet: Control = await _mount(Vector2i(960, 1280))
	var frame: Control = tablet.get_node(FRAME)
	assert_lte(frame.size.x, 800.0)
	assert_almost_eq(frame.get_global_rect().get_center().x, 480.0, 0.1)
	assert_almost_eq(frame.get_global_rect().end.y, _content_rect(tablet).end.y, 0.1)


func test_native_resize_reflows_the_same_menu() -> void:
	var menu: Control = await _mount(Vector2i(720, 1280))
	var viewport: SubViewport = menu.get_parent()
	var safe: SimulatedSafeArea = menu.get_node("SafeArea")
	viewport.size = Vector2i(960, 1280)
	safe.platform_rect = Rect2(24, 96, 912, 1136)
	await wait_process_frames(5)
	_assert_inside(menu.get_node(FRAME), _content_rect(menu), "resized frame")
	assert_almost_eq(menu.get_node(FRAME).get_global_rect().get_center().x, 480.0, 0.1)
	assert_eq(menu.get_node(FRAME + "/Header/RewardEntry/Content/Labels/Progress").text, "10/10")


func test_compact_composition_fits_portrait_and_narrow_safe_widths() -> void:
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(640, 1280)]:
		for locale: String in ["en", "tr"]:
			TranslationServer.set_locale(locale)
			var menu: Control = await _mount(dimensions, Vector4i(24, 96, 24, 48))
			var safe: Rect2 = _content_rect(menu)
			for path: String in ["Header", "ContentGroup/Center", "ContentGroup/Footer"]:
				_assert_inside(menu.get_node(FRAME + "/" + path), safe, "compact group " + path)
			_assert_header_order(menu)
			var emblem: Control = menu.get_node(FRAME + "/ContentGroup/Center/Emblem")
			var play: Button = menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/PlayButton")
			var hub: Control = menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/NavigationHub")
			assert_lte(emblem.size.y, 240.0, "logo growth stays bounded")
			assert_almost_eq(play.size.y, 108.0, 0.1, "Play retains its touch height without tall-phone growth")
			assert_almost_eq(hub.size.y, 256.0, 0.1, "compact two-row hub")
			assert_lte(hub.global_position.y - play.get_global_rect().end.y, 30.0, "compact action gap retained")
			for name: String in NAV:
				var button: Button = hub.get_node(name)
				var icon: Control = button.get_node("Content/Icon")
				var label: Label = button.get_node("Content/Label")
				_assert_inside(button, safe, "compact navigation target")
				_assert_inside(icon, button.get_global_rect(), "compact navigation icon")
				_assert_inside(label, button.get_global_rect(), "compact navigation label")
				assert_lte(icon.get_rect().end.y, label.position.y, "icon and label do not overlap")
				assert_gte(button.size.y * 320.0 / float(dimensions.x), 48.0, "compact hub touch height")
			menu.get_parent().free()


func test_brand_and_actions_are_balanced_below_fixed_header() -> void:
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600)]:
		var menu: Control = await _mount(dimensions, Vector4i(24, 96, 24, 48))
		var safe: Rect2 = _content_rect(menu)
		var header: Control = menu.get_node(FRAME + "/Header")
		var emblem: Control = menu.get_node(FRAME + "/ContentGroup/Center/Emblem")
		var brand: Control = menu.get_node(FRAME + "/ContentGroup/Center")
		var play: Control = menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/PlayButton")
		var hub: Control = menu.get_node(FRAME + "/ContentGroup/Footer/Buttons/NavigationHub")
		var group_center_y: float = (emblem.global_position.y + hub.get_global_rect().end.y) * 0.5
		var available_center_y: float = (header.get_global_rect().end.y + safe.end.y) * 0.5
		assert_almost_eq(group_center_y, available_center_y, 24.0,
			"brand and actions balance below the safe-area-aware fixed header at %s" % dimensions)
		assert_almost_eq(play.global_position.y - brand.get_global_rect().end.y, 24.0, 0.1,
			"brand-to-action spacing stays compact at %s" % dimensions)
		menu.get_parent().free()


func test_popup_roots_remain_fullscreen_and_outside_safe_content() -> void:
	var menu: Control = await _mount(Vector2i(720, 1600), Vector4i(24, 96, 24, 48))
	assert_eq(menu.get_node("Background").get_global_rect(), menu.get_global_rect())
	assert_eq(menu.get_node("RewardPopup").get_parent(), menu)
	assert_eq(menu.get_node("RewardPopup/Dim").size, menu.size)
	assert_eq(menu.get_node("GiftOverlay").get_parent(), menu)
	assert_eq(menu.get_node("GiftOverlay/Dim").size, menu.size)
