extends GutTest

## Isolated ModeSelect layout/state fixtures; production inventory and navigation remain untouched.
const SCENE: PackedScene = preload("res://scenes/ui/ModeSelect.tscn")
const CENTER: String = "SafeArea/Bounds/Center"
const SIZES: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1440), Vector2i(720, 1560),
	Vector2i(720, 1600), Vector2i(720, 1680), Vector2i(960, 1280)]
const ROWS: Array[String] = ["DailyRow", "FreeRow", "LevelRow", "CampaignRow"]
var _original: Variant


class SimulatedSafeArea:
	extends SafeAreaMargin
	var platform_rect: Rect2


	func _get_display_safe_area() -> Rect2:
		return platform_rect


	func _get_local_to_display() -> Transform2D:
		return Transform2D.IDENTITY


class RecordingModeSelect:
	extends "res://scripts/ui/mode_select.gd"
	var launches: Array[int] = []
	var campaign_requests: int = 0


	func _start(mode: int) -> void:
		launches.append(mode)


	func _open_campaign() -> void:
		campaign_requests += 1


func before_each() -> void:
	_original = Economy._data
	_set_fixture(0)


func after_each() -> void:
	Economy._data = _original
	TranslationServer.set_locale("en")


func _set_fixture(state: int) -> void:
	var fixture := SaveData.new_default()
	fixture.tutorial_seen = true
	fixture.last_claim_epoch_day = SeedManager.today_epoch()
	if state != 1:
		fixture.add_boost(&"extra_life", 2)
		fixture.add_boost(&"slow_start", 3)
	if state == 2:
		fixture.add_boost(&"coin_bonus", 5)
		fixture.set_boost_armed(&"coin_bonus", true)
	elif state == 0:
		fixture.set_boost_armed(&"extra_life", true)
	Economy._data = fixture


func _mount(dimensions: Vector2i, insets: Vector4i, record: bool = false) -> Control:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var screen: Control = SCENE.instantiate()
	if record:
		screen.set_script(RecordingModeSelect)
	var original: SafeAreaMargin = screen.get_node("SafeArea")
	var safe := SimulatedSafeArea.new()
	safe.name = "ReplacementSafeArea"
	screen.add_child(safe)
	safe.content_padding = original.content_padding
	safe.platform_rect = Rect2(Vector2(insets.x, insets.y),
		Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w))
	var bounds: Control = original.get_node("Bounds")
	bounds.owner = null
	original.remove_child(bounds)
	safe.add_child(bounds)
	screen.remove_child(original)
	original.free()
	safe.name = "SafeArea"
	screen.move_child(safe, 1)
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(screen)
	await wait_process_frames(5)
	return screen


func _safe_rect(screen: Control) -> Rect2:
	var safe: SafeAreaMargin = screen.get_node("SafeArea")
	var margin: Vector4i = safe.safe_insets() + safe.content_padding
	return Rect2(Vector2(margin.x, margin.y),
		screen.size - Vector2(margin.x + margin.z, margin.y + margin.w))


func _inside(control: Control, rect: Rect2, context: String) -> void:
	var actual: Rect2 = control.get_global_rect()
	assert_true(actual.position.x >= rect.position.x - 0.1 and actual.position.y >= rect.position.y - 0.1
		and actual.end.x <= rect.end.x + 0.1 and actual.end.y <= rect.end.y + 0.1,
		"%s: %s within %s" % [context, actual, rect])


func test_all_aspects_locales_insets_and_inventory_states_fit() -> void:
	for dimensions: Vector2i in SIZES:
		for locale: String in ["en", "tr"]:
			TranslationServer.set_locale(locale)
			for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
				for state: int in [0, 1, 2]:
					_set_fixture(state)
					var before: Dictionary = Economy._data.to_dict().duplicate(true)
					var screen: Control = await _mount(dimensions, insets)
					var context: String = "%s %s %s state %d" % [dimensions, locale, insets, state]
					for path: String in ["Title", "ModeGrid", "BoostStrip", "BackButton"]:
						_inside(screen.get_node(CENTER + "/" + path), _safe_rect(screen), context + path)
					_check_tiles(screen, context)
					_check_chips(screen, context)
					assert_eq(Economy._data.to_dict(), before, "layout does not mutate inventory/save")
					screen.get_parent().free()


