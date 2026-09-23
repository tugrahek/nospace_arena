extends GutTest

## Fix-pass #20 — device findings B5 (enemy left standing in captured territory), B6 (Sparx stuck
## patrolling a sealed pocket forever) and B7 (roam ping-pongs along a captured edge). All three
## were proven pre-existing (not caused by #17/#18/#19) via git A/B in the diagnosis pass.
## capture/seed/grid algorithm untouched throughout — only orchestration (which cell a seed/
## evacuation uses) and enemy motion/behavior change.

const EnemyMotion = preload("res://scripts/gameplay/enemy_motion.gd")


func _arena(res: String) -> ArenaController:
	var a := ArenaController.new()
	add_child_autofree(a)
	a.configure(load(res), Rect2(40, 100, 640, 1100))
	return a


## Down one side, across, back up the other -- a 3-wall pocket (the exact device B5 repro shape).
func _pocket_trail(cols_x: int, top: int, bottom: int, width: int) -> Array:
	var path: Array = []
	for y in range(top, bottom + 1):
		path.append(Vector2i(cols_x, y))
	for x in range(cols_x + 1, cols_x + width + 1):
		path.append(Vector2i(x, bottom))
	for y in range(bottom - 1, top - 1, -1):
		path.append(Vector2i(cols_x + width, y))
	return path


# --- B5: nearest_free_cell (pure) ---

func test_nearest_free_cell_pure() -> void:
	var arena := _arena("res://resources/arenas/arena_void.tres")
	var g: CaptureGrid = arena.grid
	assert_eq(arena.nearest_free_cell(Vector2i(10, 10), 5), Vector2i(10, 10), "already free -> itself")
	assert_true(g.lay_trail([Vector2i(10, 10)]), "trail laid")
	g.close_and_capture([Vector2i(30, 30)])
	var found: Vector2i = arena.nearest_free_cell(Vector2i(10, 10), 5)
	assert_ne(found, Vector2i(10, 10), "captured -> not itself")
	assert_eq(arena.cell_state(found), CaptureGrid.Cell.FREE, "the result is actually FREE")
	assert_eq(arena.nearest_free_cell(Vector2i(10, 10), 5), found, "deterministic (same inputs -> same output)")
	assert_eq(arena.nearest_free_cell(Vector2i(0, 0), 0), Vector2i(-1, -1), "radius 0, not free -> none")


func test_nearest_free_cell_out_of_range() -> void:
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	var g: CaptureGrid = arena.grid
	var cols: int = g.cols
	var wall: Array = []
	for y in range(1, g.rows - 1):
		wall.append(Vector2i(cols - 5, y))
	assert_true(g.lay_trail(wall), "wall laid")
	g.close_and_capture([Vector2i(cols - 3, 20)])  # seed only the column -> everything left is captured
	var deep := Vector2i(10, 20)
	assert_eq(arena.cell_state(deep), CaptureGrid.Cell.CAPTURED, "setup: deep cell is captured")
	assert_eq(arena.nearest_free_cell(deep, 3), Vector2i(-1, -1), "too small a radius -> none found")
	assert_ne(arena.nearest_free_cell(deep, cols), Vector2i(-1, -1), "wide enough radius -> finds the column")


# --- B5: bounce instead of freeze (approaching a trail wall from outside, the realistic case) ---

func test_grace_ignored_hit_bounces_instead_of_freezing() -> void:
	var arena := _arena("res://resources/arenas/arena_void.tres")
	GameState.start_run(3)
	var g: CaptureGrid = arena.grid
	var wall: Array = []
	for y in range(5, 40):
		wall.append(Vector2i(20, y))
	assert_true(g.lay_trail(wall), "trail wall laid")
	var e := Enemy.new()
	e.shape = Enemy.Shape.TRIANGLE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(15, 20)), Vector2(150, 0), ChaserBehavior.new(), 150.0)
	var hits: Array[int] = [0]
	e.hit_trail.connect(func() -> void: hits[0] += 1)  # connected but does nothing -- ~= grace ignoring it
	var positions: Array[Vector2] = []
	for f in 90:
		e._physics_process(1.0 / 60.0)
		positions.append(e.position)
	assert_gt(hits[0], 0, "setup: it did try to enter the trail")
	for p in positions:
		assert_lt(arena.world_to_cell(p).x, 20, "never crossed into the trail's column")
	var spread: float = 0.0
	for p in positions:
		spread = maxf(spread, p.distance_to(positions[0]))
	assert_gt(spread, arena.cell_size, "bounced and kept moving -- not frozen dead-still")
	GameState.reset()


