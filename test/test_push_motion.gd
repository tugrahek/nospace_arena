extends GutTest

# push_motion.gd is dependency-free, so it's safe under GUT's isolated loader.
const PushMotion = preload("res://scripts/gameplay/push_motion.gd")


func test_strength_max_at_edge() -> void:
	assert_almost_eq(PushMotion.strength_for(0.0, 80.0), 1.0, 0.0001)


func test_strength_half_at_mid() -> void:
	assert_almost_eq(PushMotion.strength_for(40.0, 80.0), 0.5, 0.0001)


func test_strength_zero_at_radius() -> void:
	assert_eq(PushMotion.strength_for(80.0, 80.0), 0.0)


func test_strength_zero_beyond_radius() -> void:
	assert_eq(PushMotion.strength_for(100.0, 80.0), 0.0)


func test_strength_guards_nonpositive_radius() -> void:
	assert_eq(PushMotion.strength_for(10.0, 0.0), 0.0)


func test_steer_preserves_magnitude() -> void:
	var out: Vector2 = PushMotion.steer(Vector2(100, 0), Vector2(0, -1), 1.0, deg_to_rad(8.0))
	assert_almost_eq(out.length(), 100.0, 0.001, "hız büyüklüğü korunmalı")


func test_steer_zero_strength_unchanged() -> void:
	var v := Vector2(100, 0)
	assert_eq(PushMotion.steer(v, Vector2(0, -1), 0.0, deg_to_rad(8.0)), v)


func test_steer_turns_toward_away_dir() -> void:
	# Heading right, repelled upward (-y): result should tilt upward (y < 0).
	var out: Vector2 = PushMotion.steer(Vector2(100, 0), Vector2(0, -1), 1.0, deg_to_rad(8.0))
	assert_lt(out.y, 0.0, "yön away_dir'e (yukarı) doğru dönmeli")


func test_steer_zero_velocity_unchanged() -> void:
	assert_eq(PushMotion.steer(Vector2.ZERO, Vector2(0, -1), 1.0, deg_to_rad(8.0)), Vector2.ZERO)
