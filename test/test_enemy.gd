extends GutTest

# enemy_motion.gd is dependency-free, so it's safe under GUT's isolated loader.
const EnemyMotion = preload("res://scripts/gameplay/enemy_motion.gd")


func test_reflect_x() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), true, false), Vector2(-3, 4))


func test_reflect_y() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), false, true), Vector2(3, -4))


func test_reflect_both() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), true, true), Vector2(-3, -4))


func test_reflect_none() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), false, false), Vector2(3, 4))


func test_start_velocity_magnitude() -> void:
	assert_almost_eq(EnemyMotion.start_velocity(0, 100.0).length(), 100.0, 0.001)


func test_start_velocity_varies_by_index() -> void:
	assert_ne(EnemyMotion.start_velocity(0, 100.0), EnemyMotion.start_velocity(1, 100.0))


func test_start_velocity_deterministic() -> void:
	assert_eq(EnemyMotion.start_velocity(2, 100.0), EnemyMotion.start_velocity(2, 100.0))


# --- clamp_to_wall (radius-aware bounce: body never overlaps captured) ---

func test_clamp_positive_pulls_body_off_wall() -> void:
	# Moving +, center 92, wall 100, radius 9 -> clamp to 91 (body edge exactly at wall)
	assert_almost_eq(EnemyMotion.clamp_to_wall(92.0, 100.0, 9.0, 1.0), 91.0, 0.0001)


func test_clamp_positive_leaves_safe_center() -> void:
	# Already > radius from wall -> unchanged
	assert_eq(EnemyMotion.clamp_to_wall(50.0, 100.0, 9.0, 1.0), 50.0)


func test_clamp_negative_pulls_body_off_wall() -> void:
	# Moving -, center 22, wall 20, radius 9 -> clamp to 29
	assert_almost_eq(EnemyMotion.clamp_to_wall(22.0, 20.0, 9.0, -1.0), 29.0, 0.0001)


func test_clamp_negative_leaves_safe_center() -> void:
	assert_eq(EnemyMotion.clamp_to_wall(80.0, 20.0, 9.0, -1.0), 80.0)


func test_clamp_guarantees_radius_gap() -> void:
	# After clamp, center-to-wall distance is at least radius (body doesn't overlap)
	var c: float = EnemyMotion.clamp_to_wall(98.0, 100.0, 9.0, 1.0)
	assert_true(100.0 - c >= 9.0, "gövde duvara binmemeli")
