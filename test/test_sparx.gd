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
