extends GutTest

# Explicit preloads ensure the classes resolve before GUT parses this file.
const CaptureGrid = preload("res://scripts/core/capture_grid.gd")
const CaptureResult = preload("res://scripts/core/capture_result.gd")


func _vertical_wall(x: int, y_from: int, y_to: int) -> Array:
	var path: Array = []
	for y in range(y_from, y_to + 1):
		path.append(Vector2i(x, y))
	return path


func test_init_frame_ring_and_interior() -> void:
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_eq(g.cell_at(0, 0), CaptureGrid.Cell.CAPTURED, "köşe çerçeve olmalı")
	assert_eq(g.cell_at(6, 6), CaptureGrid.Cell.CAPTURED, "köşe çerçeve olmalı")
	assert_eq(g.cell_at(3, 3), CaptureGrid.Cell.FREE, "iç FREE olmalı")
	assert_eq(g.total_capturable, 25, "iç 5x5 = 25 kapatılabilir")
	assert_eq(g.captured_percent(), 0.0)


func test_out_of_bounds_is_wall() -> void:
	var g = CaptureGrid.new(5, 5, 1.0, Vector2.ZERO)
	assert_eq(g.cell_at(-1, 0), CaptureGrid.Cell.CAPTURED)
	assert_eq(g.cell_at(5, 5), CaptureGrid.Cell.CAPTURED)
	assert_false(g.in_bounds(-1, 0))


func test_world_cell_round_trip() -> void:
	var g = CaptureGrid.new(10, 10, 10.0, Vector2(40, 100))
	assert_eq(g.cell_to_world(Vector2i(2, 3)), Vector2(40 + 25, 100 + 35))
	assert_eq(g.world_to_cell(Vector2(40 + 25, 100 + 35)), Vector2i(2, 3))


func test_no_split_captures_only_trail() -> void:
	# Wall along leftmost interior column lines the edge, splits nothing.
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_true(g.lay_trail(_vertical_wall(1, 1, 5)))
	var r = g.close_and_capture([])
	assert_eq(r.captured_count, 5, "sadece 5 trail hücre captured")
	assert_almost_eq(r.percent, 20.0, 0.001)


func test_split_captures_smaller_region_no_seed() -> void:
	# Wall at x=2 splits interior into left(5) and right(15). Smaller captured.
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_true(g.lay_trail(_vertical_wall(2, 1, 5)))
	var r = g.close_and_capture([])
	assert_eq(r.captured_count, 10, "5 trail + 5 küçük bölge")
	assert_almost_eq(r.percent, 40.0, 0.001)
	assert_eq(g.cell_at(1, 1), CaptureGrid.Cell.CAPTURED, "küçük bölge captured")
	assert_eq(g.cell_at(4, 1), CaptureGrid.Cell.FREE, "büyük bölge serbest kalır")


func test_danger_seed_flips_capture() -> void:
	# Seed in the small (left) region -> the large (right) region is captured.
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_true(g.lay_trail(_vertical_wall(2, 1, 5)))
	var r = g.close_and_capture([Vector2i(1, 1)])
	assert_eq(r.captured_count, 20, "5 trail + 15 büyük bölge")
	assert_almost_eq(r.percent, 80.0, 0.001)
	assert_eq(g.cell_at(1, 1), CaptureGrid.Cell.FREE, "seed bölgesi serbest kalır")
	assert_eq(g.cell_at(4, 1), CaptureGrid.Cell.CAPTURED, "diğer bölge captured")


func test_self_intersection_rejected() -> void:
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	# Duplicate cell -> rejected, grid unchanged.
	assert_false(g.lay_trail([Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 1)]))
	assert_eq(g.cell_at(1, 1), CaptureGrid.Cell.FREE)
	assert_eq(g.cell_at(1, 2), CaptureGrid.Cell.FREE)


func test_non_adjacent_path_rejected() -> void:
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_false(g.lay_trail([Vector2i(1, 1), Vector2i(3, 3)]))
	assert_eq(g.cell_at(1, 1), CaptureGrid.Cell.FREE)


func test_degenerate_single_cell() -> void:
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_true(g.lay_trail([Vector2i(1, 1)]))
	var r = g.close_and_capture([])
	assert_eq(r.captured_count, 1)
	assert_almost_eq(r.percent, 4.0, 0.001)


func test_full_capture_reaches_100() -> void:
	# Snake through the whole 5x5 interior so every cell becomes trail.
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	var path: Array = []
	for y in range(1, 6):
		var xs := range(1, 6) if (y % 2 == 1) else range(5, 0, -1)
		for x in xs:
			path.append(Vector2i(x, y))
	assert_true(g.lay_trail(path), "yılan yolu geçerli olmalı")
	var r = g.close_and_capture([])
	assert_eq(r.captured_count, 25)
	assert_almost_eq(r.percent, 100.0, 0.001)


func test_percent_never_exceeds_bounds() -> void:
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	assert_true(g.lay_trail(_vertical_wall(2, 1, 5)))
	g.close_and_capture([])
	assert_between(g.captured_percent(), 0.0, 100.0)


func test_capture_is_deterministic() -> void:
	# Same path + same seed strategy -> identical captured sets.
	var a = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	var b = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	a.lay_trail(_vertical_wall(2, 1, 5))
	b.lay_trail(_vertical_wall(2, 1, 5))
	var ra = a.close_and_capture([])
	var rb = b.close_and_capture([])
	assert_eq(ra.captured_count, rb.captured_count)
	assert_almost_eq(ra.percent, rb.percent, 0.001)
	assert_eq(ra.newly_captured.size(), rb.newly_captured.size())
