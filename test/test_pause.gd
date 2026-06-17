extends GutTest

## Pause behavior is integration (SceneTree.paused + node freeze), so these instantiate
## real scenes. after_each always unpauses so a failure can't leave the tree paused.


func after_each() -> void:
	get_tree().paused = false
	GameState.reset()
	SeedManager.exit_daily()


func test_overlay_toggles_pause_both_ways() -> void:
	GameState.start_run(3)  # is_playing() -> pause() is allowed
	var ov: CanvasLayer = load("res://scenes/ui/PauseOverlay.tscn").instantiate()
	add_child_autofree(ov)
	await get_tree().process_frame
	ov.pause()
	assert_true(get_tree().paused, "pause çalışır")
	ov.toggle()
	assert_false(get_tree().paused, "Esc/toggle devam ettirir (çift yönlü)")


func test_pause_stops_ghost_recording() -> void:
	SeedManager.enter_daily()  # recording runs only in daily
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var c1: int = game.recording_frame_count()
	assert_gt(c1, 0, "daily'de ghost kaydı ilerliyor")
	get_tree().paused = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var c2: int = game.recording_frame_count()
	get_tree().paused = false  # restore before asserting (never leave tree paused)
	assert_eq(c2, c1, "pause'da kare eklenmiyor -> determinizm korunur")
