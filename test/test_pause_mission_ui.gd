extends GutTest

const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/PauseOverlay.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/main/Game.tscn")


func after_each() -> void:
	get_tree().paused = false
	GameState.reset()
	SeedManager.exit_daily()
	TranslationServer.set_locale("en")


func _mission(progress: int, goal: int, key: String = "MISSION_REACH_SCORE") -> Mission:
	var definition := MissionDef.new()
	definition.description_key = key
	definition.goal_amount = goal
	var mission := Mission.new(definition)
	mission.progress = progress
	return mission


func test_hud_status_uses_completed_over_real_total_and_hides_when_empty() -> void:
	var hud: HUD = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	var status: HBoxContainer = hud.get_node("TopSafeArea/InfoStack/ActivityRow/MissionStatus")
	var count: Label = hud.get_node("TopSafeArea/InfoStack/ActivityRow/MissionStatus/Count")
	var missions: Array = [_mission(0, 10), _mission(1, 10), _mission(5, 10)]
	hud.show_missions(missions)
	assert_true(status.visible)
	assert_eq(count.text, "0/3")
	missions[0].progress = 10
	hud.show_missions(missions)
	assert_eq(count.text, "1/3")
	missions[1].progress = 10
	missions[2].progress = 10
	hud.show_missions(missions)
	assert_eq(count.text, "3/3")
	hud.show_missions([])
	assert_false(status.visible)
	assert_eq(status.size.x <= 80.0, true)


func test_pause_binds_real_mission_and_collapses_empty_section() -> void:
	TranslationServer.set_locale("tr")
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	var section: VBoxContainer = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection")
	assert_false(section.visible)
	var missions: Array = [_mission(1, 2, "MISSION_WIN_RUNS"), _mission(80, 80, "MISSION_REACH_PERCENT")]
	pause.show_missions(missions)
	assert_true(section.visible)
	var rows: VBoxContainer = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection/MissionScroll/Rows")
	assert_eq(rows.get_child_count(), 2)
	assert_eq(rows.get_child(0).objective_text, "2 oyun kazan")
	assert_eq(rows.get_child(0).progress_text, "1 / 2")
	assert_false(rows.get_child(0).completed)
	assert_true(rows.get_child(0).get_child(1).visible)
	assert_true(rows.get_child(1).completed)
	assert_true(rows.get_child(1).get_child(1).visible)
	missions[0].progress = 2
	pause.show_missions(missions)
	assert_eq(rows.get_child_count(), 2)
	assert_true(rows.get_child(0).completed)
	pause.show_missions([])
	assert_false(section.visible)
	assert_eq(rows.get_child_count(), 2, "refresh reuses rows instead of freeing live nodes")
	assert_false(rows.get_child(0).visible)


func test_pause_settings_round_trip_and_actions_keep_existing_semantics() -> void:
	GameState.start_run(3)
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	for i in 3:
		pause.pause()
		assert_true(get_tree().paused)
		pause.resume()
		assert_false(get_tree().paused)
	pause.pause()
	for i in 3:
		pause.call("_on_settings")
		assert_true(get_tree().paused)
		var panel: Control = pause.get("_settings_panel")
		assert_not_null(panel)
		panel.call("close")
		await get_tree().process_frame
		assert_null(pause.get("_settings_panel"), "Settings closes cleanly on each return")
		assert_true(get_tree().paused, "Settings return keeps the run paused")
	var restart_count := [0]
	pause.restart_requested.connect(func() -> void: restart_count[0] += 1)
	pause.call("_on_restart")
	assert_false(get_tree().paused)
	assert_eq(restart_count[0], 1)
	pause.pause()
	var menu_count := [0]
	pause.menu_requested.connect(func() -> void: menu_count[0] += 1)
	pause.call("_on_menu")
	assert_false(get_tree().paused)
	assert_eq(menu_count[0], 1)


