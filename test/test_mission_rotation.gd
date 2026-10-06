extends GutTest

const Catalog = preload("res://scripts/meta/mission_catalog.gd")
const Service = preload("res://scripts/meta/mission_service.gd")
const Content = preload("res://scripts/meta/content_catalog.gd")
const Definition = preload("res://scripts/meta/mission_def.gd")
const MissionModel = preload("res://scripts/meta/mission.gd")
const Seed = preload("res://scripts/meta/daily_seed.gd")


func _date(offset: int) -> int:
	var day: Dictionary = Time.get_datetime_dict_from_unix_time(1767225600 + offset * 86400)
	return Seed.seed_for_date(day.year, day.month, day.day)


func _families(indices: Array) -> Dictionary:
	var result: Dictionary = {}
	for index in indices:
		var family: int = Content.MISSIONS[index].goal_type
		result[family] = int(result.get(family, 0)) + 1
	return result


func test_year_rotation_is_deterministic_without_adjacent_set_slot_or_family_repeats() -> void:
	var previous: Array[int] = []
	var similar_within_day: bool = false
	var areas_and_percent: bool = false
	var reached_families: Dictionary = {}
	for day in 370:
		var seed: int = _date(day)
		var current: Array[int] = Catalog.pick_for_date(Content.MISSIONS, seed, 3)
		assert_eq(current, Catalog.pick_for_date(Content.MISSIONS, seed, 3))
		assert_eq(current.size(), 3)
		var sorted: Array[int] = current.duplicate()
		sorted.sort()
		assert_eq(sorted.size(), 3)
		var families: Dictionary = _families(current)
		similar_within_day = similar_within_day or families.size() < 3
		areas_and_percent = areas_and_percent or (families.has(1) and families.has(2))
		for family in families:
			reached_families[family] = true
		if not previous.is_empty():
			var old_sorted: Array[int] = previous.duplicate()
			old_sorted.sort()
			assert_ne(sorted, old_sorted, "adjacent full sets differ across calendar boundaries")
			assert_ne(families, _families(previous), "different objective families, not just thresholds")
			for slot in 3:
				assert_ne(current[slot], previous[slot], "same definition does not stay in the same slot")
		previous = current
	assert_true(similar_within_day, "similar families are allowed within one day")
	assert_true(areas_and_percent, "area count and area percent may appear together")
	assert_eq(reached_families.size(), 7)


func test_small_and_single_family_pools_remain_supported_without_category_quotas() -> void:
	var single: Array = [Content.MISSIONS[0], Content.MISSIONS[1], Content.MISSIONS[2], Content.MISSIONS[3]]
	for day in 12:
		assert_eq(Catalog.pick_for_date(single, _date(day), 3).size(), 3)
	assert_eq(Catalog.pick_for_date([], _date(0), 3), [])
	assert_eq(Catalog.pick_for_date(single, _date(0), 0), [])
	assert_eq(Catalog.pick_for_date(single, _date(0), 99).size(), 4)


func test_new_pool_uses_only_existing_rewards_and_reachable_localized_families() -> void:
	var rewards: Array[int] = []
	for index in 14:
		if not rewards.has(Content.MISSIONS[index].reward):
			rewards.append(Content.MISSIONS[index].reward)
	assert_eq(Content.MISSIONS.size(), 21)
	for index in range(14, 21):
		var definition: MissionDef = Content.MISSIONS[index]
		assert_true(rewards.has(definition.reward), "no new coin tier")
		assert_gt(definition.goal_amount, 0)
		assert_true(definition.goal_type in [4, 5, 6])
		for locale in ["en", "tr"]:
			TranslationServer.set_locale(locale)
			assert_ne(tr(definition.description_key), definition.description_key)
	TranslationServer.set_locale("en")


func test_snapshot_and_progress_distinguish_completed_loss_from_win() -> void:
	var completed := MissionModel.new(load("res://resources/missions/m_runs_2.tres"))
	var win := MissionModel.new(load("res://resources/missions/m_win_2.tres"))
	var stage := MissionModel.new(load("res://resources/missions/m_stage_4.tres"))
	var survival := MissionModel.new(load("res://resources/missions/m_time_30.tres"))
	var stats: Dictionary = Service.completed_run_stats(1300, 54.2, 5, false, 3, 29.99)
	assert_eq(stats.run_seconds, 29, "fractional seconds cannot prematurely complete a mission")
	for mission in [completed, win, stage, survival]:
		mission.advance(stats)
	assert_eq(completed.progress, 1)
	assert_eq(win.progress, 0)
	assert_eq(stage.progress, 3)
	assert_eq(survival.progress, 29)
	assert_false(survival.is_complete())
	stats = Service.completed_run_stats(1500, 80.0, 6, true, 4, 30.01)
	for mission in [completed, win, stage, survival]:
		mission.advance(stats)
	assert_true(completed.is_complete())
	assert_eq(win.progress, 1)
	assert_true(stage.is_complete())
	assert_true(survival.is_complete())
	assert_eq(stage.claim(), 140)
	assert_eq(stage.claim(), 0)
	stage.advance(Service.completed_run_stats(0, 0.0, 0, false, 0, 5.0))
	survival.advance(Service.completed_run_stats(0, 0.0, 0, false, 0, 5.0))
	assert_eq(stage.progress, 4, "best stage, no accumulation or outside-Endless progress")
	assert_eq(survival.progress, 30, "best single-run survival, no accumulation")


func test_build_preserves_selected_id_progress_and_claim_state() -> void:
	var first: Array[Mission] = Service.build(Content.MISSIONS, _date(0), 3, {})
	var saved: Dictionary = {String(first[0].def.id): {"progress": 1, "claimed": true}}
	var second: Array[Mission] = Service.build(Content.MISSIONS, _date(0), 3, saved)
	assert_eq(second[0].def.id, first[0].def.id)
	assert_eq(second[0].progress, 1)
	assert_true(second[0].claimed)