extends GutTest

## Sparx (edge-walker) type + Frost roster + wall-follow movement (no stall). Threat (a) trail
## only in 19b-1; player-cell threat (b) is 19b-2.

func test_sparx_type_is_edge_follow_square() -> void:
	var t: EnemyType = load("res://resources/enemies/type_sparx.tres")
	assert_true(t.edge_follow, "edge_follow set")
	assert_eq(t.shape, 2, "SQUARE shape")
	assert_eq(String(t.id), "sparx")


func test_frost_roster_has_sparx_and_chaser() -> void:
	var frost: ArenaData = null
	for a in ContentCatalog.ARENAS:
		if a.id == &"frost":
			frost = a
	assert_not_null(frost, "frost arena exists")
	var ids: Array = []
	for e in frost.enemies:
		ids.append(String(e.id))
	assert_true(ids.has("sparx"), "frost roster has sparx")
	assert_true(ids.has("chaser"), "frost still has chaser")


func test_sparx_moves_without_stall() -> void:
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	GameState.start_run(3)
	var e := Enemy.new()
	add_child_autofree(e)
	var start_cell := Vector2i(1, 1)
	var speed_px: float = 16.0 * arena.cell_size
	e.setup(arena, arena.cell_to_world(start_cell), Vector2.ZERO, null, speed_px, 0.0, true, start_cell, Vector2i.DOWN)
	var p0: Vector2 = e.position
	for i in 30:
		e._physics_process(0.05)
	assert_true(e.position.distance_to(p0) > arena.cell_size, "sparx travelled along the edge (no stall)")
	GameState.reset()


func test_sparx_catches_player_at_edge_then_cooldown() -> void:
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	GameState.start_run(3)
	var e := Enemy.new()
	add_child_autofree(e)
	var cell := Vector2i(1, 1)
	e.setup(arena, arena.cell_to_world(cell), Vector2.ZERO, null, 16.0 * arena.cell_size, 0.0, true, cell, Vector2i.DOWN)
	e.edge_catch_cooldown = 0.5
	watch_signals(e)
	# Player on the Sparx's cell -> caught (threat b), even though not drawing.
	e.decide_velocity(arena.cell_to_world(cell), false)  # reports player position
	e._physics_process(0.01)
	assert_signal_emitted(e, "hit_trail", "sparx catches the player at the edge")
	# Immediately after: cooldown blocks a chain-kill.
	e.decide_velocity(arena.cell_to_world(cell), false)
	e._physics_process(0.01)
	assert_signal_emit_count(e, "hit_trail", 1, "no chain-kill during cooldown")
	GameState.reset()


func test_frost_desc_mentions_sparx_after_19b2() -> void:
	# Localized Frost description updated to mention the edge patroller.
	assert_string_contains(tr("ARENA_FROST_DESC").to_lower(), "sparx")


func _sparx_on(arena: ArenaController, cell: Vector2i) -> Enemy:
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(cell), Vector2.ZERO, null, 16.0 * arena.cell_size, 0.0, true, cell, Vector2i.DOWN)
	return e


func _frost_arena() -> ArenaController:
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	return arena


# Fences off a small top-left FREE pocket (x in 1..4, y in 1..7) from the main region, leaving
# both regions FREE separated by a captured trail -> a real trap for the lap/respawn tests.
func _carve_corner_pocket(arena: ArenaController) -> void:
	var g: CaptureGrid = arena.grid
	var path: Array = []
	for y in range(1, 9):  # x=5 column, y=1..8
		path.append(Vector2i(5, y))
	for x in range(4, 0, -1):  # y=8 row, x=4..1
		path.append(Vector2i(x, 8))
	g.lay_trail(path)
	g.close_and_capture([Vector2i(2, 2), Vector2i(40, 40)])  # spare pocket + main region


func _in_pocket(c: Vector2i) -> bool:
	return c.x >= 1 and c.x <= 4 and c.y >= 1 and c.y <= 7


