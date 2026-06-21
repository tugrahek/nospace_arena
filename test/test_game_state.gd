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


func test_register_capture_adds_score_and_emits() -> void:
	_gs.start_run(3)
	watch_signals(_gs)
	var earned: int = _gs.register_capture(5, 0.0)
	assert_eq(earned, 50, "5 cells * 10 pts * x1")
	assert_eq(_gs.get_score(), 50)
	assert_signal_emitted_with_parameters(_gs, "score_changed", [50, 0])


func test_win_run_transitions_to_won_and_emits() -> void:
	_gs.start_run(3)
	_gs.register_capture(1, 0.0)  # score = 10
	watch_signals(_gs)
	_gs.win_run()
	assert_false(_gs.is_playing())
	assert_signal_emitted(_gs, "run_won")


func test_game_over_carries_real_score() -> void:
	_gs.start_run(1)
	_gs.register_capture(5, 0.0)  # score = 50
	watch_signals(_gs)
	_gs.lose_life()
	assert_signal_emitted_with_parameters(_gs, "game_over", [50])


func test_register_capture_noop_when_not_playing() -> void:
	var earned: int = _gs.register_capture(10, 0.0)
	assert_eq(earned, 0)
	assert_eq(_gs.get_score(), 0)


func test_capture_includes_exposed_bonus() -> void:
	_gs.start_run(3, 10, 2.0, 10.0, 10.0, 400)
	# 1 cell * 10 * x1 = 10 + floor(3 * 10) = 30 -> 40
	assert_eq(_gs.register_capture(1, 0.0, 3.0), 40)
	assert_eq(_gs.get_score(), 40)


func test_lose_life_applies_penalty() -> void:
	_gs.start_run(3, 10, 2.0, 0.0, 0.0, 400)
	_gs.register_capture(100, 0.0)  # 1000
	watch_signals(_gs)
	_gs.lose_life()
	assert_eq(_gs.get_score(), 600, "penalty 400 applied")
	assert_signal_emitted(_gs, "score_changed")
