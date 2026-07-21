extends GutTest

## Feel-pass P0 (visual layer): the capture flash must be PAINT-only (grid state is fully
## captured from frame one), the HUD shows the target next to the live percent, Sparx
## contain spawns a poof, and campaign stars reveal with a stagger. No gameplay change.


func after_each() -> void:
	# Poof bursts self-free after their 0.5s lifetime — tests end sooner, so sweep them
	# to keep GUT's unfreed-children report clean.
	for c in get_children():
		if c is CPUParticles2D:
			c.free()


func _arena() -> ArenaController:
	var a := ArenaController.new()
	add_child_autofree(a)
	a.configure(load("res://resources/arenas/arena_void.tres"), Rect2(40, 100, 640, 1100))
	return a


func test_capture_flash_is_paint_only() -> void:
	# The INSTANT close_capture returns, every new cell is CAPTURED in the grid (what enemies
	# and danger checks read) even though the flash wave is still playing.
	var arena := _arena()
	var g: CaptureGrid = arena.grid
	var path: Array = [Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3)]
	assert_true(g.lay_trail(path), "test trail laid")
	arena.close_capture([Vector2i(30, 30)])  # danger seed in the open middle
	for c in path:
		assert_eq(arena.cell_state(c), CaptureGrid.Cell.CAPTURED,
			"cell %s CAPTURED on frame one (state never lags the paint)" % str(c))
	var layer: Node2D = arena.get_node("FlashLayer")
	assert_gt(float(layer.get("_total")), 0.0, "flash wave is active (child layer, visual only)")
	# The wave plays out on its own clock and clears (visual bookkeeping only).
	layer._process(10.0)
	assert_eq(float(layer.get("_total")), 0.0, "flash wave fully played + cleared")


func test_capture_wave_spreads_from_centroid() -> void:
	# Pulse delays grow with distance from the closure centroid -> the "filling outward" read.
	var arena := _arena()
	var g: CaptureGrid = arena.grid
	var path: Array = []
	for y in range(1, 8):
		path.append(Vector2i(3, y))  # straight 7-cell line; captures just the trail cells
	assert_true(g.lay_trail(path), "test trail laid")
	arena.close_capture([Vector2i(30, 30)])
	var layer: Node2D = arena.get_node("FlashLayer")
	var runs: Array = layer.get("_runs")
	assert_gt(runs.size(), 0, "wave produced merged pulse runs")
	# Coverage invariant: the merged runs cover EXACTLY the captured cells (no more, no less).
	var covered: Dictionary = {}
	for r in runs:
		var rect: Rect2 = r[1]
		var x0: int = int(roundf((rect.position.x - arena.arena_rect.position.x) / arena.cell_size))
		var y: int = int(roundf((rect.position.y - arena.arena_rect.position.y) / arena.cell_size))
		var w: int = int(roundf(rect.size.x / arena.cell_size))
		for dx in w:
			covered[Vector2i(x0 + dx, y)] = true
	assert_eq(covered.size(), path.size(), "merged runs cover exactly the new cells")
	for c in path:
		assert_true(covered.has(c), "cell %s covered by the wave" % str(c))
	# Wave shape: farther cells start later than the centroid's bucket.
	var lo: float = runs[0][0]
	var hi: float = runs[0][0]
	for r in runs:
		lo = minf(lo, r[0])
		hi = maxf(hi, r[0])
	assert_gt(hi, lo, "farther cells pulse later (wave, not a simultaneous blink)")


func test_wave_total_capped_for_big_regions() -> void:
	# Small regions keep the per-cell pace; delays compress to wave_max_duration when a region
	# would otherwise crawl. Uses exaggerated knobs so the cap provably binds.
	var arena := _arena()
	arena.wave_delay_per_cell = 0.05
	arena.wave_max_duration = 0.1
	arena.wave_quantize = 0.001  # near-exact starts for the assertion
	var path: Array = []
	for y in range(1, 8):
		path.append(Vector2i(3, y))  # max distance from centroid = 3 cells -> uncapped 0.15s
	assert_true(arena.grid.lay_trail(path), "trail laid")
	arena.close_capture([Vector2i(30, 30)])
	var layer: Node2D = arena.get_node("FlashLayer")
	var hi: float = 0.0
	for r in layer.get("_runs"):
		hi = maxf(hi, r[0])
	assert_between(hi, 0.09, 0.11, "sweep compressed to the cap (0.15s uncapped -> ~0.1s)")
	# Under the cap: natural per-cell pace is untouched.
	layer.clear_wave()
	arena.wave_max_duration = 10.0
	var path2: Array = []
	for y in range(20, 27):
		path2.append(Vector2i(3, y))
	assert_true(arena.grid.lay_trail(path2), "second trail laid")
	arena.close_capture([Vector2i(30, 30)])
	hi = 0.0
	for r in layer.get("_runs"):
		hi = maxf(hi, r[0])
	assert_between(hi, 0.14, 0.16, "under the cap the per-cell pace is unchanged (3 x 0.05)")


