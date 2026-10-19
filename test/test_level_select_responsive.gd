extends GutTest

## Real route/scroll bounds with isolated profiles; no progression or save mutations.
const SCENE: PackedScene = preload("res://scenes/ui/LevelSelect.tscn")
const CENTER: String = "SafeArea/Bounds/Center"
const SIZES: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1440), Vector2i(720, 1560),
	Vector2i(720, 1600), Vector2i(720, 1680), Vector2i(960, 1280), Vector2i(640, 1280)]
var _original: Variant
var _pending: int


class SimulatedSafeArea:
	extends SafeAreaMargin
	var platform_rect: Rect2


	func _get_display_safe_area() -> Rect2:
		return platform_rect


	func _get_local_to_display() -> Transform2D:
		return Transform2D.IDENTITY


class RecordingLevelSelect:
	extends "res://scripts/ui/level_select.gd"
	var picks: Array[int] = []


	func _on_pick(index: int) -> void:
		picks.append(index)


func before_each() -> void:
	_original = Economy._data
	_pending = Economy._pending_unlock
	_progress(2)


func after_each() -> void:
	Economy._data = _original
	Economy._pending_unlock = _pending
	TranslationServer.set_locale("en")


func _progress(completed: int) -> void:
	var fixture := SaveData.new_default()
	for index: int in completed:
		fixture.set_campaign_star(ContentCatalog.LEVELS[index].id, 3 - index % 3)
	Economy._data = fixture
	Economy._pending_unlock = -1


func _mount(dimensions: Vector2i, insets: Vector4i, record: bool = false) -> Control:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var screen: Control = SCENE.instantiate()
	if record:
		screen.set_script(RecordingLevelSelect)
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
	await wait_process_frames(8)
	return screen


func _safe_rect(screen: Control) -> Rect2:
	var safe: SafeAreaMargin = screen.get_node("SafeArea")
	var margin: Vector4i = safe.safe_insets() + safe.content_padding
	return Rect2(Vector2(margin.x, margin.y), screen.size - Vector2(margin.x + margin.z, margin.y + margin.w))


func _inside(actual: Rect2, rect: Rect2, context: String) -> void:
	assert_true(actual.position.x >= rect.position.x - 0.1 and actual.position.y >= rect.position.y - 0.1
		and actual.end.x <= rect.end.x + 0.1 and actual.end.y <= rect.end.y + 0.1,
		"%s: %s within %s" % [context, actual, rect])


func test_six_aspects_locales_insets_and_progress_states() -> void:
	for dimensions: Vector2i in SIZES:
		for locale: String in ["en", "tr"]:
			TranslationServer.set_locale(locale)
			for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
				for completed: int in [2, ContentCatalog.LEVELS.size() - 1]:
					_progress(completed)
					var snapshot: Dictionary = Economy._data.to_dict().duplicate(true)
					var screen: Control = await _mount(dimensions, insets)
					var context: String = "%s %s %s completed %d" % [dimensions, locale, insets, completed]
					for path: String in ["Title", "Scroll", "BackButton"]:
						_inside(screen.get_node(CENTER + "/" + path).get_global_rect(), _safe_rect(screen), context + path)
					_check_route(screen, context)
					assert_eq(Economy._data.to_dict(), snapshot)
					screen.get_parent().free()


func _check_route(screen: Control, context: String) -> void:
	var canvas: Control = screen.get_node(CENTER + "/Scroll/PathCanvas")
	var scroll: ScrollContainer = screen.get_node(CENTER + "/Scroll")
	assert_eq(screen._nodes.size(), ContentCatalog.LEVELS.size())
	assert_gt(canvas.size.y, scroll.size.y)
	for index: int in screen._nodes.size():
		var node: Button = screen._nodes[index]
		var metadata: Label = screen._metadata[index]
		_inside(node.get_rect().grow(screen._animation_padding()), Rect2(Vector2.ZERO, canvas.size), context + " glow")
		_inside(metadata.get_rect(), Rect2(Vector2.ZERO, canvas.size), context + " metadata")
		assert_lte(metadata.get_minimum_size().y, metadata.size.y + 0.1)
		assert_false(metadata.get_rect().intersects(node.get_rect().grow(screen._animation_padding())))
		assert_eq(node.disabled, not Economy.is_level_unlocked(index))
		if not node.disabled:
			var lines: PackedStringArray = metadata.text.split("\n")
			assert_eq(lines[0], "%s %d" % [tr("LEVEL_LABEL"), index + 1])
			assert_eq(lines[1], "★".repeat(Economy.campaign_star(ContentCatalog.LEVELS[index].id))
				+ "☆".repeat(3 - Economy.campaign_star(ContentCatalog.LEVELS[index].id)))
			assert_true(metadata.text.contains(tr(ContentCatalog.LEVELS[index].description_key).replace(" • ", "\n")))
		assert_gte(node.size.x * 320.0 / 720.0, 48.0)
		assert_gte(node.size.y * 320.0 / 720.0, 48.0)
		if index > 0:
			assert_gte(screen._focus_regions[index].position.y, screen._focus_regions[index - 1].end.y)
		var mirrored: float = canvas.size.x * 0.5 + (screen.X_OFFSET if index % 2 == 1 else -screen.X_OFFSET)
		assert_almost_eq(node.get_rect().get_center().x, mirrored, 0.1)
	assert_false(scroll.get_global_rect().intersects(screen.get_node(CENTER + "/BackButton").get_global_rect()))


