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
