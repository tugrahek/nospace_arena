extends GutTest

## Fix-Pass #7: crossing your own active trail (non-adjacent) = life loss (self_hit). Backtracking
## (stepping onto the immediately-previous trail cell) and returning to CAPTURED stay safe.

func _frost() -> ArenaController:
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	return arena


func _player_on(arena: ArenaController, cell: Vector2i) -> Player:
	var p := Player.new()
	add_child_autofree(p)
	p.setup(arena)
	p.set("_grid_pos", cell)  # a CAPTURED border cell adjacent to the interior
	p.set("_safe_cell", cell)
	return p


func _step(p: Player, dir: Vector2i) -> void:
	p.set("_direction", dir)
	p.call("_try_step")


func test_self_cross_emits_self_hit() -> void:
	var arena := _frost()
	GameState.start_run(3)
	var p := _player_on(arena, Vector2i(1, 0))
	watch_signals(p)
	_step(p, Vector2i.DOWN)   # (1,1) FREE -> start drawing
	_step(p, Vector2i.DOWN)   # (1,2)
	_step(p, Vector2i.RIGHT)  # (2,2)
	_step(p, Vector2i.UP)     # (2,1)
	_step(p, Vector2i.LEFT)   # target (1,1) = own trail, non-adjacent -> self_hit
	assert_signal_emitted(p, "self_hit")
	assert_eq(p.get("_grid_pos"), Vector2i(2, 1), "does not enter the crossed trail cell")
	GameState.reset()


func test_backtrack_is_safe() -> void:
	var arena := _frost()
	GameState.start_run(3)
	var p := _player_on(arena, Vector2i(1, 0))
	watch_signals(p)
	_step(p, Vector2i.DOWN)   # (1,1)
	_step(p, Vector2i.DOWN)   # (1,2)
	_step(p, Vector2i.UP)     # target (1,1) = immediate-previous -> backtrack (undo)
	assert_signal_not_emitted(p, "self_hit", "backtrack is not a self-cross")
	assert_eq(p.get("_grid_pos"), Vector2i(1, 1), "backtracked")
	var trail: Array = p.get("_trail_path")
	assert_eq(trail.size(), 1, "last trail cell undone")
	GameState.reset()


func test_return_to_captured_closes_loop_not_death() -> void:
	var arena := _frost()
	GameState.start_run(3)
	var p := _player_on(arena, Vector2i(1, 0))
	watch_signals(p)
	_step(p, Vector2i.DOWN)   # (1,1)
	_step(p, Vector2i.DOWN)   # (1,2)
	_step(p, Vector2i.LEFT)   # target (0,2) CAPTURED -> close loop, not death
	assert_signal_emitted(p, "loop_closed")
	assert_signal_not_emitted(p, "self_hit", "closing on captured is not a self-cross")
	GameState.reset()
