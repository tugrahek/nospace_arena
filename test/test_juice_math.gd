extends GutTest

## Pure-logic juice tests (the visual feel is verified by Tuğra playing).

const JuiceMath = preload("res://scripts/fx/juice_math.gd")


func test_decay_clamps_to_zero() -> void:
	# 0.1 - 1.0 * 0.5 < 0 -> clamped to 0
	assert_eq(JuiceMath.decay_trauma(0.1, 1.0, 0.5), 0.0)


func test_decay_partial() -> void:
	# 1.0 - 2.0 * 0.25 = 0.5
	assert_almost_eq(JuiceMath.decay_trauma(1.0, 2.0, 0.25), 0.5, 0.0001)


func test_decay_upper_clamp() -> void:
	assert_eq(JuiceMath.decay_trauma(2.0, 0.0, 0.0), 1.0)


func test_shake_amount_quadratic() -> void:
	assert_almost_eq(JuiceMath.shake_amount(0.5), 0.25, 0.0001)


func test_shake_amount_clamped() -> void:
	assert_eq(JuiceMath.shake_amount(2.0), 1.0)
	assert_eq(JuiceMath.shake_amount(-1.0), 0.0)


func test_polyline_empty_is_inf() -> void:
	assert_eq(JuiceMath.min_distance_to_polyline(Vector2(5, 5), PackedVector2Array()), INF)


func test_polyline_single_point() -> void:
	var pts := PackedVector2Array([Vector2(0, 0)])
	assert_almost_eq(JuiceMath.min_distance_to_polyline(Vector2(3, 4), pts), 5.0, 0.0001)


func test_polyline_perpendicular_to_segment() -> void:
	# Point above the middle of a horizontal segment -> distance is the perpendicular (10).
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(20, 0)])
	assert_almost_eq(JuiceMath.min_distance_to_polyline(Vector2(10, 10), pts), 10.0, 0.0001)


func test_polyline_clamps_past_endpoint() -> void:
	# Point beyond the end -> distance to the endpoint, not the infinite line.
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	assert_almost_eq(JuiceMath.min_distance_to_polyline(Vector2(13, 4), pts), 5.0, 0.0001)


func test_polyline_picks_nearest_segment() -> void:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	# Closest to the second (vertical) segment at x=10.
	assert_almost_eq(JuiceMath.min_distance_to_polyline(Vector2(13, 5), pts), 3.0, 0.0001)


func test_danger_zero_at_or_beyond_radius() -> void:
	assert_eq(JuiceMath.danger_from_distance(64.0, 64.0), 0.0)
	assert_eq(JuiceMath.danger_from_distance(100.0, 64.0), 0.0)


func test_danger_full_at_zero_distance() -> void:
	assert_eq(JuiceMath.danger_from_distance(0.0, 64.0), 1.0)


func test_danger_midpoint_is_smoothstep_half() -> void:
	# t = 0.5 -> smoothstep(0,1,0.5) = 0.5
	assert_almost_eq(JuiceMath.danger_from_distance(32.0, 64.0), 0.5, 0.0001)


func test_danger_zero_radius_safe() -> void:
	assert_eq(JuiceMath.danger_from_distance(0.0, 0.0), 0.0)
