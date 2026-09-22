extends GutTest

## Fix-pass #18 (device bugs B1/B2/B3): Sparx catches on CHEBYSHEV adjacency from the drawn cell
## (corner immunity gone), death_grace is the only post-death invulnerability, the Chaser hunts
## only what it can SEE (no more pinning against a wall), and the HUD leaves room for the pause
## button. Balance change is deliberate and approved.

const EnemyMotion = preload("res://scripts/gameplay/enemy_motion.gd")
const CAPTURED: int = 1  # CaptureGrid.Cell.CAPTURED


func after_each() -> void:
	for c in get_children():
		if c is CPUParticles2D:
			c.free()


func _arena(res: String) -> ArenaController:
	var a := ArenaController.new()
	add_child_autofree(a)
	a.configure(load(res), Rect2(40, 100, 640, 1100))
	return a


func _sparx(arena: ArenaController, cell: Vector2i, heading: Vector2i = Vector2i.DOWN) -> Enemy:
	var e := Enemy.new()
	e.shape = Enemy.Shape.SQUARE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(cell), Vector2.ZERO, null, 200.0, 0.0, true, cell, heading)
	return e


# --- B1: Sparx adjacency ---

func test_sparx_kills_player_parked_on_a_corner() -> void:
	# The wall-follower rounds a corner DIAGONALLY, so with the old Manhattan test a player parked
	# on the frame corner was immune while the drawn bodies overlapped. Regression guard.
	var arena := _arena("res://resources/arenas/arena_void.tres")
	GameState.start_run(3)
	var rows: int = arena.grid.rows
	var corner: Vector2 = arena.cell_to_world(Vector2i(0, rows - 1))
	var s := _sparx(arena, Vector2i(1, rows - 20))
	watch_signals(s)
	var min_px: float = INF
	for f in 90:
		s.decide_velocity(corner, false)
		s._physics_process(1.0 / 60.0)
		min_px = minf(min_px, s.position.distance_to(corner))
	assert_gt(get_signal_emit_count(s, "hit_trail"), 0, "sparx passing the corner is lethal")
	assert_lt(min_px, arena.cell_size * 2.0, "it really did pass right next to the player")
	GameState.reset()


func test_sparx_diagonal_neighbour_kills_two_cells_away_does_not() -> void:
	var arena := _arena("res://resources/arenas/arena_void.tres")
	GameState.start_run(3)
	var cell := Vector2i(1, 5)
	var diagonal := _sparx(arena, cell)
	watch_signals(diagonal)
	diagonal.decide_velocity(arena.cell_to_world(cell + Vector2i(-1, -1)), false)
	diagonal._physics_process(0.01)
	assert_signal_emitted(diagonal, "hit_trail", "diagonal contact is lethal (chebyshev)")
	var far := _sparx(arena, cell)
	watch_signals(far)
	far.decide_velocity(arena.cell_to_world(cell + Vector2i(2, 1)), false)
	far._physics_process(0.01)
	assert_signal_emit_count(far, "hit_trail", 0, "two cells away is still safe")
	GameState.reset()


func test_sparx_catch_uses_the_drawn_cell() -> void:
	# Mid-step the body is drawn between cells; lethality follows the DRAWN cell, so a player
	# adjacent to where the square actually is gets caught even before it "arrives".
	var arena := _arena("res://resources/arenas/arena_void.tres")
	GameState.start_run(3)
	var s := _sparx(arena, Vector2i(1, 5))
	var drawn: Vector2i = arena.world_to_cell(s.position)
	var found: bool = false
	for f in 60:  # walk until the body is drawn past the cell it last arrived on
		s.decide_velocity(arena.cell_to_world(Vector2i(40, 40)), false)  # player far away
		s._physics_process(1.0 / 60.0)
		drawn = arena.world_to_cell(s.position)
		if drawn != s.get("_grid_cell"):
			found = true
			break
	assert_true(found, "setup: found a frame where the drawn cell leads the arrived cell")
	watch_signals(s)
	s.decide_velocity(arena.cell_to_world(drawn + Vector2i(1, 0)), false)
	s._physics_process(0.01)
	assert_signal_emitted(s, "hit_trail", "neighbour of the DRAWN cell is caught")
	GameState.reset()


## Drops the start grace (player "has moved") so a test can exercise the lethal paths.
func _clear_start_grace(game: Node) -> void:
	game.get_node("Player").set("_has_moved", true)
	game.set("_awaiting_first_move", false)
	game.set("_death_grace_timer", 0.0)


