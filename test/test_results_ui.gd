extends GutTest

const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const RESULT_ART: Script = preload("res://scripts/ui/result_territory_art.gd")
const GAME_SCENE: PackedScene = preload("res://scenes/main/Game.tscn")


func before_each() -> void:
	TranslationServer.set_locale("en")


func after_each() -> void:
	TranslationServer.set_locale("en")


func _hud() -> HUD:
	var hud: HUD = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	hud.setup(3)
	hud.set_target(75.0)
	hud.update_percent(62.0)
	return hud


func test_loss_result_binds_real_score_and_capture_state() -> void:
	var hud: HUD = await _hud()
	hud.call("_on_game_over", 1234)
	var art: Control = hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ResultArt")
	assert_true(hud.get_node("ResultPanel").visible, "loss shows results")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/TitleLabel").text, tr("RESULT_LOSE"))
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ScoreCaption").text, tr("HUD_SCORE"))
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ResultScore").text, "1234")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ProgressLabel").text, "62 / 75%")
	assert_true(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ProgressLabel").visible, "real target progress is shown on loss")
	assert_lte(art.custom_minimum_size.y, 70.0, "loss uses a compact progress motif")
	assert_almost_eq(float(art.get("completion_percent")), 62.0, 0.01, "result art uses real capture percent")
	assert_almost_eq(float(art.get("target_percent")), 75.0, 0.01, "result art uses real target percent")
	assert_false(bool(art.get("won")), "loss retains its result state")
	assert_false(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/NextButton").visible, "loss has no next action")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/RetryButton").theme_type_variation,
		&"HeroButton", "retry is primary on loss")


func test_arabic_progress_keeps_ltr_numbers_inside_rtl_results() -> void:
	TranslationServer.set_locale("ar")
	var hud: HUD = await _hud()
	hud.set_target(70.0)
	hud.call("_on_game_over", 1234)
	var panel: Control = hud.get_node("ResultPanel")
	var progress: Label = panel.get_node("SafeArea/Bounds/VBox/ProgressLabel")
	assert_true(panel.is_layout_rtl(), "Results layout remains Arabic RTL")
	assert_eq(progress.text_direction, Control.TEXT_DIRECTION_LTR, "only numeric progress is LTR")
	assert_eq(progress.text, "62 / 70%", "loss values and format stay unchanged")
	hud.update_percent(74.0)
	hud.call("_on_run_won", 2600)
	assert_eq(progress.text, "74 / 70%", "win values and format stay unchanged")
	assert_true(panel.is_layout_rtl())


func test_win_result_keeps_completion_and_campaign_star_binding() -> void:
	var hud: HUD = await _hud()
	hud.set_target(70.0)
	hud.update_percent(74.0)
	hud.call("_on_run_won", 2600)
	var art: Control = hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ResultArt")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/TitleLabel").text, tr("RESULT_WIN"))
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ResultScore").text, "2600")
	assert_true(bool(art.get("won")), "win retains its result state")
	assert_almost_eq(float(art.get("completion_percent")), 74.0, 0.01, "win never invents 100 percent")
	assert_almost_eq(float(art.get("target_percent")), 70.0, 0.01, "win retains the independent target")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ProgressLabel").text, "74 / 70%")
	assert_lte(art.custom_minimum_size.y, 70.0, "win keeps the progress motif compact")
	hud.star_stagger = 0.01
	hud.show_campaign_stars(2, false, true)
	await get_tree().create_timer(0.08).timeout
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/StarsLabel").text, "★★☆", "campaign stars keep their earned value")
	assert_true(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/NextButton").visible, "campaign next remains available")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/RetryButton").theme_type_variation,
		&"Secondary", "campaign next keeps retry secondary")


func test_win_without_next_keeps_retry_primary_and_optional_labels_collapsed() -> void:
	var hud: HUD = await _hud()
	hud.call("_on_run_won", 1700)
	assert_false(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/NextButton").visible)
	assert_false(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/StarsLabel").visible)
	assert_false(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/NewBestLabel").visible)
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/RetryButton").theme_type_variation,
		&"HeroButton", "retry becomes primary when there is no next level")


func test_result_actions_keep_retry_menu_and_next_signals() -> void:
	var hud: HUD = await _hud()
	var counts := {"retry": 0, "menu": 0, "next": 0}
	hud.retry_pressed.connect(func() -> void: counts["retry"] += 1)
	hud.menu_pressed.connect(func() -> void: counts["menu"] += 1)
	hud.next_pressed.connect(func() -> void: counts["next"] += 1)
	hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/RetryButton").emit_signal("pressed")
	hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/MenuButton").emit_signal("pressed")
	hud.get_node("ResultPanel/SafeArea/Bounds/VBox/NextButton").emit_signal("pressed")
	assert_eq(counts["retry"], 1, "retry signal is unchanged")
	assert_eq(counts["menu"], 1, "menu signal is unchanged")
	assert_eq(counts["next"], 1, "next signal is unchanged")


func test_results_localize_in_english_and_turkish() -> void:
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var hud: HUD = await _hud()
		assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/RetryButton").text, tr("RESULT_RETRY"))
		assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/ButtonRow/MenuButton").text, tr("RESULT_MENU"))
		assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/NextButton").text, tr("RESULT_NEXT"))
		hud.show_endless_stage_reached(8)
		assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/StageReachedLabel").text,
			tr("RESULT_STAGE_REACHED") % 8, "stage label follows the active locale")


func test_endless_first_stage_loss_reports_stage_one() -> void:
	SeedManager.enter_level_endless()
	var game: Node = GAME_SCENE.instantiate()
	add_child_autofree(game)
	await get_tree().process_frame
	game.call("_show_endless_result_stage")
	var stage_label: Label = game.get_node("HUD/ResultPanel/SafeArea/Bounds/VBox/StageReachedLabel")
	assert_true(stage_label.visible)
	assert_eq(stage_label.text, tr("RESULT_STAGE_REACHED") % 1)
	SeedManager.enter_free()
	GameState.reset()


func test_endless_stage_transition_result_uses_stage_just_started() -> void:
	SeedManager.enter_level_endless()
	var game: Node = GAME_SCENE.instantiate()
	add_child_autofree(game)
	await get_tree().process_frame
	game.call("_show_endless_result_stage")
	var hud: HUD = game.get_node("HUD")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/StageReachedLabel").text, tr("RESULT_STAGE_REACHED") % 1,
		"before transition the current stage is reported")
	game.call("_advance_stage")
	hud.setup(3)
	game.call("_show_endless_result_stage")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/StageReachedLabel").text, tr("RESULT_STAGE_REACHED") % 2,
		"after transition the newly started stage is reported")
	game.call("_start_stage", 7)
	hud.setup(3)
	game.call("_show_endless_result_stage")
	assert_eq(hud.get_node("ResultPanel/SafeArea/Bounds/VBox/StageReachedLabel").text, tr("RESULT_STAGE_REACHED") % 8,
		"later stage uses one-based display numbering")
	SeedManager.enter_free()
	GameState.reset()