func test_cleared_trail_lets_the_enemy_through() -> void:
	# The other synchronous outcome: the hit WASN'T ignored (something cleared the trail, as the
	# game does on a real death) -- the enemy should proceed into the now-FREE cell, not bounce.
	var arena := _arena("res://resources/arenas/arena_void.tres")
	GameState.start_run(3)
	var g: CaptureGrid = arena.grid
	assert_true(g.lay_trail([Vector2i(20, 20)]), "single trail cell")
	var e := Enemy.new()
	e.shape = Enemy.Shape.TRIANGLE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(15, 20)), Vector2(150, 0), ChaserBehavior.new(), 150.0)
	e.hit_trail.connect(func() -> void: g.remove_trail_cell(Vector2i(20, 20)))  # clears it, like a real death
	for f in 40:
		e._physics_process(1.0 / 60.0)
	assert_gt(arena.world_to_cell(e.position).x, 20, "passed straight through the now-FREE cell")
	GameState.reset()


# --- B5: guard invariant (the exact device repro, via the real game.gd functions) ---

func test_guard_invariant_no_active_enemy_in_captured_cell() -> void:
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	var arena: ArenaController = game.get_node("Arena")
	var enemies: Array = game.get("_enemies")
	assert_gt(enemies.size(), 0, "setup: free-play spawns at least one enemy")
	var e: Enemy = enemies[0]
	var path: Array = _pocket_trail(20, 10, 40, 8)
	assert_true(arena.grid.lay_trail(path), "pocket trail laid")
	e.position = arena.cell_to_world(path[15])  # embedded ON the trail (the device finding B5 repro)
	assert_eq(arena.cell_state(arena.world_to_cell(e.position)), CaptureGrid.Cell.TRAIL, "setup: on the trail")
	arena.close_capture(game.call("_enemy_cells"))  # real seed-correction, real evacuation via the signal
	assert_ne(arena.cell_state(arena.world_to_cell(e.position)), CaptureGrid.Cell.CAPTURED,
		"guard invariant: no active enemy left standing in captured territory")
	GameState.reset()


func test_enemy_cells_corrects_a_non_free_seed() -> void:
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	var arena: ArenaController = game.get_node("Arena")
	var enemies: Array = game.get("_enemies")
	var e: Enemy = enemies[0]
	assert_true(arena.grid.lay_trail([Vector2i(15, 15)]), "trail laid")
	arena.grid.close_and_capture([Vector2i(1, 1)])
	e.position = arena.cell_to_world(Vector2i(15, 15))  # now sits on a CAPTURED cell
	var cells: Array = game.call("_enemy_cells")
	assert_eq(cells.size(), enemies.size(), "one seed per active enemy")
	for c in cells:
		assert_eq(arena.cell_state(c), CaptureGrid.Cell.FREE, "every returned seed is FREE (corrected if needed)")
	GameState.reset()


func test_evacuate_moves_a_stuck_chaser() -> void:
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	var arena: ArenaController = game.get_node("Arena")
	var enemies: Array = game.get("_enemies")
	var e: Enemy = enemies[0]
	assert_true(arena.grid.lay_trail([Vector2i(15, 15)]), "trail laid")
	arena.grid.close_and_capture([Vector2i(1, 1)])
	e.position = arena.cell_to_world(Vector2i(15, 15))
	game.call("_evacuate_enemies_from_captured_cells")
	assert_ne(arena.cell_state(arena.world_to_cell(e.position)), CaptureGrid.Cell.CAPTURED,
		"non-edge-follow enemy evacuated off the captured cell")
	GameState.reset()


