extends GutTest

## Pure stage-progression logic. Determinism is critical (daily fairness); the feel/balance
## of the ramp is tuned by Tuğra via config/progression.tres.

const StagePlan = preload("res://scripts/meta/stage_plan.gd")

# Mirrors config/progression.tres defaults used across cases.
const SR := 0.12   # speed_ramp
const SC := 2.5    # speed_cap
const EAE := 2     # enemy_add_every
const ECB := 4     # enemy_cap_bonus
const TR := 2.0    # target_ramp


func _daily(stage: int, count: int = 3) -> Dictionary:
	return StagePlan.compute(true, 20260619, 0, stage, count, SR, SC, EAE, ECB, TR)


func test_deterministic_same_seed_stage() -> void:
	assert_eq(_daily(3), _daily(3), "same seed+stage -> identical spec")


func test_stage0_matches_existing_daily_arena_draw() -> void:
	# Stage 0 must equal the legacy draw to_index(seed, ARENA_SALT, count) so today's arena
	# is unchanged by the progression refactor.
	var expected: int = DailySeed.to_index(20260619, StagePlan.ARENA_SALT, 3)
	assert_eq(int(_daily(0)["arena_index"]), expected)


func test_stage0_seed_is_raw_seed() -> void:
	assert_eq(int(_daily(0)["stage_seed"]), 20260619)


func test_speed_ramps_then_caps() -> void:
	assert_almost_eq(float(_daily(0)["speed_scale"]), 1.0, 0.0001)
	assert_almost_eq(float(_daily(2)["speed_scale"]), 1.24, 0.0001)
	# Far stage saturates at the cap.
	assert_almost_eq(float(_daily(99)["speed_scale"]), SC, 0.0001)


func test_target_bonus_increases_linearly() -> void:
	assert_almost_eq(float(_daily(0)["target_bonus"]), 0.0, 0.0001)
	assert_almost_eq(float(_daily(3)["target_bonus"]), 6.0, 0.0001)


func test_enemy_bonus_steps_and_caps() -> void:
	assert_eq(int(_daily(1)["enemy_bonus"]), 0)   # 1/2 = 0
	assert_eq(int(_daily(2)["enemy_bonus"]), 1)   # 2/2 = 1
	assert_eq(int(_daily(8)["enemy_bonus"]), 4)   # 8/2 = 4 = cap
	assert_eq(int(_daily(99)["enemy_bonus"]), ECB, "capped")


func test_stages_differ() -> void:
	# Across a few stages, at least arena or speed should vary (escalation is real).
	var s0 := _daily(0)
	var s1 := _daily(1)
	var changed: bool = s0["arena_index"] != s1["arena_index"] or s0["speed_scale"] != s1["speed_scale"]
	assert_true(changed)


func test_freeplay_cycles_arenas() -> void:
	var count := 3
	assert_eq(int(StagePlan.compute(false, 0, 1, 0, count, SR, SC, EAE, ECB, TR)["arena_index"]), 1)
	assert_eq(int(StagePlan.compute(false, 0, 1, 1, count, SR, SC, EAE, ECB, TR)["arena_index"]), 2)
	assert_eq(int(StagePlan.compute(false, 0, 1, 2, count, SR, SC, EAE, ECB, TR)["arena_index"]), 0)  # wrap


func test_freeplay_stage_seed_zero() -> void:
	assert_eq(int(StagePlan.compute(false, 0, 0, 3, 3, SR, SC, EAE, ECB, TR)["stage_seed"]), 0)
