extends GutTest

const TrailHeadLayer = preload("res://scripts/fx/trail_head_layer.gd")


func _assert_rect(actual: Rect2, expected: Rect2, label: String) -> void:
	assert_almost_eq(actual.position.x, expected.position.x, 0.001, "%s x" % label)
	assert_almost_eq(actual.position.y, expected.position.y, 0.001, "%s y" % label)
	assert_almost_eq(actual.size.x, expected.size.x, 0.001, "%s width" % label)
	assert_almost_eq(actual.size.y, expected.size.y, 0.001, "%s height" % label)


func test_forward_right_progress_clips_the_head_cell() -> void:
	var from := Vector2(5, 5)
	var to := Vector2(15, 5)
	_assert_rect(TrailHeadLayer.forward_rect(from, to, from, 10.0), Rect2(10, 0, 0, 10), "start")
	_assert_rect(TrailHeadLayer.forward_rect(from, to, Vector2(10, 5), 10.0), Rect2(10, 0, 5, 10), "half")
	_assert_rect(TrailHeadLayer.forward_rect(from, to, to, 10.0), Rect2(10, 0, 10, 10), "full")


func test_forward_left_progress_clips_the_head_cell() -> void:
	var from := Vector2(15, 5)
	var to := Vector2(5, 5)
	_assert_rect(TrailHeadLayer.forward_rect(from, to, from, 10.0), Rect2(10, 0, 0, 10), "start")
	_assert_rect(TrailHeadLayer.forward_rect(from, to, Vector2(10, 5), 10.0), Rect2(5, 0, 5, 10), "half")
	_assert_rect(TrailHeadLayer.forward_rect(from, to, to, 10.0), Rect2(0, 0, 10, 10), "full")


func test_forward_vertical_progress_clips_the_head_cell() -> void:
	_assert_rect(TrailHeadLayer.forward_rect(Vector2(5, 5), Vector2(5, 15), Vector2(5, 10), 10.0),
		Rect2(0, 10, 10, 5), "down half")
	_assert_rect(TrailHeadLayer.forward_rect(Vector2(5, 15), Vector2(5, 5), Vector2(5, 10), 10.0),
		Rect2(0, 5, 10, 5), "up half")


func test_first_dive_uses_the_safe_cell_as_the_visual_anchor() -> void:
	_assert_rect(TrailHeadLayer.forward_rect(Vector2(5, 5), Vector2(15, 5), Vector2(12.5, 5), 10.0),
		Rect2(10, 0, 7.5, 10), "first dive")


func test_diagonal_geometry_is_rejected() -> void:
	_assert_rect(TrailHeadLayer.forward_rect(Vector2(5, 5), Vector2(15, 15), Vector2(10, 10), 10.0),
		Rect2(), "diagonal")


func test_retract_segment_shrinks_to_clear_at_the_new_head() -> void:
	var from := Vector2(15, 5)
	var to := Vector2(5, 5)
	_assert_rect(TrailHeadLayer.retract_rect(from, to, from, 10.0), Rect2(10, 0, 5, 10), "start")
	_assert_rect(TrailHeadLayer.retract_rect(from, to, Vector2(10, 5), 10.0), Rect2(10, 0, 0, 10), "boundary")
	_assert_rect(TrailHeadLayer.retract_rect(from, to, to, 10.0), Rect2(10, 0, 0, 10), "target")


func test_overlay_only_covers_an_active_matching_forward_head() -> void:
	var layer := TrailHeadLayer.new()
	layer.configure(10.0, Color.WHITE, 0.0, 0.0, 0.0)
	assert_false(layer.covers_head(Vector2i(1, 1)), "inactive overlay must not suppress base head")
	layer.begin_forward(Vector2(5, 5), Vector2(15, 5), Vector2i(1, 0))
	assert_true(layer.covers_head(Vector2i(1, 0)), "valid forward overlay owns its matching head")
	assert_false(layer.covers_head(Vector2i(0, 1)), "other logical heads remain base-drawn")
	layer.clear()
	assert_false(layer.covers_head(Vector2i(1, 0)), "clear restores the base draw fallback")
	layer.free()


func test_arena_suppresses_the_base_head_only_for_a_valid_overlay() -> void:
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	var head := Vector2i(1, 1)
	assert_true(arena.add_trail(head), "logical trail is added before presentation")
	assert_false(arena.is_trail_head_suppressed(), "inactive overlay leaves the logical base head visible")
	arena.begin_trail_head_forward(arena.cell_to_world(Vector2i(0, 1)), arena.cell_to_world(head))
	assert_true(arena.is_trail_head_suppressed(), "valid matching overlay suppresses duplicate base drawing")
	arena.clear_trail_head_presentation()
	assert_false(arena.is_trail_head_suppressed(), "clear immediately restores the base head fallback")
