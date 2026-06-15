extends GutTest

const GameStateScript = preload("res://scripts/autoload/GameState.gd")

var _gs


func before_each() -> void:
	_gs = GameStateScript.new()


func after_each() -> void:
	_gs.free()


func test_start_run_sets_lives_and_playing() -> void:
	watch_signals(_gs)
	_gs.start_run(3)
	assert_eq(_gs.lives, 3)
	assert_true(_gs.is_playing())
	assert_signal_emitted(_gs, "game_started")


func test_lose_life_decrements_and_emits() -> void:
	_gs.start_run(3)
	watch_signals(_gs)
	var remaining: int = _gs.lose_life()
	assert_eq(remaining, 2)
	assert_eq(_gs.lives, 2)
	assert_signal_emitted_with_parameters(_gs, "life_lost", [2])


func test_game_over_at_zero() -> void:
	_gs.start_run(1)
	watch_signals(_gs)
	_gs.lose_life()
	assert_eq(_gs.lives, 0)
	assert_false(_gs.is_playing())
	assert_signal_emitted(_gs, "game_over")


func test_lose_life_noop_when_not_playing() -> void:
	assert_eq(_gs.lose_life(), 0, "IDLE iken no-op")
	_gs.start_run(1)
	_gs.lose_life()  # -> GAME_OVER
	assert_eq(_gs.lose_life(), 0, "GAME_OVER iken no-op")


func test_reset_restores_idle() -> void:
	_gs.start_run(3)
	_gs.reset()
	assert_eq(_gs.lives, 0)
	assert_false(_gs.is_playing())