func test_sparx_self_heals_instead_of_being_evacuated() -> void:
	# Sparx isn't touched by the generic evacuation (a blind teleport would desync its internal
	# _grid_cell/_step_from/_step_to) -- it keeps its own, already-tested engulf self-heal.
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	GameState.start_run(3)
	assert_true(arena.grid.lay_trail([Vector2i(15, 15)]), "trail laid")
	arena.grid.close_and_capture([Vector2i(1, 1)])
	var s := Enemy.new()
	s.shape = Enemy.Shape.SQUARE
	add_child_autofree(s)
	var start := Vector2i(15, 15)
	s.setup(arena, arena.cell_to_world(start), Vector2.ZERO, null, 200.0, 0.0, true, start, Vector2i.DOWN)
	assert_true(s.is_edge_follow(), "setup: this is an edge-walker")
	assert_eq(arena.cell_state(arena.world_to_cell(s.position)), CaptureGrid.Cell.CAPTURED, "setup: engulfed")
	s.decide_velocity(arena.cell_to_world(Vector2i(40, 40)), false)
	s._physics_process(1.0 / 60.0)
	assert_true(s.is_contained(), "self-heals via its own engulf check, unrelated to game.gd's evacuation")
	GameState.reset()


# --- B6: periodic bounded trap re-check ---

func _sealed_column_arena() -> Dictionary:
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	var g: CaptureGrid = arena.grid
	var cols: int = g.cols
	var wall: Array = []
	for y in range(1, g.rows - 1):
		wall.append(Vector2i(cols - 5, y))
	g.lay_trail(wall)
	# Seed BOTH sides: the wall alone (not the seed choice) is what bounds the column's flood size,
	# so seeding the main area too keeps it FREE for tests that need open space elsewhere, without
	# changing whether the column itself is small enough to trap (fix-pass #20, B6).
	g.close_and_capture([Vector2i(cols - 3, 20), Vector2i(10, 10)])
	return {"arena": arena, "start": Vector2i(cols - 3, 20)}


func test_periodic_recheck_catches_a_sealed_pocket_without_a_capture_event() -> void:
	var setup: Dictionary = _sealed_column_arena()
	var arena: ArenaController = setup["arena"]
	var start: Vector2i = setup["start"]
	GameState.start_run(3)
	var s := Enemy.new()
	s.shape = Enemy.Shape.SQUARE
	s.trap_recheck_steps = 8  # short cadence so the test doesn't need thousands of steps
	add_child_autofree(s)
	s.setup(arena, arena.cell_to_world(start), Vector2.ZERO, null, 200.0, 0.0, true, start, Vector2i.DOWN)
	# Deliberately never call on_capture_event -- reproduces the pocket being sealed by a capture
	# whose event handling this Sparx missed (e.g. mid-TELEGRAPH).
	assert_false(s.is_contained(), "not contained yet -- no capture event has told it")
	for f in 400:
		s.decide_velocity(arena.cell_to_world(Vector2i(10, 40)), false)
		s._physics_process(1.0 / 60.0)
		if s.is_contained():
			break
	assert_true(s.is_contained(), "periodic bounded recheck eventually catches the sealed pocket")
	GameState.reset()


func test_trap_recheck_can_be_disabled() -> void:
	var setup: Dictionary = _sealed_column_arena()
	var arena: ArenaController = setup["arena"]
	var start: Vector2i = setup["start"]
	GameState.start_run(3)
	var s := Enemy.new()
	s.shape = Enemy.Shape.SQUARE
	s.trap_recheck_steps = 0  # disabled
	add_child_autofree(s)
	s.setup(arena, arena.cell_to_world(start), Vector2.ZERO, null, 200.0, 0.0, true, start, Vector2i.DOWN)
	for f in 800:
		s.decide_velocity(arena.cell_to_world(Vector2i(10, 40)), false)
		s._physics_process(1.0 / 60.0)
	assert_false(s.is_contained(), "disabled -> stays patrolling forever, matching pre-#20 behavior")
	GameState.reset()


