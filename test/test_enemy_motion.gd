extends GutTest

## Pure enemy motion math (EnemyMotion). Here: even_spread used for per-enemy variation.

const EnemyMotion = preload("res://scripts/gameplay/enemy_motion.gd")


func test_even_spread_single_is_zero() -> void:
	assert_eq(EnemyMotion.even_spread(0, 1), 0.0)


func test_even_spread_three_spans_minus_one_to_one() -> void:
	assert_almost_eq(EnemyMotion.even_spread(0, 3), -1.0, 0.0001)
	assert_almost_eq(EnemyMotion.even_spread(1, 3), 0.0, 0.0001)
	assert_almost_eq(EnemyMotion.even_spread(2, 3), 1.0, 0.0001)


func test_even_spread_values_are_distinct() -> void:
	var seen := {}
	for i in 5:
		var v: float = EnemyMotion.even_spread(i, 5)
		assert_false(seen.has(v), "each index -> distinct variation")
		seen[v] = true


func test_turn_helpers_are_cardinal_rotations() -> void:
	assert_eq(EnemyMotion.turn_right(Vector2i.RIGHT), Vector2i.DOWN)
	assert_eq(EnemyMotion.turn_right(Vector2i.DOWN), Vector2i.LEFT)
	assert_eq(EnemyMotion.turn_left(Vector2i.DOWN), Vector2i.RIGHT)
	assert_eq(EnemyMotion.turn_left(Vector2i.RIGHT), Vector2i.UP)


func test_wall_follow_straight_along_wall() -> void:
	# Heading DOWN, wall on the right (right blocked), front open -> keep going DOWN.
	assert_eq(EnemyMotion.wall_follow_turn(Vector2i.DOWN, false, true, false), Vector2i.DOWN)


func test_wall_follow_convex_corner_turns_right() -> void:
	# Wall ends -> right opens -> turn right (hug the wall around the corner).
	assert_eq(EnemyMotion.wall_follow_turn(Vector2i.DOWN, true, true, true), Vector2i.LEFT)


func test_wall_follow_concave_corner_turns_left() -> void:
	# Right + front blocked, left open -> turn left.
	assert_eq(EnemyMotion.wall_follow_turn(Vector2i.DOWN, false, false, true), Vector2i.RIGHT)


func test_wall_follow_dead_end_reverses() -> void:
	assert_eq(EnemyMotion.wall_follow_turn(Vector2i.DOWN, false, false, false), Vector2i.UP)