func test_sparx_contains_when_sealed_off() -> void:
	# Connectivity trigger: a real pocket (Sparx cell stays FREE but is cut off from the main
	# region) -> CONTAINED. trap_pocket_max_cells = 0 disables the size safety, proving connectivity.
	var arena := _frost_arena()
	GameState.start_run(3)
	_carve_corner_pocket(arena)
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.trap_pocket_max_cells = 0  # pure connectivity, no size shortcut
	e.on_capture_event()
	assert_eq(e.get("_sparx_state"), Enemy.SparxState.CONTAINED, "sealed off -> CONTAINED")
	assert_false(e.visible, "contained -> invisible")
	GameState.reset()


func test_sparx_open_arena_not_contained() -> void:
	# Sparx in the main region (no pocket) is never contained -> stays on patrol.
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.trap_pocket_max_cells = 0
	e.on_capture_event()
	assert_eq(e.get("_sparx_state"), Enemy.SparxState.PATROL, "main region -> PATROL")
	assert_true(e.visible, "stays visible")
	GameState.reset()


func test_sparx_contains_on_engulf() -> void:
	# Engulf (Sparx cell captured) is the pocket-size-0 case -> CONTAINED.
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(0, 0))  # a CAPTURED (border) cell
	e.on_capture_event()
	assert_eq(e.get("_sparx_state"), Enemy.SparxState.CONTAINED, "engulfed -> CONTAINED")
	GameState.reset()


func test_sparx_reemerges_in_main_on_timer_alone() -> void:
	# CONTAINED -> after contain_duration (NO further capture) -> re-emerge in the MAIN region,
	# never back in the pocket. Pure timer; proves no permanent trap.
	var arena := _frost_arena()
	GameState.start_run(3)
	_carve_corner_pocket(arena)
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.trap_pocket_max_cells = 0
	e.contain_duration = 0.3
	e.emerge_telegraph = 0.0
	e.decide_velocity(arena.cell_to_world(Vector2i(40, 40)), false)  # player in main
	e.on_capture_event()
	assert_eq(e.get("_sparx_state"), Enemy.SparxState.CONTAINED, "trapped -> CONTAINED")
	for i in 12:
		e._physics_process(0.05)  # 0.6s > contain -> re-emerge, with NO capture event
	assert_false(_in_pocket(e.get("_grid_cell")), "re-emerged in the MAIN region, not the pocket")
	assert_true(e.visible, "visible after re-emerge")
	GameState.reset()


func test_sparx_patrols_after_reemerge() -> void:
	var arena := _frost_arena()
	GameState.start_run(3)
	_carve_corner_pocket(arena)
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.trap_pocket_max_cells = 0
	e.contain_duration = 0.2
	e.emerge_telegraph = 0.0
	e.decide_velocity(arena.cell_to_world(Vector2i(40, 40)), false)
	e.on_capture_event()
	for i in 10:
		e._physics_process(0.05)  # contain + telegraph done -> PATROL in main
	var c0: Vector2i = e.get("_grid_cell")
	for i in 8:
		e._physics_process(0.1)
	assert_ne(e.get("_grid_cell"), c0, "Sparx patrols after re-emerge (no spin-in-place)")
	GameState.reset()


func test_sparx_reemerges_at_safe_distance() -> void:
	# Anti-insta-kill: re-emerge cell is >= safe_emerge_distance from the player (never adjacent).
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(5, 5))
	e.safe_emerge_distance = 8
	var player_cell := Vector2i(10, 10)
	e.decide_velocity(arena.cell_to_world(player_cell), false)
	e.call("_begin_telegraph")  # pick the re-emerge target
	var gc: Vector2i = e.get("_grid_cell")
	var dist: int = absi(gc.x - player_cell.x) + absi(gc.y - player_cell.y)
	assert_true(dist >= 8, "re-emerge at safe distance (got %d)" % dist)
	assert_true(dist > 1, "never re-emerge adjacent to the player")
	GameState.reset()


