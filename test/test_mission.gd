extends GutTest

const Mission = preload("res://scripts/meta/mission.gd")
const MissionDef = preload("res://scripts/meta/mission_def.gd")


func _def(goal_type: int, amount: int, reward: int = 10) -> MissionDef:
	var d := MissionDef.new()
	d.id = &"m"
	d.goal_type = goal_type
	d.goal_amount = amount
	d.reward = reward
	return d


func test_reach_score_takes_max() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.REACH_SCORE, 1000))
	m.advance({"score": 500})
	m.advance({"score": 300})
	assert_eq(m.progress, 500, "max, kümülatif değil")
	assert_false(m.is_complete())
	m.advance({"score": 1200})
	assert_true(m.is_complete())


func test_total_areas_accumulates() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.TOTAL_AREAS, 10))
	m.advance({"areas": 3})
	m.advance({"areas": 4})
	assert_eq(m.progress, 7)
	m.advance({"areas": 5})
	assert_true(m.is_complete())


func test_win_runs_counts_wins_only() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.WIN_RUNS, 2))
	m.advance({"won": true})
	m.advance({"won": false})
	assert_eq(m.progress, 1)
	m.advance({"won": true})
	assert_true(m.is_complete())


func test_reach_percent_takes_max() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.REACH_PERCENT, 80))
	m.advance({"percent": 60})
	assert_eq(m.progress, 60)
	m.advance({"percent": 85})  # max 85, capped at goal 80
	assert_eq(m.progress, 80, "tavanda durur")
	assert_true(m.is_complete())


func test_claim_pays_once() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.REACH_SCORE, 100, 50))
	m.advance({"score": 150})
	assert_eq(m.claim(), 50, "tamamlanınca ödül")
	assert_eq(m.claim(), 0, "ikinci claim 0 — çift ödül yok")


func test_claim_zero_when_incomplete() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.REACH_SCORE, 100, 50))
	m.advance({"score": 40})
	assert_eq(m.claim(), 0)


func test_progress_clamped_to_goal() -> void:
	# Cumulative overshoot is capped at the goal (display 3/3, not 5/3).
	var w := Mission.new(_def(MissionDef.GoalType.WIN_RUNS, 1))
	w.advance({"won": true})
	w.advance({"won": true})
	assert_eq(w.progress, 1, "WIN tavanda durur")
	var a := Mission.new(_def(MissionDef.GoalType.TOTAL_AREAS, 10))
	a.advance({"areas": 50})
	assert_eq(a.progress, 10, "AREAS tavanda durur")


func test_dict_round_trip() -> void:
	var m := Mission.new(_def(MissionDef.GoalType.TOTAL_AREAS, 10, 30))
	m.advance({"areas": 12})  # clamped to 10
	m.claim()
	var restored := Mission.new(_def(MissionDef.GoalType.TOTAL_AREAS, 10, 30))
	restored.apply_dict(m.to_dict())
	assert_eq(restored.progress, 10)
	assert_true(restored.claimed)
	assert_eq(restored.claim(), 0, "yüklenen claimed tekrar ödemez")
