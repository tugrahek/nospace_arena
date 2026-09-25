extends GutTest

## Pure stage-progression logic (Level-Endless spine; Daily is single-arena, stage 0 only).
## Determinism is critical (daily fairness); ramp feel is tuned via config/progression.tres.

const StagePlan = preload("res://scripts/meta/stage_plan.gd")
const PROGRESSION: ProgressionConfig = preload("res://config/progression.tres")

# Mirrors config/progression.tres defaults used across cases.
const SR := 0.12   # speed_ramp
const SC := 2.5    # speed_cap
const EAE := 2     # enemy_add_every
const ECB := 4     # enemy_cap_bonus
const TR := 2.0    # target_ramp


# The ramp lives in Level-Endless (free-play compute path).
func _endless(stage: int, count: int = 3) -> Dictionary:
	return StagePlan.compute(false, 0, 0, stage, count, SR, SC, EAE, ECB, TR)


func _daily(stage: int, count: int = 3) -> Dictionary:
	return StagePlan.compute(true, 20260619, 0, stage, count, SR, SC, EAE, ECB, TR)


func _authored(stage: int, base_arena: int = 0, count: int = 3) -> Dictionary:
	return StagePlan.compute_endless(base_arena, stage, count, PROGRESSION)


func _enemy_ids(spec: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for enemy: EnemyType in spec["enemies"]:
		ids.append(enemy.id)
	return ids


func test_deterministic_same_seed_stage() -> void:
	assert_eq(_endless(3), _endless(3), "same inputs -> identical spec")
	assert_eq(_daily(0), _daily(0), "daily stage-0 spec is deterministic")


func test_stage0_matches_existing_daily_arena_draw() -> void:
	# Daily stage 0 must equal the legacy draw to_index(seed, ARENA_SALT, count) so today's
	# arena is unchanged (daily is single-arena; stage 0 is the only daily request).
	var expected: int = DailySeed.to_index(20260619, StagePlan.ARENA_SALT, 3)
	assert_eq(int(_daily(0)["arena_index"]), expected)


func test_stage0_seed_is_raw_seed() -> void:
	assert_eq(int(_daily(0)["stage_seed"]), 20260619)


func test_speed_ramps_then_caps() -> void:
	assert_almost_eq(float(_endless(0)["speed_scale"]), 1.0, 0.0001)
	assert_almost_eq(float(_endless(2)["speed_scale"]), 1.24, 0.0001)
	# Far stage saturates at the cap.
	assert_almost_eq(float(_endless(99)["speed_scale"]), SC, 0.0001)


func test_target_bonus_increases_linearly() -> void:
	assert_almost_eq(float(_endless(0)["target_bonus"]), 0.0, 0.0001)
	assert_almost_eq(float(_endless(3)["target_bonus"]), 6.0, 0.0001)


func test_enemy_bonus_steps_and_caps() -> void:
	assert_eq(int(_endless(1)["enemy_bonus"]), 0)   # 1/2 = 0
	assert_eq(int(_endless(2)["enemy_bonus"]), 1)   # 2/2 = 1
	assert_eq(int(_endless(8)["enemy_bonus"]), 4)   # 8/2 = 4 = cap
	assert_eq(int(_endless(99)["enemy_bonus"]), ECB, "capped")


func test_stages_differ() -> void:
	# Across endless stages, arena and/or speed vary (escalation is real).
	var s0 := _endless(0)
	var s1 := _endless(1)
	var changed: bool = s0["arena_index"] != s1["arena_index"] or s0["speed_scale"] != s1["speed_scale"]
	assert_true(changed)


func test_freeplay_cycles_arenas() -> void:
	var count := 3
	assert_eq(int(StagePlan.compute(false, 0, 1, 0, count, SR, SC, EAE, ECB, TR)["arena_index"]), 1)
	assert_eq(int(StagePlan.compute(false, 0, 1, 1, count, SR, SC, EAE, ECB, TR)["arena_index"]), 2)
	assert_eq(int(StagePlan.compute(false, 0, 1, 2, count, SR, SC, EAE, ECB, TR)["arena_index"]), 0)  # wrap


func test_freeplay_stage_seed_zero() -> void:
	assert_eq(int(StagePlan.compute(false, 0, 0, 3, 3, SR, SC, EAE, ECB, TR)["stage_seed"]), 0)


# --- Fix-pass #22: authored Endless onboarding + anchored late ramp ---

func test_endless_authored_stages_match_b1_r_golden() -> void:
	var expected: Array[Dictionary] = [
		{"arena": 0, "roster": [&"bouncer"], "pace": 1.0, "target": 75.0, "adaptive": false},
		{"arena": 1, "roster": [&"bouncer", &"bouncer"], "pace": 1.0, "target": 75.0, "adaptive": false},
		{"arena": 2, "roster": [&"bouncer", &"chaser"], "pace": 1.0, "target": 76.0, "adaptive": false},
		{"arena": 2, "roster": [&"bouncer", &"chaser", &"sparx"], "pace": 1.0, "target": 76.0, "adaptive": false},
		{"arena": 2, "roster": [&"bouncer", &"bouncer", &"chaser", &"sparx"], "pace": 1.0, "target": 76.0, "adaptive": false},
		{"arena": 2, "roster": [&"bouncer", &"bouncer", &"chaser", &"sparx"], "pace": 1.0, "target": 76.0, "adaptive": true},
		{"arena": 0, "roster": [&"bouncer", &"bouncer", &"chaser", &"chaser", &"sparx"], "pace": 1.0, "target": 76.0, "adaptive": true},
		{"arena": 1, "roster": [&"bouncer", &"bouncer", &"chaser", &"chaser", &"sparx"], "pace": 1.0, "target": 77.0, "adaptive": true},
	]
	for stage in expected.size():
		var spec := _authored(stage)
		var want: Dictionary = expected[stage]
		assert_eq(int(spec["arena_index"]), int(want["arena"]), "stage %d arena" % (stage + 1))
		assert_eq(_enemy_ids(spec), want["roster"], "stage %d roster" % (stage + 1))
		assert_eq((spec["enemies"] as Array).size(), (want["roster"] as Array).size(), "stage %d count" % (stage + 1))
		assert_almost_eq(float(spec["pace_scale"]), float(want["pace"]), 0.0001, "stage %d pace" % (stage + 1))
		assert_almost_eq(float(spec["target_percent"]), float(want["target"]), 0.0001, "stage %d target" % (stage + 1))
		assert_eq(bool(spec["adaptive_chaser"]), bool(want["adaptive"]), "stage %d adaptive" % (stage + 1))


func test_endless_handoff_is_anchored_to_stage_eight() -> void:
	var stage8 := _authored(7)
	var stage9 := _authored(8)
	assert_eq(_enemy_ids(stage9), _enemy_ids(stage8), "stage 9 keeps the authored baseline roster")
	assert_almost_eq(float(stage9["pace_scale"]), 1.03, 0.0001, "stage 9 starts a relative pace ramp")
	assert_almost_eq(float(stage9["target_percent"]), 78.0, 0.0001, "stage 9 starts a relative target ramp")
	assert_true(bool(stage9["adaptive_chaser"]), "adaptive remains enabled after handoff")


func test_endless_late_count_growth_holds_other_pressure_axes() -> void:
	var stage10 := _authored(9)
	var stage11 := _authored(10)
	var stage13 := _authored(12)
	var stage14 := _authored(13)
	assert_eq((stage11["enemies"] as Array).size(), 6, "stage 11 adds one Bouncer")
	assert_eq(_enemy_ids(stage11).back(), &"bouncer", "first late addition is Bouncer")
	assert_eq(int(stage11["arena_index"]), int(stage10["arena_index"]), "stage 11 holds arena")
	assert_almost_eq(float(stage11["pace_scale"]), float(stage10["pace_scale"]), 0.0001, "stage 11 holds pace")
	assert_almost_eq(float(stage11["target_percent"]), float(stage10["target_percent"]), 0.0001, "stage 11 holds target")
	assert_eq((stage14["enemies"] as Array).size(), 7, "stage 14 adds one Sparx")
	assert_eq(_enemy_ids(stage14).back(), &"sparx", "second late addition is Sparx")
	assert_eq(int(stage14["arena_index"]), int(stage13["arena_index"]), "stage 14 holds arena")
	assert_almost_eq(float(stage14["pace_scale"]), float(stage13["pace_scale"]), 0.0001, "stage 14 holds pace")
	assert_almost_eq(float(stage14["target_percent"]), float(stage13["target_percent"]), 0.0001, "stage 14 holds target")


func test_endless_late_curve_is_bounded_and_monotonic() -> void:
	var previous_count: int = 0
	var previous_pace: float = 0.0
	var previous_target: float = 0.0
	for stage in range(8, 18):
		var spec := _authored(stage)
		var count: int = (spec["enemies"] as Array).size()
		assert_lte(count - previous_count, 1, "stage %d count grows by at most one" % (stage + 1))
		assert_lte(count, 7, "stage %d count never exceeds cap" % (stage + 1))
		assert_gte(float(spec["pace_scale"]), previous_pace, "stage %d pace is monotonic" % (stage + 1))
		assert_lte(float(spec["pace_scale"]), PROGRESSION.late_speed_cap, "stage %d pace is capped" % (stage + 1))
		assert_gte(float(spec["target_percent"]), previous_target, "stage %d target is monotonic" % (stage + 1))
		assert_lte(float(spec["target_percent"]), PROGRESSION.late_target_cap, "stage %d target is capped" % (stage + 1))
		previous_count = count
		previous_pace = float(spec["pace_scale"])
		previous_target = float(spec["target_percent"])


func test_endless_base_arena_offsets_keep_pressure_identical() -> void:
	var expected: Array[Array] = [
		[0, 1, 2, 2, 2, 2, 0, 1],
		[1, 2, 0, 0, 0, 0, 1, 2],
		[2, 0, 1, 1, 1, 1, 2, 0],
	]
	for base in 3:
		for stage in 8:
			var spec := _authored(stage, base)
			var void_spec := _authored(stage, 0)
			assert_eq(int(spec["arena_index"]), expected[base][stage], "base %d stage %d arena" % [base, stage + 1])
			assert_eq(_enemy_ids(spec), _enemy_ids(void_spec), "base %d stage %d roster" % [base, stage + 1])
			assert_almost_eq(float(spec["pace_scale"]), float(void_spec["pace_scale"]), 0.0001, "base %d stage %d pace" % [base, stage + 1])
			assert_almost_eq(float(spec["target_percent"]), float(void_spec["target_percent"]), 0.0001, "base %d stage %d target" % [base, stage + 1])


func test_endless_plan_is_deterministic() -> void:
	assert_eq(_authored(13, 2), _authored(13, 2), "same explicit Endless input -> identical plan")
