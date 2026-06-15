extends GutTest

# Explicit preload ensures BorderMath is resolved before GUT parses this file.
const BorderMath = preload("res://scripts/core/border_math.gd")
const RECT: Rect2 = Rect2(0.0, 0.0, 100.0, 100.0)


func test_perimeter_square() -> void:
	assert_eq(BorderMath.perimeter(RECT), 400.0)


func test_perimeter_rectangle() -> void:
	assert_eq(BorderMath.perimeter(Rect2(0.0, 0.0, 200.0, 100.0)), 600.0)


func test_position_at_t0_is_top_left() -> void:
	assert_eq(BorderMath.position_at(RECT, 0.0), Vector2(0.0, 0.0))


func test_position_at_t025_is_top_right() -> void:
	assert_eq(BorderMath.position_at(RECT, 0.25), Vector2(100.0, 0.0))


func test_position_at_t05_is_bottom_right() -> void:
	assert_eq(BorderMath.position_at(RECT, 0.5), Vector2(100.0, 100.0))


func test_position_at_t075_is_bottom_left() -> void:
	assert_eq(BorderMath.position_at(RECT, 0.75), Vector2(0.0, 100.0))


func test_position_at_t1_wraps_to_top_left() -> void:
	assert_eq(BorderMath.position_at(RECT, 1.0), Vector2(0.0, 0.0))


func test_advance_wraps_forward() -> void:
	assert_almost_eq(BorderMath.advance(0.95, 0.1), 0.05, 0.0001)


func test_advance_wraps_backward() -> void:
	assert_almost_eq(BorderMath.advance(0.05, -0.1), 0.95, 0.0001)


func test_nearest_t_top_edge_midpoint() -> void:
	# (50, 0) lies on the top edge: dist_along=50, t=50/400=0.125
	assert_almost_eq(BorderMath.nearest_t(RECT, Vector2(50.0, 0.0)), 0.125, 0.0001)


func test_nearest_t_right_edge_midpoint() -> void:
	# (100, 50) lies on the right edge: dist_along=100+50=150, t=150/400=0.375
	assert_almost_eq(BorderMath.nearest_t(RECT, Vector2(100.0, 50.0)), 0.375, 0.0001)
