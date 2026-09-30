extends GutTest

const MissionProgressStrip = preload("res://scripts/ui/mission_progress_strip.gd")
const Mission = preload("res://scripts/meta/mission.gd")
const MissionDef = preload("res://scripts/meta/mission_def.gd")
const MISSIONS_SCENE: PackedScene = preload("res://scenes/ui/Missions.tscn")


func after_each() -> void:
	TranslationServer.set_locale("en")


func _mission(progress: int, goal: int, reward: int = 35) -> Mission:
	var definition := MissionDef.new()
	definition.id = &"progress_strip"
	definition.description_key = "MISSION_REACH_PERCENT"
	definition.goal_type = MissionDef.GoalType.REACH_PERCENT
	definition.goal_amount = goal
	definition.reward = reward
	var mission := Mission.new(definition)
	mission.progress = progress
	return mission


func _contained(child: Control, parent: Control) -> bool:
	var child_rect: Rect2 = child.get_global_rect()
	var parent_rect: Rect2 = parent.get_global_rect()
	return parent_rect.encloses(child_rect)


func test_zero_progress_keeps_void_without_active_frontier() -> void:
	var strip := MissionProgressStrip.new()
	strip.configure(_mission(0, 80))
	assert_eq(strip.progress_ratio, 0.0)
	assert_false(strip.has_active_frontier)
	assert_false(strip.shows_diamond)
	assert_false(strip.is_completed)
	strip.free()


func test_partial_progress_uses_real_ratio_and_frontier() -> void:
	var strip := MissionProgressStrip.new()
	strip.configure(_mission(20, 80, 55))
	assert_almost_eq(strip.progress_ratio, 0.25, 0.001)
	assert_true(strip.has_active_frontier)
	assert_true(strip.shows_diamond)
	assert_eq(strip.current_value, 20)
	assert_eq(strip.goal_value, 80)
	assert_eq(strip.reward_value, 55)
	strip.free()


func test_fractional_large_goal_ratio_stays_precise() -> void:
	var strip := MissionProgressStrip.new()
	strip.configure(_mission(1, 10000))
	assert_almost_eq(strip.progress_ratio, 0.0001, 0.000001)
	assert_true(strip.has_active_frontier)
	strip.free()


func test_complete_progress_removes_active_frontier_marker() -> void:
	var strip := MissionProgressStrip.new()
	strip.configure(_mission(120, 80))
	assert_eq(strip.progress_ratio, 1.0)
	assert_true(strip.is_completed)
	assert_false(strip.has_active_frontier)
	assert_false(strip.shows_diamond)
	strip.free()


func test_territory_area_coverage_is_monotonic_with_progress() -> void:
	var ratios: Array[float] = []
	var host := VBoxContainer.new()
	host.size = Vector2(540.0, 1400.0)
	add_child_autofree(host)
	for progress in [0, 20, 40, 60, 80]:
		var strip := MissionProgressStrip.new()
		strip.configure(_mission(progress, 80))
		host.add_child(strip)
		await get_tree().process_frame
		ratios.append(strip.rendered_captured_area_ratio())
	for index in ratios.size() - 1:
		assert_lte(ratios[index], ratios[index + 1], "territory coverage never recedes")
	assert_almost_eq(ratios[0], 0.0, 0.001)
	assert_almost_eq(ratios[ratios.size() - 1], 1.0, 0.001)


func test_objective_uses_existing_locale_template() -> void:
	var strip := MissionProgressStrip.new()
	TranslationServer.set_locale("tr")
	strip.configure(_mission(12, 80))
	assert_eq(strip.objective_text, "80% alan ele geçir")
	TranslationServer.set_locale("en")
	strip.configure(_mission(12, 80))
	assert_eq(strip.objective_text, "Capture 80%")
	strip.free()


func test_missions_scene_builds_three_runtime_strips() -> void:
	var screen: Control = MISSIONS_SCENE.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame
	var list: VBoxContainer = screen.get_node("List")
	assert_eq(list.get_child_count(), 3)
	for child in list.get_children():
		assert_true(child is MissionProgressStrip)


func test_runtime_strip_geometry_does_not_cross_into_siblings() -> void:
	var screen: Control = MISSIONS_SCENE.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame
	var list: VBoxContainer = screen.get_node("List")
	for index in list.get_child_count():
		var strip: MissionProgressStrip = list.get_child(index)
		assert_true(_contained(strip.objective_label(), strip), "objective stays in strip %d" % index)
		assert_true(_contained(strip.reward_cluster(), strip), "reward stays in strip %d" % index)
		assert_true(_contained(strip.territory_patch(), strip), "patch stays in strip %d" % index)
		if index + 1 < list.get_child_count():
			var next_strip: Control = list.get_child(index + 1)
			assert_lte(strip.get_global_rect().end.y, next_strip.get_global_rect().position.y,
				"strip %d does not overlap its next sibling" % index)


func test_long_turkish_objective_stays_in_its_header() -> void:
	TranslationServer.set_locale("tr")
	var host := VBoxContainer.new()
	host.size = Vector2(600.0, 300.0)
	add_child_autofree(host)
	var definition := MissionDef.new()
	definition.id = &"turkish_areas"
	definition.description_key = "MISSION_TOTAL_AREAS"
	definition.goal_type = MissionDef.GoalType.TOTAL_AREAS
	definition.goal_amount = 50
	definition.reward = 180
	var mission := Mission.new(definition)
	var strip := MissionProgressStrip.new()
	strip.configure(mission)
	host.add_child(strip)
	await get_tree().process_frame
	assert_eq(strip.objective_text, "50 bölge ele geçir")
	assert_true(_contained(strip.objective_label(), strip))
	assert_true(_contained(strip.reward_cluster(), strip))