func test_start_grace_holds_until_the_first_step() -> void:
	# Chebyshev catches made the spawn corner reachable: a still player must never lose a life
	# before they have moved, however long they sit there.
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	var lives0: int = GameState.lives
	for f in 120:  # 2 seconds of physics, player never steps
		game._physics_process(1.0 / 60.0)
	game.call("_on_trail_failed")
	assert_eq(GameState.lives, lives0, "no life lost while parked at the start")
	assert_gt(float(game.get("_death_grace_timer")), 0.0, "grace held, not counting down")
	GameState.reset()


func test_start_grace_expires_after_the_first_step() -> void:
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	var lives0: int = GameState.lives
	game.get_node("Player").set("_has_moved", true)  # first step taken
	for f in 120:  # grace now counts down (start_grace_duration = 1.0s)
		game._physics_process(1.0 / 60.0)
	assert_lt(float(game.get("_death_grace_timer")), 0.001, "grace expired once the player moved")
	game.call("_on_trail_failed")
	assert_eq(GameState.lives, lives0 - 1, "lethal again after the grace")
	GameState.reset()


func test_respawn_rearms_the_start_grace() -> void:
	# Same fairness after a death: the player is parked again, so the window re-holds.
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	_clear_start_grace(game)
	game.call("_on_trail_failed")  # costs one life, respawns, re-arms
	var lives1: int = GameState.lives
	for f in 120:
		game._physics_process(1.0 / 60.0)
	game.call("_on_trail_failed")
	assert_eq(GameState.lives, lives1, "parked after respawn -> still invulnerable")
	GameState.reset()


func test_death_grace_still_owns_chain_kills() -> void:
	# With the Sparx cooldown gone, the game's i-frames must still absorb repeat hits — and the
	# player must be lethal again as soon as the grace expires (the old bug disarmed the sparx).
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	var lives0: int = GameState.lives
	_clear_start_grace(game)
	game.call("_on_trail_failed")
	game.call("_on_trail_failed")
	assert_eq(GameState.lives, lives0 - 1, "grace absorbs the repeat hit")
	_clear_start_grace(game)  # grace expired + player moved again
	game.call("_on_trail_failed")
	assert_eq(GameState.lives, lives0 - 2, "lethal again the moment the grace ends")
	GameState.reset()


# --- B2: line of sight ---

func test_line_of_sight_pure() -> void:
	var cols: int = 8
	var cells := PackedByteArray()
	cells.resize(cols * 8)
	assert_true(EnemyMotion.line_of_sight(cells, cols, Vector2i(1, 1), Vector2i(6, 6), CAPTURED),
		"open board -> sighted")
	assert_true(EnemyMotion.line_of_sight(cells, cols, Vector2i(3, 3), Vector2i(3, 3), CAPTURED),
		"same cell -> sighted")
	assert_true(EnemyMotion.line_of_sight(cells, cols, Vector2i(3, 3), Vector2i(3, 4), CAPTURED),
		"neighbour -> sighted")
	for x in cols:  # captured wall across row 4
		cells[4 * cols + x] = CAPTURED
	assert_false(EnemyMotion.line_of_sight(cells, cols, Vector2i(3, 1), Vector2i(3, 7), CAPTURED),
		"wall between -> blind")
	assert_true(EnemyMotion.line_of_sight(cells, cols, Vector2i(1, 1), Vector2i(5, 3), CAPTURED),
		"same side of the wall -> sighted")
	cells[4 * cols + 3] = 0  # a gap in the wall
	assert_true(EnemyMotion.line_of_sight(cells, cols, Vector2i(3, 1), Vector2i(3, 7), CAPTURED),
		"straight through the gap -> sighted")
	var target_blocked := PackedByteArray()
	target_blocked.resize(cols * 8)
	target_blocked[2 * cols + 5] = CAPTURED
	assert_true(EnemyMotion.line_of_sight(target_blocked, cols, Vector2i(5, 0), Vector2i(5, 2), CAPTURED),
		"the target cell itself never blocks")


func test_trail_does_not_block_sight() -> void:
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	arena.grid.lay_trail([Vector2i(20, 40), Vector2i(20, 41), Vector2i(20, 42)])
	var g: CaptureGrid = arena.grid
	assert_true(EnemyMotion.line_of_sight(g.cells(), g.cols, Vector2i(20, 30), Vector2i(20, 50), CAPTURED),
		"the player's trail is a target, not cover")


