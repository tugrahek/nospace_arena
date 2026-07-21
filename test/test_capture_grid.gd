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


func test_remove_trail_cell_frees_the_cell() -> void:
	var g = CaptureGrid.new(7, 7, 1.0, Vector2.ZERO)
	g.add_trail_cell(Vector2i(1, 1))
	assert_eq(g.cell_at(1, 1), CaptureGrid.Cell.TRAIL)
	g.remove_trail_cell(Vector2i(1, 1))
	assert_eq(g.cell_at(1, 1), CaptureGrid.Cell.FREE)


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


# --- Reference-reachability property (guard for ANY future core-flood change, perf #5+) ---

## Independent naive BFS over a state snapshot: which cells stay FREE given the danger seeds.
## Deliberately a different implementation (queue + Dictionary) than the engine's flood.
func _reference_unreached(states: Array, cols: int, rows: int, seeds: Array) -> Dictionary:
	var reached: Dictionary = {}
	var queue: Array = []
	for s in seeds:
		var sc: Vector2i = s
		if sc.x >= 0 and sc.x < cols and sc.y >= 0 and sc.y < rows \
				and states[sc.y * cols + sc.x] == CaptureGrid.Cell.FREE and not reached.has(sc):
			reached[sc] = true
			queue.append(sc)
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()  # BFS on purpose (engine uses DFS) — same closure
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if n.x < 0 or n.x >= cols or n.y < 0 or n.y >= rows:
				continue
			if states[n.y * cols + n.x] == CaptureGrid.Cell.FREE and not reached.has(n):
				reached[n] = true
				queue.append(n)
	var unreached: Dictionary = {}
	for y in rows:
		for x in cols:
			if states[y * cols + x] == CaptureGrid.Cell.FREE and not reached.has(Vector2i(x, y)):
				unreached[Vector2i(x, y)] = true
	return unreached


func _assert_capture_matches_reference(g, trail: Array, seeds: Array, label: String) -> void:
	assert_true(g.lay_trail(trail), "%s: trail laid" % label)
	# Snapshot the post-trail state with TRAIL already converted (close's first step).
	var states: Array = []
	for y in g.rows:
		for x in g.cols:
			var s: int = g.cell_at(x, y)
			states.append(CaptureGrid.Cell.CAPTURED if s == CaptureGrid.Cell.TRAIL else s)
	var expected: Dictionary = _reference_unreached(states, g.cols, g.rows, seeds)
	for t in trail:
		expected[t] = true  # the trail itself is always newly captured
	var r = g.close_and_capture(seeds)
	assert_eq(r.newly_captured.size(), expected.size(), "%s: newly count == reference" % label)
	for c in r.newly_captured:
		assert_true(expected.has(c), "%s: %s expected by reference BFS" % [label, str(c)])


func test_capture_matches_reference_reachability() -> void:
	# Line that splits nothing (seed in the open).
	var a = CaptureGrid.new(9, 9, 1.0, Vector2.ZERO)
	_assert_capture_matches_reference(a, _vertical_wall(2, 1, 4), [Vector2i(5, 5)], "open-line")
	# Full split, seed on the big side -> small side captured.
	var b = CaptureGrid.new(9, 9, 1.0, Vector2.ZERO)
	_assert_capture_matches_reference(b, _vertical_wall(3, 1, 7), [Vector2i(6, 4)], "split")
	# L-shaped pocket, seed outside it.
	var c = CaptureGrid.new(11, 11, 1.0, Vector2.ZERO)
	var l_path: Array = []
	for y in range(1, 5):
		l_path.append(Vector2i(4, y))
	for x in range(3, 0, -1):
		l_path.append(Vector2i(x, 4))
	_assert_capture_matches_reference(c, l_path, [Vector2i(8, 8)], "L-pocket")