func _check_tiles(screen: Control, context: String) -> void:
	var grid: Control = screen.get_node(CENTER + "/ModeGrid")
	for row: String in ROWS:
		var button: Button = grid.get_node(row + "/Button")
		_inside(button, grid.get_global_rect(), context + row)
		for child: String in ["Art", "ModeLabel", "Desc"]:
			var item: Control = button.get_node("Content/" + child)
			_inside(item, button.get_global_rect(), context + row + child)
			if item is Label:
				assert_lte(item.get_minimum_size().x, item.size.x + 0.1, context + " label width")
				assert_lte(item.get_minimum_size().y, item.size.y + 0.1, context + " label height")
		var art: Control = button.get_node("Content/Art")
		assert_almost_eq(art.size.x / art.size.y, 1.75, 0.001, "art aspect is preserved")
		assert_gte(button.size.y, 108.0)


func _check_chips(screen: Control, context: String) -> void:
	var rail: HBoxContainer = screen.get_node(CENTER + "/BoostStrip/Boosts")
	assert_eq(rail.get_child_count(), 3)
	for chip: BoostLoadoutChip in rail.get_children():
		_inside(chip, _safe_rect(screen), context + " chip")
		for child: String in ["Content/Icon", "Content/Name", "Content/Count"]:
			var item: Control = chip.get_node(child)
			_inside(item, chip.get_global_rect(), context + " chip " + child)
		assert_eq(chip.disabled, Economy.boost_count(chip.boost_id) == 0)
		assert_eq(chip.button_pressed, Economy.is_boost_armed(chip.boost_id))
		assert_eq(chip._marker.visible, chip.button_pressed)
		assert_gte(chip.size.x * 320.0 / 720.0, 48.0)
		assert_gte(chip.size.y * 320.0 / 720.0, 48.0)


func test_mode_buttons_dispatch_immediately_once_without_extra_confirm() -> void:
	var screen: RecordingModeSelect = await _mount(Vector2i(720, 1280), Vector4i.ZERO, true)
	var grid: Control = screen.get_node(CENTER + "/ModeGrid")
	for row: String in ["DailyRow", "FreeRow", "LevelRow"]:
		grid.get_node(row + "/Button").pressed.emit()
	assert_eq(screen.launches, [SeedManager.Mode.DAILY, SeedManager.Mode.FREE, SeedManager.Mode.LEVEL_ENDLESS])
	grid.get_node("CampaignRow/Button").pressed.emit()
	assert_eq(screen.campaign_requests, 1)
	assert_true(screen.get_node(CENTER + "/BackButton").pressed.get_connections().size() > 0)
	assert_eq(screen.MENU_SCENE, "res://scenes/main/MainMenu.tscn")
	assert_eq(screen.LEVEL_SELECT_SCENE, "res://scenes/ui/LevelSelect.tscn")


func test_daily_resolution_ignores_prepared_boosts_without_consumption() -> void:
	_set_fixture(2)
	Economy._data.set_boost_armed(&"extra_life", true)
	Economy._data.set_boost_armed(&"slow_start", true)
	var snapshot: Dictionary = Economy._data.to_dict().duplicate(true)
	var armed: Dictionary = {}
	for id: StringName in Economy._data.armed_boosts:
		armed[id] = true
	assert_eq(armed.size(), 3, "all boost types are prepared")
	var result: Dictionary = BoostEffects.resolve(SeedManager.Mode.DAILY, ContentCatalog.BOOSTS,
		armed, Economy._data.boost_charges)
	assert_true(result["consume"].is_empty())
	assert_eq(result["coin_multiplier"], 1.0)
	assert_eq(result["extra_lives"], 0)
	assert_eq(result["slow_scale"], 1.0)
	assert_eq(Economy._data.to_dict(), snapshot)


func test_resize_reflows_bounded_width_and_back_touch_target() -> void:
	var screen: Control = await _mount(Vector2i(720, 1280), Vector4i.ZERO)
	var viewport: SubViewport = screen.get_parent()
	var safe: SimulatedSafeArea = screen.get_node("SafeArea")
	viewport.size = Vector2i(960, 1280)
	safe.platform_rect = Rect2(24, 96, 912, 1136)
	await wait_process_frames(5)
	var center: Control = screen.get_node(CENTER)
	assert_lte(center.size.x, 800.0)
	assert_almost_eq(center.get_global_rect().get_center().x, 480.0, 0.1)
	_inside(center, _safe_rect(screen), "resized center")
	var back: Button = screen.get_node(CENTER + "/BackButton")
	assert_gte(back.size.y * 320.0 / 720.0, 48.0)