func _walled_arena() -> ArenaController:
	# Captured wall on row 50 (x 1..50): player above, chaser below (the device-bug geometry).
	var arena := _arena("res://resources/arenas/arena_frost.tres")
	var wall: Array = []
	for x in range(1, 51):
		wall.append(Vector2i(x, 50))
	arena.grid.lay_trail(wall)
	arena.grid.close_and_capture([Vector2i(20, 30), Vector2i(20, 80)])
	return arena


func _chaser(arena: ArenaController, cell: Vector2i) -> Enemy:
	var e := Enemy.new()
	e.shape = Enemy.Shape.TRIANGLE
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(cell), Vector2(0, -150), ChaserBehavior.new(), 150.0)
	return e


func test_chaser_roams_when_blind_homes_when_seen() -> void:
	var arena := _walled_arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 75))
	var behind: Vector2 = arena.cell_to_world(Vector2i(20, 20))  # other side of the wall
	assert_eq(c.decide_velocity(behind, true), c.get("_velocity"), "blind -> roam (keeps heading)")
	var open: Vector2 = arena.cell_to_world(Vector2i(30, 70))  # same side, clear line
	var v: Vector2 = c.decide_velocity(open, true)
	assert_ne(v, c.get("_velocity"), "clear line -> homes")
	assert_gt(v.x, 0.0, "homes toward the visible player")
	GameState.reset()


func test_chaser_no_longer_pins_itself_on_the_wall() -> void:
	# Device bug B2 reproduction: aligned player behind the wall. Before the fix the chaser
	# oscillated on the wall face (~3 px net over 180 frames); now it roams away.
	var arena := _walled_arena()
	GameState.start_run(3)
	var effect := TerritoryEffect.new()
	var c := _chaser(arena, Vector2i(20, 75))
	var player: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	var start: Vector2 = c.position
	for f in 180:
		c.apply_territory(effect, arena, c.decide_velocity(player, true))
		c._physics_process(1.0 / 60.0)
	assert_gt(c.position.distance_to(start), arena.cell_size * 4.0, "left the wall instead of pinning")
	GameState.reset()


func test_sight_gate_can_be_disabled() -> void:
	# requires_line_of_sight = false restores the pre-fix blind homing exactly.
	var arena := _walled_arena()
	GameState.start_run(3)
	var c := _chaser(arena, Vector2i(20, 75))
	var behavior: ChaserBehavior = c.get("_behavior")
	behavior.requires_line_of_sight = false
	var behind: Vector2 = arena.cell_to_world(Vector2i(32, 20))  # offset so homing != current heading
	var v: Vector2 = c.decide_velocity(behind, true)
	assert_ne(v, c.get("_velocity"), "knob off -> homes through the wall (old behavior)")
	assert_lt(v.y, 0.0, "homes upward toward the player")
	assert_gt(v.x, 0.0, "and sideways toward them — the wall is ignored")
	GameState.reset()


func test_bouncer_ignores_the_sight_gate() -> void:
	var arena := _walled_arena()
	GameState.start_run(3)
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(20, 75)), Vector2(10, -150), BouncerBehavior.new(), 150.0)
	var behind: Vector2 = arena.cell_to_world(Vector2i(20, 20))
	assert_eq(e.decide_velocity(behind, true), Vector2(10, -150), "bouncer keeps its heading either way")
	GameState.reset()


# --- B3: HUD layout ---

func test_hud_leaves_room_for_the_pause_button() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/HUD.tscn").instantiate()
	var pause: CanvasLayer = load("res://scenes/ui/PauseOverlay.tscn").instantiate()
	add_child_autofree(hud)
	add_child_autofree(pause)
	await get_tree().process_frame
	await get_tree().process_frame
	var button: Control = pause.get_node("PauseButton")
	var score: Control = hud.get_node("TopBar/ScoreLabel")
	var daily: Control = hud.get_node("DailyLabel")
	assert_false(button.get_global_rect().intersects(score.get_global_rect()),
		"pause button no longer covers the score")
	assert_false(button.get_global_rect().intersects(daily.get_global_rect()),
		"pause button no longer covers the daily badge")
	assert_lt(score.get_global_rect().end.x, button.get_global_rect().position.x,
		"score sits left of the button")
