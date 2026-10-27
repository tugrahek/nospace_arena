extends GutTest

## Pause behavior is integration (SceneTree.paused + node freeze), so these instantiate
## real scenes. after_each always unpauses so a failure can't leave the tree paused.

const LEADERBOARD_PATH: String = "user://leaderboard.json"
var _restore_board: bool = false
var _old_board_existed: bool = false
var _old_board: String = ""


func after_each() -> void:
	get_tree().paused = false
	GameState.reset()
	SeedManager.exit_daily()
	if _restore_board:
		if _old_board_existed:
			_write_board(_old_board)
		else:
			DirAccess.remove_absolute(LEADERBOARD_PATH)
	_restore_board = false


func test_overlay_toggles_pause_both_ways() -> void:
	GameState.start_run(3)  # is_playing() -> pause() is allowed
	var ov: CanvasLayer = load("res://scenes/ui/PauseOverlay.tscn").instantiate()
	add_child_autofree(ov)
	await get_tree().process_frame
	ov.pause()
	assert_true(get_tree().paused, "pause çalışır")
	ov.toggle()
	assert_false(get_tree().paused, "Esc/toggle devam ettirir (çift yönlü)")


func test_pause_freezes_combo_clock() -> void:
	# The combo window now runs on accumulated game time (physics steps), not the wall clock:
	# pausing must freeze it so a paused player can't lose (or exploit) the combo window.
	SeedManager.enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var t1: float = game.get("_run_time")
	assert_gt(t1, 0.0, "oyun-zamanı fizik kareleriyle ilerliyor")
	get_tree().paused = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var t2: float = game.get("_run_time")
	get_tree().paused = false  # restore before asserting (never leave tree paused)
	assert_eq(t2, t1, "pause'da kombo saati durur (skor adaleti)")


func test_daily_pause_and_submission_preserve_legacy_scores_without_tracks() -> void:
	_old_board_existed = FileAccess.file_exists(LEADERBOARD_PATH)
	_old_board = FileAccess.get_file_as_string(LEADERBOARD_PATH) if _old_board_existed else ""
	_restore_board = true
	SeedManager.enter_daily()
	var day: String = str(SeedManager.daily_seed)
	var legacy: Dictionary = {"19990101": {"score": 700, "track": [[1, 2]]}}
	legacy[day] = {"score": 200, "track": "obsolete data"}
	var original: String = JSON.stringify(legacy)
	_write_board(original)
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(game.get("_leaderboard").best_score(SeedManager.daily_seed), 200)
	assert_eq(game.get_node("HUD").get("_best_score"), 200)
	var before: float = game.get("_run_time")
	get_tree().paused = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(game.get("_run_time"), before, "Daily scoring clock remains frozen")
	get_tree().paused = false  # restore before asserting (never leave tree paused)
	game.call("_submit_run", 200)
	assert_eq(FileAccess.get_file_as_string(LEADERBOARD_PATH), original, "tie does not rewrite old data")
	game.call("_submit_run", 250)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEADERBOARD_PATH))
	assert_eq(saved["19990101"], {"score": 700.0})
	assert_eq(saved[day], {"score": 250.0})
	assert_eq(game.get_node("HUD").get("_best_score"), 250)


func _write_board(text: String) -> void:
	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
