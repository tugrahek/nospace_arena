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


func test_dpad_center_is_bottom_center() -> void:
	var c := DpadControl.center(Vector2(720, 1280))
	assert_eq(c.x, 360.0)
	assert_almost_eq(c.y, 1280.0 - DpadControl.MARGIN_BOTTOM, 0.001)