func test_periodic_recheck_no_false_positive_in_open_arena() -> void:
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	GameState.start_run(3)
	var start := Vector2i(1, 5)
	var s := Enemy.new()
	s.shape = Enemy.Shape.SQUARE
	s.trap_recheck_steps = 4  # aggressive cadence -- should still never misfire in the open arena
	add_child_autofree(s)
	s.setup(arena, arena.cell_to_world(start), Vector2.ZERO, null, 200.0, 0.0, true, start, Vector2i.DOWN)
	for f in 600:
		s.decide_velocity(arena.cell_to_world(Vector2i(40, 40)), false)
		s._physics_process(1.0 / 60.0)
	assert_false(s.is_contained(), "wide-open arena is never mistaken for a small pocket")
	GameState.reset()


func test_periodic_recheck_never_touches_a_live_trail() -> void:
	# Correctness hazard check: the periodic path must NEVER call close_capture (that would wrongly
	# finalize a live, unclosed player trail if it fired mid-draw).
	var setup: Dictionary = _sealed_column_arena()
	var arena: ArenaController = setup["arena"]
	var start: Vector2i = setup["start"]
	var g: CaptureGrid = arena.grid
	var live_trail: Array = [Vector2i(10, 40), Vector2i(10, 41), Vector2i(10, 42)]
	assert_true(g.lay_trail(live_trail), "a SEPARATE, still-live player trail elsewhere on the board")
	GameState.start_run(3)
	var s := Enemy.new()
	s.shape = Enemy.Shape.SQUARE
	s.trap_recheck_steps = 8
	add_child_autofree(s)
	s.setup(arena, arena.cell_to_world(start), Vector2.ZERO, null, 200.0, 0.0, true, start, Vector2i.DOWN)
	for f in 200:
		s.decide_velocity(arena.cell_to_world(Vector2i(10, 40)), false)
		s._physics_process(1.0 / 60.0)
		if s.is_contained():
			break
	assert_true(s.is_contained(), "periodic recheck still fires")
	for c in live_trail:
		assert_eq(g.cell_at(c.x, c.y), CaptureGrid.Cell.TRAIL, "the live player trail is untouched")
	GameState.reset()


# --- B7: roam axis-unstick ---

func _chaser(arena: ArenaController, cell: Vector2i, velocity: Vector2) -> Enemy:
	var e := Enemy.new()
	e.shape = Enemy.Shape.TRIANGLE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(cell), velocity, ChaserBehavior.new(), 150.0)
	return e


func _wall_split_arena() -> ArenaController:
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	var g: CaptureGrid = arena.grid
	var wall: Array = []
	for x in range(1, 60):
		wall.append(Vector2i(x, 50))
	g.lay_trail(wall)
	g.close_and_capture([Vector2i(20, 30), Vector2i(20, 80)])
	return arena