func test_flash_window_skips_completed_and_pending() -> void:
	# Mobile perf: per frame only the ACTIVE wedge is touched — completed runs fall behind _lo,
	# pending ones aren't iterated (sorted starts). Coverage/look identical (other tests pin it).
	var arena := _arena()
	arena.wave_delay_per_cell = 0.1
	arena.wave_max_duration = 10.0  # cap must not bind here
	arena.wave_quantize = 0.001
	var path: Array = []
	for y in range(1, 8):
		path.append(Vector2i(3, y))  # delays span 0 .. 0.3s, duration 0.25
	assert_true(arena.grid.lay_trail(path), "trail laid")
	arena.close_capture([Vector2i(30, 30)])
	var layer: Node2D = arena.get_node("FlashLayer")
	var runs: Array = layer.get("_runs")
	for i in range(1, runs.size()):
		assert_true(runs[i][0] >= runs[i - 1][0], "runs sorted by pulse start")
	assert_eq(int(layer.get("_lo")), 0, "window starts at the head")
	layer._process(0.28)  # start-0 pulses (duration 0.25) are done; late ones still pending/active
	var lo: int = int(layer.get("_lo"))
	assert_gt(lo, 0, "completed runs fell behind the window")
	assert_lt(lo, runs.size(), "wave still alive (later pulses remain)")
	layer._process(10.0)
	assert_eq(int(layer.get("_total")), 0, "wave finished and cleared")


func test_cells_accessor_matches_cell_at() -> void:
	# The rendering fast path (raw buffer) must agree with the logic path (cell_at) everywhere.
	var arena := _arena()
	var g: CaptureGrid = arena.grid
	g.lay_trail([Vector2i(3, 1), Vector2i(3, 2)])
	var cells: PackedByteArray = g.cells()
	for y in g.rows:
		for x in g.cols:
			if cells[y * g.cols + x] != g.cell_at(x, y):
				fail_test("mismatch at (%d,%d)" % [x, y])
				return
	pass_test("raw buffer == cell_at across the whole grid")


func test_hud_shows_target_next_to_percent() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	hud.set_target(75.0)
	hud.update_percent(62.0)
	var label: Label = hud.get_node("TopBar/PercentLabel")
	assert_eq(label.text, "62 / 75%", "player can always see the goal")
	hud.set_target(50.0)
	hud.update_percent(0.0)
	assert_eq(label.text, "0 / 50%", "target follows the stage/level")


func test_sparx_contain_spawns_poof() -> void:
	var arena := _arena()
	GameState.start_run(3)
	# Seal a corner pocket so connectivity traps the sparx (same shape as test_sparx).
	var g: CaptureGrid = arena.grid
	var path: Array = []
	for y in range(1, 9):
		path.append(Vector2i(5, y))
	for x in range(4, 0, -1):
		path.append(Vector2i(x, 8))
	g.lay_trail(path)
	g.close_and_capture([Vector2i(2, 2), Vector2i(40, 40)])
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(1, 1)), Vector2.ZERO, null, 100.0, 0.0, true, Vector2i(1, 1), Vector2i.DOWN)
	var bursts_before: int = _count_bursts()
	e.on_capture_event()
	assert_true(e.is_contained(), "sparx contained")
	assert_gt(_count_bursts(), bursts_before, "contain spawned a poof burst (visual)")
	GameState.reset()


func _count_bursts() -> int:
	var n: int = 0
	for c in get_children():
		if c is CPUParticles2D:
			n += 1
	return n


func test_campaign_stars_reveal_staggered() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	hud.star_stagger = 0.02  # fast for the test; feel value stays @export
	hud.show_campaign_stars(2, true, false)
	var stars: Label = hud.get_node("ResultPanel/VBox/StarsLabel")
	assert_eq(stars.text, "", "reveal starts empty (stars come one by one)")
	await get_tree().create_timer(0.3).timeout
	assert_eq(stars.text, "★★☆", "all three slots revealed with the earned fill")
	var best: Label = hud.get_node("ResultPanel/VBox/NewBestLabel")
	assert_true(best.visible, "new-best pops at the end")
