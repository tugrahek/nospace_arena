extends GutTest

## Actual root-window canvas stretch, with explicit Android densityDpi simulations.
const Sizing = preload("res://scripts/ui/touch_target_sizing.gd")
const LanguageSelector = preload("res://scripts/ui/settings_language_selector.gd")
var _original_data: Variant
var _window_state: Dictionary
var _screens: Array[Node] = []

class SimulatedSafeArea:
	extends SafeAreaMargin
	func _get_display_safe_area() -> Rect2:
		return Rect2(Vector2(24, 96), get_viewport().get_visible_rect().size - Vector2(48, 144))
	func _get_local_to_display() -> Transform2D:
		return Transform2D.IDENTITY

func before_each() -> void:
	_original_data = Economy._data
	var fixture := SaveData.new_default()
	fixture.tutorial_seen = true
	Economy._data = fixture
	var window: Window = get_tree().root
	_window_state = {"size": window.size, "content_scale_size": window.content_scale_size,
		"content_scale_mode": window.content_scale_mode, "content_scale_aspect": window.content_scale_aspect}
	TranslationServer.set_locale("tr")
	_screens.clear()

func after_each() -> void:
	for screen: Node in _screens:
		if is_instance_valid(screen):
			screen.free()
	var window: Window = get_tree().root
	for key: String in _window_state:
		window.set(key, _window_state[key])
	Economy._data = _original_data
	TranslationServer.set_locale("en")

func _profile(size_px: Vector2i) -> void:
	var window: Window = get_tree().root
	window.content_scale_size = Vector2i(720, 1280)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size = size_px
	await wait_process_frames(5)

func _mount_screens() -> Array[Button]:
	for name: String in ["HowToPlay", "PauseOverlay", "HUD", "Settings", "Credits", "Missions", "Leaderboard"]:
		var screen: Node = load("res://scenes/ui/%s.tscn" % name).instantiate()
		_prepare_safe_area(screen)
		add_child(screen)
		_screens.append(screen)
	var language := LanguageSelector.new()
	add_child(language)
	_screens.append(language)
	_screens[0]._show(1)
	_screens[1].get_node("Overlay").visible = true
	var hud: HUD = _screens[2]
	hud._result_panel.visible = true
	hud._last_percent = 78.0
	hud._result_title.text = tr("RESULT_WIN")
	hud._show_result_data(2300, true)
	hud._next_button.visible = true
	hud._stars_label.text = "★★★"
	hud._stars_label.visible = true
	hud._new_best_label.visible = true
	hud._result_content.get_node("RewardedBonusButton").visible = true
	var bonus: Button = hud._result_content.get_node("RewardedBonusButton")
	bonus.get_node("Content/ActionLabel").text = (tr("RESULT_REWARDED_BONUS") % 50).split("+")[0].strip_edges()
	bonus.get_node("Content/Reward/Amount").text = "+50"
	_screens[3]._privacy.visible = true
	await wait_process_frames(8)
	var targets: Array[Button] = []
	targets.append_array([_screens[0]._close, _screens[0]._prev, _screens[0]._next])
	targets.append_array([_screens[1]._pause_button, _screens[1]._resume_button,
		_screens[1]._settings_button, _screens[1]._restart_button, _screens[1]._menu_button])
	targets.append_array([hud._next_button, hud._retry_button, hud._menu_button,
		hud._result_content.get_node("RewardedBonusButton")])
	targets.append_array([_screens[3]._back, _screens[3]._licenses, _screens[3]._privacy, _screens[3]._language_button])
	for index: int in [4, 5, 6]:
		targets.append(_screens[index]._back)
	targets.append_array(language._buttons)
	targets.append(language._back)
	return targets

func _prepare_safe_area(node: Node) -> void:
	if node is SafeAreaMargin:
		var padding: Vector4i = node.content_padding
		node.set_script(SimulatedSafeArea)
		node.content_padding = padding
	for child: Node in node.get_children():
		_prepare_safe_area(child)

