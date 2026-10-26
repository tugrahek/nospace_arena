extends GutTest

## Real viewport event routing; assertions cover input ownership, not visual taste.
var _viewport: SubViewport
var _player: Player
var _old_status: int


func before_each() -> void:
	_old_status = GameState.status
	GameState.status = GameState.Status.PLAYING
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(720, 1280)
	add_child_autofree(_viewport)
	_player = Player.new()
	_viewport.add_child(_player)
	_player.set_process(false)
	_player.set_scheme(Player.SchemeId.DPAD)
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	GameState.status = _old_status


func test_unhandled_start_and_owned_release_over_hud() -> void:
	var button: Button = Button.new()
	button.position = Vector2(400, 300)
	button.size = Vector2(120, 90)
	_viewport.add_child(button)
	await get_tree().process_frame
	_viewport.push_input(_touch(0, Vector2(200, 300), true), true)
	_viewport.push_input(_drag(0, Vector2(450, 330)), true)
	_player._update_intent()
	assert_eq(_player._queued_dir, Vector2i.RIGHT)
	_viewport.push_input(_touch(0, Vector2(450, 330), false), true)
	_player._update_intent()
	assert_eq(_player._direction, Vector2i.ZERO)
	assert_eq(_player._queued_dir, Vector2i.ZERO)
	assert_false(_player._scheme.is_held())


func test_interactive_hud_press_cannot_start_or_become_drag() -> void:
	var button: Button = Button.new()
	button.position = Vector2(400, 300)
	button.size = Vector2(120, 90)
	_viewport.add_child(button)
	await get_tree().process_frame
	_viewport.push_input(_touch(3, Vector2(450, 330), true), true)
	_viewport.push_input(_drag(3, Vector2(200, 330)), true)
	assert_false(_player._scheme.is_held())
	_player._update_intent()
	assert_eq(_player._queued_dir, Vector2i.ZERO)


func test_actual_game_hud_and_screen_wide_empty_regions() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/HUD.tscn").instantiate()
	var pause: CanvasLayer = load("res://scenes/ui/PauseOverlay.tscn").instantiate()
	_viewport.add_child(hud)
	_viewport.add_child(pause)
	await get_tree().process_frame
	await get_tree().process_frame
	for origin: Vector2 in [Vector2(20, 200), Vector2(690, 200), Vector2(350, 640), Vector2(350, 1200)]:
		_viewport.push_input(_touch(0, origin, true), true)
		assert_true(_player._scheme.is_held(), str(origin))
		assert_eq(_player._scheme.touch_origin, origin)
		_viewport.push_input(_touch(0, origin, false), true)
	var button: Button = pause.get_node("PauseSafeArea/Bounds/PauseButton")
	_viewport.push_input(_touch(0, button.get_global_rect().get_center(), true), true)
	assert_false(_player._scheme.is_held(), "Pause must not own a movement gesture")


func test_switching_scheme_discards_old_owner_and_visual() -> void:
	watch_signals(_player)
	_viewport.push_input(_touch(2, Vector2(220, 400), true), true)
	_viewport.push_input(_drag(2, Vector2(280, 400)), true)
	var previous: ControlScheme = _player._scheme
	_player.set_scheme(Player.SchemeId.SWIPE)
	assert_false(previous.is_held())
	assert_true(_player._scheme.auto_advance)
	assert_signal_emitted_with_parameters(_player, "dpad_gesture_changed", [false, Vector2.ZERO])
	_player.set_scheme(Player.SchemeId.DPAD)
	_viewport.push_input(_drag(2, Vector2(350, 400)), true)
	assert_false(_player._scheme.is_held())
	_player._update_intent()
	assert_eq(_player._queued_dir, Vector2i.ZERO)
	assert_eq(_player._direction, Vector2i.ZERO)


func test_pause_cancels_held_input_before_resume() -> void:
	_viewport.push_input(_touch(0, Vector2(220, 400), true), true)
	_viewport.push_input(_drag(0, Vector2(280, 400)), true)
	assert_true(_player._scheme.is_held())
	get_tree().paused = true
	assert_false(_player._scheme.is_held())
	get_tree().paused = false
	_player._update_intent()
	assert_eq(_player._queued_dir, Vector2i.ZERO)
	assert_eq(_player._direction, Vector2i.ZERO)


func test_inactive_run_rejects_touch() -> void:
	GameState.status = GameState.Status.GAME_OVER
	_viewport.push_input(_touch(0, Vector2(220, 400), true), true)
	assert_false(_player._scheme.is_held())


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event
