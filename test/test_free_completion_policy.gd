extends GutTest

const FreeCompletionPolicy = preload("res://scripts/meta/free_completion_policy.gd")
const BALANCE: BalanceConfig = preload("res://config/balance.tres")


func test_free_target_is_ninety_nine_for_every_arena() -> void:
	for arena in ContentCatalog.ARENAS:
		var target: float = FreeCompletionPolicy.target_for(
			SeedManager.Mode.FREE, arena.target_percent, BALANCE.free_completion_percent)
		assert_almost_eq(target, 99.0, 0.0001, "%s Free target" % arena.id)


func test_daily_keeps_each_shared_arena_target() -> void:
	for arena in ContentCatalog.ARENAS:
		var target: float = FreeCompletionPolicy.target_for(
			SeedManager.Mode.DAILY, arena.target_percent, BALANCE.free_completion_percent)
		assert_almost_eq(target, arena.target_percent, 0.0001, "%s Daily target unchanged" % arena.id)


func test_old_free_arena_thresholds_are_not_terminal() -> void:
	assert_false(FreeCompletionPolicy.is_reached(75.0, BALANCE.free_completion_percent), "Void's old 75% is not terminal")
	assert_false(FreeCompletionPolicy.is_reached(70.0, BALANCE.free_completion_percent), "Ember's old 70% is not terminal")
	assert_false(FreeCompletionPolicy.is_reached(80.0, BALANCE.free_completion_percent), "Frost's old 80% is not terminal")


func test_raw_percent_boundary_does_not_use_hud_rounding() -> void:
	assert_false(FreeCompletionPolicy.is_reached(98.49, BALANCE.free_completion_percent))
	assert_false(FreeCompletionPolicy.is_reached(98.99, BALANCE.free_completion_percent))
	assert_true(FreeCompletionPolicy.is_reached(99.0, BALANCE.free_completion_percent))
	assert_true(FreeCompletionPolicy.is_reached(99.01, BALANCE.free_completion_percent))


func test_terminal_event_is_idempotent_after_the_free_boundary() -> void:
	GameState.reset()
	watch_signals(GameState)
	GameState.start_run(3)
	if FreeCompletionPolicy.is_reached(99.0, BALANCE.free_completion_percent):
		GameState.win_run()
	if FreeCompletionPolicy.is_reached(99.01, BALANCE.free_completion_percent):
		GameState.win_run()
	assert_signal_emit_count(GameState, "run_won", 1, "terminal event is emitted once")
	GameState.reset()