func test_first_middle_last_rows_are_fully_reachable_on_each_aspect() -> void:
	_progress(ContentCatalog.LEVELS.size() - 1)
	for dimensions: Vector2i in SIZES:
		var screen: Control = await _mount(dimensions, Vector4i(24, 96, 24, 48))
		var scroll: ScrollContainer = screen.get_node(CENTER + "/Scroll")
		for index: int in [0, ContentCatalog.LEVELS.size() / 2, ContentCatalog.LEVELS.size() - 1]:
			screen._focus_checkpoint(screen._nodes[index])
			await wait_process_frames(2)
			var region: Rect2 = screen._focus_regions[index]
			var canvas: Control = screen.get_node(CENTER + "/Scroll/PathCanvas")
			_inside(Rect2(canvas.global_position + region.position, region.size), scroll.get_global_rect(), "focused complete row")
		assert_gte(screen.get_node(CENTER + "/BackButton").size.y * 320.0 / 720.0, 48.0)
		screen.get_parent().free()


func test_unlock_animation_auto_scroll_envelope_and_idle_style_restoration() -> void:
	_progress(8)
	Economy._pending_unlock = 8
	var screen: Control = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48))
	assert_eq(Economy._pending_unlock, -1, "existing pending unlock is consumed once")
	var node: Button = screen._nodes[8]
	var idle: StyleBox = node.get_meta("route_idle_style")
	await wait_seconds(0.35)
	var scroll: ScrollContainer = screen.get_node(CENTER + "/Scroll")
	var canvas: Control = screen.get_node(CENTER + "/Scroll/PathCanvas")
	var region: Rect2 = screen._focus_regions[8]
	_inside(Rect2(canvas.global_position + region.position, region.size), scroll.get_global_rect(), "auto focus includes metadata/glow")
	for tick: int in 8:
		var visual: Rect2 = node.get_global_rect().grow(screen.unlock_glow_size)
		_inside(visual, scroll.get_global_rect(), "animation/glow remains visible")
		await wait_seconds(0.05)
	await wait_seconds(0.65)
	assert_eq(node.get_theme_stylebox("normal"), idle, "animation restores original frontier style")
	assert_eq(node.get_theme_stylebox("hover"), idle)
	assert_eq(node.scale, Vector2.ONE)


func test_unlocked_locked_completed_and_selected_navigation_states() -> void:
	var screen: RecordingLevelSelect = await _mount(Vector2i(720, 1280), Vector4i.ZERO, true)
	var completed: Button = screen._nodes[0]
	var frontier: Button = screen._nodes[2]
	var locked: Button = screen._nodes[3]
	completed.pressed.emit()
	frontier.pressed.emit()
	locked.pressed.emit()
	assert_eq(screen.picks, [0, 2], "only playable checkpoints dispatch catalog indexes")
	assert_true(locked.disabled)
	frontier.grab_focus()
	assert_eq(frontier.get_viewport().gui_get_focus_owner(), frontier)
	assert_eq(frontier.get_theme_stylebox("focus").border_width_left, 3)
	assert_true(screen._metadata[0].text.contains("★★★"))
	assert_eq(screen.MODE_SELECT_SCENE, "res://scenes/ui/ModeSelect.tscn")
	assert_eq(screen.GAME_SCENE, "res://scenes/main/Game.tscn")
	assert_eq(screen.get_node(CENTER + "/BackButton").pressed.get_connections().size(), 1)


func test_resize_recenters_route_and_preserves_profile() -> void:
	var screen: Control = await _mount(Vector2i(720, 1280), Vector4i.ZERO)
	var profile: Dictionary = Economy._data.to_dict().duplicate(true)
	var viewport: SubViewport = screen.get_parent()
	var safe: SimulatedSafeArea = screen.get_node("SafeArea")
	viewport.size = Vector2i(960, 1280)
	safe.platform_rect = Rect2(24, 96, 912, 1136)
	await wait_process_frames(8)
	var center: Control = screen.get_node(CENTER)
	assert_lte(center.size.x, 800.0)
	assert_almost_eq(center.get_global_rect().get_center().x, 480.0, 0.1)
	_check_route(screen, "resized tablet")
	assert_eq(Economy._data.to_dict(), profile)


func test_b1_long_campaign_descriptions_fit_360_by_640() -> void:
	for locale: String in ["ru", "id", "vi", "pl"]:
		TranslationServer.set_locale(locale)
		LocaleFonts.apply(locale)
		_progress(ContentCatalog.LEVELS.size() - 1)
		var screen: Control = await _mount(Vector2i(360, 640), Vector4i(12, 32, 12, 24))
		_check_route(screen, "B1 campaign 360x640 " + locale)
		screen.get_parent().free()