func test_pause_labels_follow_english_and_turkish_locale() -> void:
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	var title: Label = pause.get_node("Overlay/SafeArea/Bounds/Box/Title")
	assert_eq(title.text, "Paused")
	TranslationServer.set_locale("tr")
	pause.call("_apply_texts")
	assert_eq(title.text, "Duraklatıldı")
	assert_eq(pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection/Heading").text, "Görevler")


func test_game_scene_routes_hud_missions_to_pause_without_core_changes() -> void:
	SeedManager.enter_free()
	var game: Node = GAME_SCENE.instantiate()
	add_child_autofree(game)
	var hud: HUD = game.get_node("HUD")
	var pause: CanvasLayer = game.get_node("PauseOverlay")
	var section: VBoxContainer = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection")
	assert_true(section.visible, "real run missions reach pause via scene signal")
	var missions: Array = [_mission(0, 3), _mission(3, 3)]
	hud.show_missions(missions)
	var rows: VBoxContainer = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection/MissionScroll/Rows")
	assert_eq(rows.get_child_count(), 3, "existing rows remain reusable")
	assert_true(rows.get_child(0).visible)
	assert_true(rows.get_child(1).visible)
	assert_false(rows.get_child(2).visible)
	assert_eq(pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection/MissionScroll/Rows").get_child(1).progress_text, "3 / 3")


func test_pause_content_stays_ordered_and_inside_720_by_1280_view() -> void:
	TranslationServer.set_locale("tr")
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	pause.show_missions([
		_mission(200, 800, "MISSION_REACH_SCORE"),
		_mission(1, 2, "MISSION_WIN_RUNS"),
		_mission(80, 80, "MISSION_REACH_PERCENT"),
	])
	pause.get_node("Overlay").visible = true
	await get_tree().process_frame
	var title: Control = pause.get_node("Overlay/SafeArea/Bounds/Box/Title")
	var resume: Control = pause.get_node("Overlay/SafeArea/Bounds/Box/ResumeButton")
	var missions: Control = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection")
	var actions: Control = pause.get_node("Overlay/SafeArea/Bounds/Box/SecondaryActions")
	var menu: Control = pause.get_node("Overlay/SafeArea/Bounds/Box/MenuButton")
	assert_lte(title.get_global_rect().end.y, resume.get_global_rect().position.y)
	assert_lte(resume.get_global_rect().end.y, missions.get_global_rect().position.y)
	assert_lte(missions.get_global_rect().end.y, actions.get_global_rect().position.y)
	assert_lte(actions.get_global_rect().end.y, menu.get_global_rect().position.y)
	assert_lte(menu.get_global_rect().end.y, 1280.0)
	assert_gte(title.get_global_rect().position.y, 0.0)
	var box: Control = pause.get_node("Overlay/SafeArea/Bounds/Box")
	var settings: Control = pause.get_node("Overlay/SafeArea/Bounds/Box/SecondaryActions/SettingsButton")
	assert_lte(resume.size.x, box.size.x * 0.85, "Continue is primary without spanning the mission width")
	assert_lt(menu.size.x, settings.size.x, "Menu is quieter than secondary actions")
	assert_gte(menu.size.y, 48.0, "Menu retains a mobile tap target")


func test_all_complete_pause_rows_keep_numeric_truth_without_active_frontiers() -> void:
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	pause.show_missions([
		_mission(800, 800),
		_mission(2, 2, "MISSION_WIN_RUNS"),
		_mission(80, 80, "MISSION_REACH_PERCENT"),
	])
	var rows: VBoxContainer = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection/MissionScroll/Rows")
	assert_eq(rows.get_child_count(), 3)
	for row in rows.get_children():
		assert_true(row.completed)
		assert_true(row.progress_text.contains(" / "))
		var track: Control = row.get_child(1)
		assert_true(track.is_complete)
		assert_true(track.visible, "complete missions retain the captured line")
		assert_eq(track.ratio, 1.0)


func test_zero_progress_pause_row_shows_only_muted_track() -> void:
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	pause.show_missions([_mission(0, 10)])
	var rows: VBoxContainer = pause.get_node("Overlay/SafeArea/Bounds/Box/MissionSection/MissionScroll/Rows")
	var track: Control = rows.get_child(0).get_child(1)
	assert_true(track.visible)
	assert_false(track.is_complete)
	assert_eq(track.ratio, 0.0)