func test_sparx_full_lap_no_premature_reverse() -> void:
	# Wall-follow traces a full loop back to start without ever U-turning mid-loop (only at dead-ends).
	var arena := _frost_arena()
	GameState.start_run(3)
	var start := Vector2i(1, 1)
	var e := _sparx_on(arena, start)
	var prev: Vector2i = e.get("_heading")
	var reversed := false
	var returned := false
	for i in 600:
		e._physics_process(0.05)
		var h: Vector2i = e.get("_heading")
		if h == -prev:
			reversed = true
		prev = h
		if i > 10 and e.get("_grid_cell") == start:
			returned = true
	assert_false(reversed, "no premature reverse on a closed edge loop")
	assert_true(returned, "completes a full lap back to the start cell")
	GameState.reset()


func test_stuck_loop_detected_on_big_region() -> void:
	# Circling a tiny set of cells while a large FREE region exists -> degenerate loop detected.
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.loop_check_steps = 12
	e.loop_min_cells = 4
	var cyc: Array = [Vector2i(20, 20), Vector2i(20, 21), Vector2i(21, 21), Vector2i(21, 20)]
	var flagged := false
	for i in 40:
		e.set("_grid_cell", cyc[i % cyc.size()])
		if e.call("_is_stuck_in_loop"):
			flagged = true
			break
	assert_true(flagged, "tiny cycle amid a large FREE region -> stuck")
	GameState.reset()


func test_tiny_region_not_flagged_no_thrash() -> void:
	# When the whole reachable area IS that small (near-win), do NOT relocate -> no thrash.
	var arena := _frost_arena()
	GameState.start_run(3)
	_carve_corner_pocket(arena)  # ~28-cell isolated FREE pocket
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.loop_check_steps = 12
	e.loop_min_cells = 40  # pocket counts as "tiny", but it is the whole region
	var flagged := false
	for i in 40:
		e.set("_grid_cell", Vector2i(1 + (i % 4), 1))  # cycle inside the pocket
		if e.call("_is_stuck_in_loop"):
			flagged = true
			break
	assert_false(flagged, "whole region IS this small -> no relocate")
	GameState.reset()


func test_real_lap_not_flagged_as_stuck() -> void:
	# A genuine border lap covers many distinct cells -> never mistaken for a stuck loop.
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(1, 1))
	var seen: Dictionary = {}
	for i in 200:
		e._physics_process(0.05)
		seen[e.get("_grid_cell")] = true
	assert_eq(e.get("_sparx_state"), Enemy.SparxState.PATROL, "real lap stays patrolling (no relocate)")
	assert_gt(seen.size(), e.loop_min_cells, "real lap covers many distinct cells")
	GameState.reset()


func test_sparx_stays_on_border_never_interior() -> void:
	# Edge-lock invariant: every cell Sparx occupies is border-adjacent (touches a wall). It must
	# NEVER step into the open interior, even over a long patrol.
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(1, 1))
	for i in 150:
		e._physics_process(0.05)
		var gc: Vector2i = e.get("_grid_cell")
		assert_true(e.call("_has_captured_neighbor", gc.x, gc.y),
			"Sparx stays border-adjacent (never interior) at step %d" % i)
	GameState.reset()


func test_sparx_telegraph_is_non_lethal() -> void:
	# During the respawn telegraph blink, Sparx must not catch the player (warning window).
	var arena := _frost_arena()
	GameState.start_run(3)
	var e := _sparx_on(arena, Vector2i(1, 1))
	e.set("_sparx_state", Enemy.SparxState.TELEGRAPH)
	e.set("_telegraph_timer", 1.0)  # in the warning window
	watch_signals(e)
	for i in 3:
		e.decide_velocity(arena.cell_to_world(Vector2i(1, 1)), false)  # player on its cell
		e._physics_process(0.1)
	assert_signal_emit_count(e, "hit_trail", 0, "telegraph window is non-lethal")
	GameState.reset()
