extends GutTest

# territory_motion.gd is dependency-free, so it's safe under GUT's isolated loader.
const TerritoryMotion = preload("res://scripts/gameplay/territory_motion.gd")


# --- strength_for (push gradient) ---

func test_strength_max_at_edge() -> void:
	assert_almost_eq(TerritoryMotion.strength_for(0.0, 80.0), 1.0, 0.0001)


func test_strength_half_at_mid() -> void:
	assert_almost_eq(TerritoryMotion.strength_for(40.0, 80.0), 0.5, 0.0001)


func test_strength_zero_at_radius() -> void:
	assert_eq(TerritoryMotion.strength_for(80.0, 80.0), 0.0)


func test_strength_zero_beyond_radius() -> void:
	assert_eq(TerritoryMotion.strength_for(100.0, 80.0), 0.0)


func test_strength_guards_nonpositive_radius() -> void:
	assert_eq(TerritoryMotion.strength_for(10.0, 0.0), 0.0)


# --- steer (push heading change) ---

func test_steer_preserves_magnitude() -> void:
	var out: Vector2 = TerritoryMotion.steer(Vector2(100, 0), Vector2(0, -1), 1.0, deg_to_rad(8.0))
	assert_almost_eq(out.length(), 100.0, 0.001, "hız büyüklüğü korunmalı")


func test_steer_zero_strength_unchanged() -> void:
	var v := Vector2(100, 0)
	assert_eq(TerritoryMotion.steer(v, Vector2(0, -1), 0.0, deg_to_rad(8.0)), v)


func test_steer_turns_toward_target() -> void:
	# Heading right, target upward (-y): result should tilt upward (y < 0).
	var out: Vector2 = TerritoryMotion.steer(Vector2(100, 0), Vector2(0, -1), 1.0, deg_to_rad(8.0))
	assert_lt(out.y, 0.0, "yön target_dir'e (yukarı) doğru dönmeli")


func test_steer_zero_velocity_unchanged() -> void:
	assert_eq(TerritoryMotion.steer(Vector2.ZERO, Vector2(0, -1), 1.0, deg_to_rad(8.0)), Vector2.ZERO)


# --- scale_for (slow gradient) ---

func test_scale_max_slow_at_edge() -> void:
	assert_almost_eq(TerritoryMotion.scale_for(0.0, 80.0, 0.7), 0.3, 0.0001)


func test_scale_none_at_radius() -> void:
	assert_eq(TerritoryMotion.scale_for(80.0, 80.0, 0.7), 1.0)


func test_scale_mid() -> void:
	assert_almost_eq(TerritoryMotion.scale_for(40.0, 80.0, 0.7), 0.65, 0.0001)


func test_scale_guards_nonpositive_radius() -> void:
	assert_eq(TerritoryMotion.scale_for(10.0, 0.0, 0.7), 1.0)


func test_scale_factor_zero_is_no_slow() -> void:
	assert_almost_eq(TerritoryMotion.scale_for(0.0, 80.0, 0.0), 1.0, 0.0001)


# --- slow_scale (Drag floor) ---

func test_slow_scale_floors_at_min() -> void:
	# core gradient 0.3 floored to min_scale 0.40
	assert_almost_eq(TerritoryMotion.slow_scale(0.0, 80.0, 0.7, 0.40), 0.40, 0.0001)


func test_slow_scale_above_floor_unchanged() -> void:
	# mid gradient 0.725 stays above floor
	assert_almost_eq(TerritoryMotion.slow_scale(40.0, 80.0, 0.55, 0.40), 0.725, 0.0001)


func test_slow_scale_never_below_min() -> void:
	# even strong factor cannot dip below the floor
	assert_almost_eq(TerritoryMotion.slow_scale(0.0, 80.0, 0.9, 0.40), 0.40, 0.0001)


func test_slow_scale_no_slow_at_radius() -> void:
	assert_almost_eq(TerritoryMotion.slow_scale(80.0, 80.0, 0.55, 0.40), 1.0, 0.0001)


