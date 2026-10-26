extends GutTest

# Preloads keep the schemes resolvable under GUT's isolated loader.
const TapTurnControl = preload("res://scripts/gameplay/controls/tap_turn_control.gd")
const SwipeControl = preload("res://scripts/gameplay/controls/swipe_control.gd")
const DpadControl = preload("res://scripts/gameplay/controls/dpad_control.gd")


func test_tap_rotate_clockwise() -> void:
	assert_eq(TapTurnControl.rotate(Vector2i.RIGHT, 1), Vector2i.DOWN)
	assert_eq(TapTurnControl.rotate(Vector2i.DOWN, 1), Vector2i.LEFT)
	assert_eq(TapTurnControl.rotate(Vector2i.LEFT, 1), Vector2i.UP)
	assert_eq(TapTurnControl.rotate(Vector2i.UP, 1), Vector2i.RIGHT)


func test_tap_rotate_counter_clockwise() -> void:
	assert_eq(TapTurnControl.rotate(Vector2i.RIGHT, -1), Vector2i.UP)
	assert_eq(TapTurnControl.rotate(Vector2i.UP, -1), Vector2i.LEFT)
	assert_eq(TapTurnControl.rotate(Vector2i.LEFT, -1), Vector2i.DOWN)
	assert_eq(TapTurnControl.rotate(Vector2i.DOWN, -1), Vector2i.RIGHT)


func test_tap_rotate_zero_base_defaults_right() -> void:
	assert_eq(TapTurnControl.rotate(Vector2i.ZERO, 1), Vector2i.DOWN)
	assert_eq(TapTurnControl.rotate(Vector2i.ZERO, -1), Vector2i.UP)


func test_swipe_dominant_axis() -> void:
	assert_eq(SwipeControl.vector_to_dir(Vector2(40, 5), 24.0), Vector2i.RIGHT)
	assert_eq(SwipeControl.vector_to_dir(Vector2(-40, 5), 24.0), Vector2i.LEFT)
	assert_eq(SwipeControl.vector_to_dir(Vector2(5, 40), 24.0), Vector2i.DOWN)
	assert_eq(SwipeControl.vector_to_dir(Vector2(5, -40), 24.0), Vector2i.UP)


func test_swipe_below_threshold_is_zero() -> void:
	assert_eq(SwipeControl.vector_to_dir(Vector2(5, 5), 24.0), Vector2i.ZERO)


func test_swipe_diagonal_tiebreak_horizontal() -> void:
	assert_eq(SwipeControl.vector_to_dir(Vector2(30, 30), 24.0), Vector2i.RIGHT)


func test_dpad_directions_from_center() -> void:
	var c := Vector2(360, 1080)
	assert_eq(DpadControl.pos_to_dir(c + Vector2(50, 0), c, 18.0), Vector2i.RIGHT)
	assert_eq(DpadControl.pos_to_dir(c + Vector2(-50, 0), c, 18.0), Vector2i.LEFT)
	assert_eq(DpadControl.pos_to_dir(c + Vector2(0, 50), c, 18.0), Vector2i.DOWN)
	assert_eq(DpadControl.pos_to_dir(c + Vector2(0, -50), c, 18.0), Vector2i.UP)


func test_dpad_dead_zone_is_zero() -> void:
	var c := Vector2(360, 1080)
	assert_eq(DpadControl.pos_to_dir(c + Vector2(5, 5), c, 18.0), Vector2i.ZERO)


func test_dpad_touch_origin_at_different_screen_positions() -> void:
	for origin: Vector2 in [Vector2(20, 110), Vector2(690, 180), Vector2(360, 640), Vector2(15, 1240)]:
		var pad: DpadControl = DpadControl.new()
		pad.handle_input(_touch(2, origin, true), Vector2(720, 1280))
		assert_eq(pad.touch_origin, origin)
		assert_eq(pad.poll(Vector2(720, 1280), Vector2i.RIGHT), Vector2i.ZERO)
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			pad.handle_input(_drag(2, origin + Vector2(direction) * 50), Vector2(720, 1280))
			assert_eq(pad.poll(Vector2(720, 1280), Vector2i.ZERO), direction)
		assert_false(pad.auto_advance)


func test_dpad_dead_zone_stops_and_resume_requires_drag() -> void:
	var pad: DpadControl = DpadControl.new()
	pad.handle_input(_touch(0, Vector2(200, 300), true), Vector2(720, 1280))
	pad.handle_input(_drag(0, Vector2(250, 300)), Vector2(720, 1280))
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.ZERO), Vector2i.RIGHT)
	pad.handle_input(_drag(0, Vector2(218, 300)), Vector2(720, 1280))
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.RIGHT), Vector2i.ZERO)
	pad.handle_input(_drag(0, Vector2(200, 300)), Vector2(720, 1280))
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.RIGHT), Vector2i.ZERO)
	pad.handle_input(_drag(0, Vector2(200, 250)), Vector2(720, 1280))
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.ZERO), Vector2i.UP)


func test_dpad_tracks_owner_and_never_hands_off_to_second_finger() -> void:
	var pad: DpadControl = DpadControl.new()
	pad.handle_input(_touch(4, Vector2(200, 300), true), Vector2(720, 1280))
	pad.handle_input(_drag(4, Vector2(250, 300)), Vector2(720, 1280))
	pad.handle_input(_touch(9, Vector2(500, 700), true), Vector2(720, 1280))
	pad.handle_input(_drag(9, Vector2(500, 800)), Vector2(720, 1280))
	pad.handle_input(_touch(9, Vector2(500, 800), false), Vector2(720, 1280))
	assert_eq(pad.touch_origin, Vector2(200, 300))
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.ZERO), Vector2i.RIGHT)
	pad.handle_input(_touch(9, Vector2(500, 700), true), Vector2(720, 1280))
	pad.handle_input(_touch(4, Vector2(250, 300), false), Vector2(720, 1280))
	assert_false(pad.is_held())
	pad.handle_input(_drag(9, Vector2(500, 800)), Vector2(720, 1280))
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.RIGHT), Vector2i.ZERO)


func test_dpad_cancel_reset_and_outside_press() -> void:
	var pad: DpadControl = DpadControl.new()
	pad.handle_input(_touch(0, Vector2(-10, 20), true), Vector2(720, 1280))
	assert_false(pad.is_held())
	pad.handle_input(_drag(0, Vector2(200, 300)), Vector2(720, 1280))
	assert_false(pad.is_held())
	pad.handle_input(_touch(0, Vector2(200, 300), true), Vector2(720, 1280))
	var cancel: InputEventScreenTouch = _touch(0, Vector2(200, 300), false)
	cancel.canceled = true
	pad.handle_input(cancel, Vector2(720, 1280))
	assert_false(pad.is_held())
	pad.handle_input(_touch(7, Vector2(600, 900), true), Vector2(720, 1280))
	assert_eq(pad.touch_origin, Vector2(600, 900))
	pad.reset()
	assert_false(pad.is_held())
	assert_eq(pad.poll(Vector2.ZERO, Vector2i.RIGHT), Vector2i.ZERO)


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