func test_unstick_axis_pure() -> void:
	var nudged: Vector2 = EnemyMotion.unstick_axis(Vector2(150, 0), 150.0, 0.5, 0.08)
	assert_gt(absf(nudged.x), 0.0)
	assert_gt(absf(nudged.y), 0.0)
	assert_almost_eq(nudged.length(), 150.0, 0.01, "renormalized to base_speed")
	var diag := Vector2(-90, -120)
	assert_eq(EnemyMotion.unstick_axis(diag, 150.0, 0.0, 0.08), diag, "already-diagonal -> unchanged")
	assert_eq(EnemyMotion.unstick_axis(Vector2(150, 0), 150.0, 0.5, 0.0), Vector2(150, 0), "ratio<=0 -> disabled")
	assert_eq(EnemyMotion.unstick_axis(Vector2(150, 0), 0.0, 0.5, 0.08), Vector2(150, 0), "base_speed<=0 -> disabled")
	var a: Vector2 = EnemyMotion.unstick_axis(Vector2(0, 150), 150.0, 0.7, 0.08)
	var b: Vector2 = EnemyMotion.unstick_axis(Vector2(0, 150), 150.0, 0.7, 0.08)
	assert_eq(a, b, "deterministic")
	var pos_var: Vector2 = EnemyMotion.unstick_axis(Vector2(0, 150), 150.0, 0.5, 0.08)
	var neg_var: Vector2 = EnemyMotion.unstick_axis(Vector2(0, 150), 150.0, -0.5, 0.08)
	assert_ne(pos_var.x, neg_var.x, "variation sign picks the fallback axis when the input axis is exactly 0")
	var zero: Vector2 = EnemyMotion.unstick_axis(Vector2.ZERO, 150.0, 0.0, 0.08)
	assert_almost_eq(zero.length(), 150.0, 0.01, "no heading at all -> still picks a diagonal")


func test_roam_gets_unstuck_axis() -> void:
	var arena := _wall_split_arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 75), Vector2(0, -150))  # axis-locked, blind (behind the wall)
	var behind: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	var v: Vector2 = c.decide_velocity(behind, true)
	assert_ne(v, c.get("_velocity"), "axis-locked roam gets nudged off its heading")
	assert_gt(absf(v.x), 0.0, "now has a real x component")
	assert_almost_eq(v.length(), 150.0, 0.5, "still base speed")
	GameState.reset()


func test_homing_toward_the_same_column_is_not_mistaken_for_roam() -> void:
	# Regression guard for the exposed-based (not equality-based) roam heuristic: a genuinely
	# visible target straight ahead makes the raw homing vector COINCIDENTALLY equal the current
	# axis-aligned heading -- that must NOT be treated as roam and nudged off course.
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 60), Vector2(0, -150))
	var head: Vector2 = arena.cell_to_world(Vector2i(20, 20))  # same column, clear line of sight
	var v: Vector2 = c.decide_velocity(head, true)
	assert_eq(v, Vector2(0, -150), "genuine homing straight up is left exactly as computed")
	GameState.reset()


func test_bouncer_never_unstuck() -> void:
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	GameState.start_run(3)
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(20, 60)), Vector2(150, 0), BouncerBehavior.new(), 150.0)
	assert_eq(e.decide_velocity(arena.cell_to_world(Vector2i(99, 99)), true), Vector2(150, 0),
		"bouncer's identical-heading passthrough is its own physical bounce, never nudged")
	GameState.reset()


func test_axis_lock_ratio_zero_disables_unstick() -> void:
	var arena := _wall_split_arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 75), Vector2(0, -150))
	c.axis_lock_ratio = 0.0
	var behind: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	assert_eq(c.decide_velocity(behind, true), Vector2(0, -150), "knob off -> old axis-locked roam")
	GameState.reset()


func test_roam_no_longer_pings_purely_on_one_axis() -> void:
	# Device finding B7 regression: without any territory push (isolates this fix from PushEffect,
	# which the original device diagnosis also had applied), a purely axis-locked roaming chaser
	# used to bounce along a single axis forever (zero x-variety).
	var arena := _wall_split_arena()
	GameState.start_run(3)
	var effect := TerritoryEffect.new()  # base no-op
	var c := _chaser(arena, Vector2i(20, 75), Vector2(0, -150))
	var target: Vector2 = arena.cell_to_world(Vector2i(20, 20))  # behind the wall -> always roam
	var min_x: float = INF
	var max_x: float = -INF
	for f in 300:
		c.apply_territory(effect, arena, c.decide_velocity(target, true))
		c._physics_process(1.0 / 60.0)
		min_x = minf(min_x, c.position.x)
		max_x = maxf(max_x, c.position.x)
	assert_gt(max_x - min_x, arena.cell_size * 3.0, "no longer pinned to a single vertical line")
	GameState.reset()