func test_non_endless_result_modes_hide_stage_reached_label() -> void:
	SeedManager.enter_free()
	var game: Node = GAME_SCENE.instantiate()
	add_child_autofree(game)
	await get_tree().process_frame
	var stage_label: Label = game.get_node("HUD/ResultPanel/SafeArea/Bounds/VBox/StageReachedLabel")
	for mode in [SeedManager.Mode.FREE, SeedManager.Mode.DAILY, SeedManager.Mode.CAMPAIGN]:
		game.set("_mode", mode)
		game.call("_show_endless_result_stage")
		assert_false(stage_label.visible, "non-Endless mode %d has no stage reached row" % mode)
	SeedManager.enter_free()
	GameState.reset()


func test_result_motif_clamps_real_progress_without_forcing_win_completion() -> void:
	var art: ResultTerritoryArt = RESULT_ART.new()
	add_child_autofree(art)
	art.size = Vector2(320.0, 64.0)
	art.set_result(-5.0, 120.0, false)
	assert_almost_eq(art.completion_percent, 0.0, 0.01, "negative actual clamps to zero")
	assert_almost_eq(art.target_percent, 100.0, 0.01, "target clamps to 100")
	assert_almost_eq((art.progress_geometry()["fill"] as Rect2).size.x, 0.0, 0.01)
	art.set_result(120.0, 50.0, true)
	assert_almost_eq(art.completion_percent, 100.0, 0.01, "actual clamps to 100")
	assert_almost_eq((art.progress_geometry()["fill"] as Rect2).size.x,
		(art.progress_geometry()["bar"] as Rect2).size.x, 0.01)
	art.set_result(63.0, 70.0, true)
	assert_almost_eq(art.completion_percent, 63.0, 0.01, "winning motif retains its real capture amount")


func test_result_motif_loss_geometry_places_actual_before_independent_target() -> void:
	var art: ResultTerritoryArt = RESULT_ART.new()
	add_child_autofree(art)
	art.size = Vector2(320.0, 64.0)
	art.set_result(32.0, 50.0, false)
	var geometry: Dictionary = art.progress_geometry()
	var bar: Rect2 = geometry["bar"]
	var fill: Rect2 = geometry["fill"]
	assert_almost_eq(fill.size.x / bar.size.x, 0.32, 0.0001)
	assert_almost_eq((float(geometry["target_x"]) - bar.position.x) / bar.size.x, 0.50, 0.0001)
	assert_almost_eq(((geometry["diamond"] as Vector2).x - bar.position.x) / bar.size.x, 0.32, 0.0001)
	assert_almost_eq(fill.position.y, bar.position.y, 0.0001, "rectangular fill starts at bar top")
	assert_almost_eq(fill.end.y, bar.end.y, 0.0001, "fill edge spans full bar height vertically")


func test_result_motif_win_geometry_crosses_target_without_faking_full_capture() -> void:
	var art: ResultTerritoryArt = RESULT_ART.new()
	add_child_autofree(art)
	art.size = Vector2(320.0, 64.0)
	art.set_result(74.0, 70.0, true)
	var geometry: Dictionary = art.progress_geometry()
	var bar: Rect2 = geometry["bar"]
	var fill: Rect2 = geometry["fill"]
	assert_almost_eq(fill.size.x / bar.size.x, 0.74, 0.0001)
	assert_almost_eq((float(geometry["target_x"]) - bar.position.x) / bar.size.x, 0.70, 0.0001)
	assert_almost_eq(((geometry["diamond"] as Vector2).x - bar.position.x) / bar.size.x, 0.74, 0.0001)
	assert_gt(fill.end.x, float(geometry["target_x"]), "actual fill visibly crosses target")
	assert_lt(fill.end.x, bar.end.x, "win retains remaining VOID")
	assert_almost_eq(fill.end.y, bar.end.y, 0.0001, "fill right edge remains vertical")
