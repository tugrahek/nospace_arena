extends GutTest

const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/PauseOverlay.tscn")
const Mission = preload("res://scripts/meta/mission.gd")
const MissionDef = preload("res://scripts/meta/mission_def.gd")


func _mission(progress: int, goal: int) -> Mission:
	var definition := MissionDef.new()
	definition.description_key = "MISSION_REACH_SCORE"
	definition.goal_amount = goal
	var mission := Mission.new(definition)
	mission.progress = progress
	return mission


func _overlaps(first: Control, second: Control) -> bool:
	return first.get_global_rect().intersects(second.get_global_rect())


func test_populated_top_hud_and_pause_button_fit_portrait_sizes() -> void:
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child_autofree(viewport)
		var hud: HUD = HUD_SCENE.instantiate()
		var pause: CanvasLayer = PAUSE_SCENE.instantiate()
		viewport.add_child(hud)
		viewport.add_child(pause)
		await get_tree().process_frame
		await get_tree().process_frame

		hud.setup(3)
		hud.set_target(75.0)
		hud.update_percent(62.0)
		hud.call("_on_life_lost", 2)
		hud.set_daily(true, 20261010)
		hud.set_best(987654)
		hud.show_missions([_mission(3, 5), _mission(10, 10)])
		hud.call("_on_score_changed", 123456, 3)
		await get_tree().process_frame

		var safe: SafeAreaMargin = hud.get_node("TopSafeArea")
		var info: Control = hud.get_node("TopSafeArea/InfoStack")
		var top_bar: Control = hud.get_node("TopSafeArea/InfoStack/TopBar")
		var hearts: HeartsHud = hud.get_node("TopSafeArea/InfoStack/TopBar/Hearts")
		var percent: Label = hud.get_node("TopSafeArea/InfoStack/TopBar/PercentLabel")
		var score: Label = hud.get_node("TopSafeArea/InfoStack/TopBar/ScoreLabel")
		var daily: Label = hud.get_node("TopSafeArea/InfoStack/MetaRow/DailyLabel")
		var best: Label = hud.get_node("TopSafeArea/InfoStack/MetaRow/BestLabel")
		var mission_status: Control = hud.get_node("TopSafeArea/InfoStack/ActivityRow/MissionStatus")
		var mission_count: Label = hud.get_node("TopSafeArea/InfoStack/ActivityRow/MissionStatus/Count")
		var combo: Label = hud.get_node("TopSafeArea/InfoStack/ActivityRow/ComboLabel")
		var pause_button: Button = pause.get_node("PauseSafeArea/Bounds/PauseButton")

		assert_eq(score.text, "Skor: 123456" if TranslationServer.get_locale() == "tr" else "Score: 123456")
		assert_eq(hearts.get("_current"), 2)
		assert_eq(percent.text, "62 / 75%")
		assert_true(daily.visible and best.visible)
		assert_true(mission_status.visible)
		assert_eq(mission_count.text, "1/2")
		assert_true(combo.visible)
		assert_eq(combo.text, tr("HUD_COMBO") + " x4")

		var safe_rect: Rect2 = safe.get_global_rect()
		var left: float = float(safe.get_theme_constant("margin_left"))
		var top: float = float(safe.get_theme_constant("margin_top"))
		var right: float = float(safe.get_theme_constant("margin_right"))
		var bottom: float = float(safe.get_theme_constant("margin_bottom"))
		var content_rect := Rect2(safe_rect.position + Vector2(left, top),
			safe_rect.size - Vector2(left + right, top + bottom))
		assert_true(content_rect.encloses(info.get_global_rect()), "HUD info respects safe-area content at %s" % dimensions)
		assert_true(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(pause_button.get_global_rect()),
			"Pause button stays accessible at %s" % dimensions)
		assert_false(_overlaps(info, pause_button), "Pause button stays clear of HUD info at %s" % dimensions)

		var visible_groups: Array[Control] = [hearts, percent, score, daily, best, mission_status, combo]
		for index in visible_groups.size():
			for other_index in range(index + 1, visible_groups.size()):
				var first: Control = visible_groups[index]
				var second: Control = visible_groups[other_index]
				if first.is_visible_in_tree() and second.is_visible_in_tree():
					assert_false(_overlaps(first, second),
						"visible HUD groups do not overlap at %s: %s / %s" % [dimensions, first.name, second.name])