func test_android_density_and_canvas_stretch_require_48_dp_on_both_axes() -> void:
	for profile: Dictionary in [{"px": Vector2i(720, 1280), "dpi": 360},
			{"px": Vector2i(1080, 2400), "dpi": 480}, {"px": Vector2i(1440, 2560), "dpi": 640},
			{"px": Vector2i(720, 960), "dpi": 360}, {"px": Vector2i(1080, 2400), "dpi": 420}]:
		await _profile(profile.px)
		var targets: Array[Button] = await _mount_screens()
		for button: Button in targets:
			var guard: Sizing = button.get_node("TouchTargetSizing")
			var stretch: float = minf(float(profile.px.x) / 720.0, float(profile.px.y) / 1280.0)
			assert_almost_eq(guard.pixels_per_unit().x, stretch, 0.01, "real root-window stretch")
			var before: Vector2 = Sizing.size_in_dp(button.size, guard.pixels_per_unit(), profile.dpi)
			print("TOUCH_BEFORE %s ui=%s dp=%s px=%s densityDpi=%s" % [button.name, button.size, before, profile.px, profile.dpi])
			Sizing.attach(button, profile.dpi)
		_screens[2]._fit_pause_touch_space(profile.dpi)
		await wait_process_frames(12)
		for button: Button in targets:
			var guard: Sizing = button.get_node("TouchTargetSizing")
			var dp: Vector2 = Sizing.size_in_dp(button.size, guard.pixels_per_unit(), profile.dpi)
			assert_gte(dp.x, 48.0 - 0.01, "width dp " + String(button.name))
			assert_gte(dp.y, 48.0 - 0.01, "height dp " + String(button.name))
		_check_safe_and_separate_actions()
		for screen: Node in _screens:
			screen.free()
		_screens.clear()

func _check_safe_and_separate_actions() -> void:
	var tutorial: Control = _screens[0]
	assert_true(tutorial.get_node("SafeArea/Bounds").get_global_rect().encloses(tutorial._close.get_global_rect()))
	assert_false(tutorial._prev.get_global_rect().intersects(tutorial._next.get_global_rect()))
	var pause: CanvasLayer = _screens[1]
	assert_false(pause._settings_button.get_global_rect().intersects(pause._restart_button.get_global_rect()))
	assert_false(pause._settings_button.get_global_rect().intersects(pause._menu_button.get_global_rect()))
	var hud: HUD = _screens[2]
	assert_almost_eq(hud._bonus_video.size.y, 48.0, 0.1, "video cue keeps its authored height")
	assert_eq(tutorial._close_icon.size, Vector2(64, 64), "close glyph does not grow with its hit area")
	assert_false(hud._retry_button.get_global_rect().intersects(hud._menu_button.get_global_rect()))
	assert_false(pause._pause_button.get_global_rect().intersects(hud.get_node("TopSafeArea/InfoStack").get_global_rect()))
	for button: Button in [hud._next_button, hud._retry_button, hud._menu_button, hud._result_content.get_node("RewardedBonusButton")]:
		assert_true(hud._result_bounds.get_global_rect().encloses(button.get_global_rect()), "Results action accessible")
	var settings: Control = _screens[3]
	assert_true(settings._bounds.get_global_rect().encloses(settings._bottom.get_global_rect()), "legal footer safe")
	assert_false(settings._center.get_global_rect().intersects(settings._bottom.get_global_rect()))

func test_large_dp_display_and_desktop_keep_authored_sizes() -> void:
	await _profile(Vector2i(960, 1280))
	var targets: Array[Button] = await _mount_screens()
	var original: Array[Vector2] = []
	for button: Button in targets:
		original.append(button.size)
		Sizing.attach(button, 160)
	await wait_process_frames(10)
	for index: int in targets.size():
		assert_eq(targets[index].size, original[index], "no growth when native hit area already meets 48 dp")

func test_press_scale_does_not_change_required_hit_size_or_connections() -> void:
	await _profile(Vector2i(1080, 2400))
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	add_child_autofree(button)
	var presses: Array[int] = [0]
	button.pressed.connect(func() -> void: presses[0] += 1)
	var guard: Sizing = Sizing.attach(button, 480)
	await wait_process_frames(5)
	var minimum: Vector2 = button.custom_minimum_size
	button.scale = Vector2.ONE * 1.12
	guard._queue_layout()
	await wait_process_frames(3)
	assert_eq(button.custom_minimum_size, minimum)
	button.pressed.emit()
	assert_eq(presses[0], 1)

func test_parent_scale_changes_refresh_touch_minimum_without_button_resize() -> void:
	await _profile(Vector2i(720, 1280))
	var parent := Control.new()
	add_child_autofree(parent)
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	parent.add_child(button)
	var guard: Sizing = Sizing.attach(button, 160)
	await wait_process_frames(5)
	parent.scale = Vector2(0.5, 0.75)
	await wait_process_frames(5)
	var dp: Vector2 = Sizing.size_in_dp(button.size, guard.pixels_per_unit(), 160)
	assert_gte(dp.x, 48.0, "parent scaling preserves the physical touch width")
	assert_gte(dp.y, 48.0, "parent scaling preserves the physical touch height")
	parent.scale = Vector2.ONE
	await wait_process_frames(5)
	assert_eq(button.custom_minimum_size, Vector2(64, 64), "restoring scale restores the authored minimum")
