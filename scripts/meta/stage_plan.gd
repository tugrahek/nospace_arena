class_name StagePlan
extends RefCounted

## Pure, deterministic per-stage spec for the Level-Endless progression spine (D1=A). No
## nodes, no RNG. Free-play/endless cycles arenas + ramps difficulty. Daily is SINGLE-ARENA
## (18a redirect): only stage 0 is ever requested — its arena/seed equal the daily draw, so
## today's challenge is unchanged. (The multi-stage daily salt-shift path was rolled back.)
##
## ARENA_SALT mirrors game.gd's ARENA_SALT (same daily arena draw).

const ARENA_SALT: int = 1


## Returns a stage spec dict: arena_index, speed_scale (>=1, capped), enemy_bonus (extra
## enemies over the arena's base composition, capped), target_bonus (% added; caller clamps
## with the arena base + target_cap), stage_seed (for deterministic enemy dirs; 0 free-play).
static func compute(
	daily: bool, seed: int, base_arena_index: int, stage_index: int, arena_count: int,
	speed_ramp: float, speed_cap: float, enemy_add_every: int, enemy_cap_bonus: int,
	target_ramp: float
) -> Dictionary:
	var speed_scale: float = minf(1.0 + speed_ramp * float(stage_index), speed_cap)
	var enemy_bonus: int = 0
	if enemy_add_every > 0:
		enemy_bonus = mini(stage_index / enemy_add_every, enemy_cap_bonus)
	return {
		"arena_index": _arena_for(daily, seed, base_arena_index, stage_index, arena_count),
		"speed_scale": speed_scale,
		"enemy_bonus": enemy_bonus,
		"target_bonus": target_ramp * float(stage_index),
		"stage_seed": seed if daily else 0,
	}


## Pure Level-Endless plan: eight authored onboarding stages, then a relative ramp anchored
## to the final authored stage. The returned roster is final, so callers must not add bonuses.
static func compute_endless(
	base_arena_index: int, stage_index: int, arena_count: int, config: ProgressionConfig
) -> Dictionary:
	assert(not config.early_stages.is_empty(), "Endless progression needs authored early stages")
	var early_count: int = config.early_stages.size()
	if stage_index < early_count:
		return _from_authored(config.early_stages[maxi(stage_index, 0)], base_arena_index, arena_count,
			stage_index, config.chaser_hunts_nearest_stage)
	var baseline: EndlessStageSpec = config.early_stages[early_count - 1]
	var relative_stage: int = stage_index - early_count
	var add_cap: int = mini(config.late_enemy_cap, config.late_add_order.size())
	var additions: int = 0
	if config.late_enemy_add_every > 0:
		additions = mini((relative_stage + 1) / config.late_enemy_add_every, add_cap)
	var pressure_steps: int = relative_stage + 1 - additions
	var enemies: Array[EnemyType] = []
	for enemy in baseline.enemies:
		enemies.append(enemy)
	for i in additions:
		enemies.append(config.late_add_order[i])
	return {
		"arena_index": _offset_arena(base_arena_index, baseline.arena_offset + pressure_steps, arena_count),
		"enemies": enemies,
		"pace_scale": minf(baseline.pace_scale + float(pressure_steps) * config.late_speed_ramp,
			config.late_speed_cap),
		"target_percent": minf(baseline.target_percent + float(pressure_steps) * config.late_target_ramp,
			config.late_target_cap),
		"adaptive_chaser": _adaptive(stage_index, config.chaser_hunts_nearest_stage),
	}


static func _from_authored(
	spec: EndlessStageSpec, base_arena_index: int, arena_count: int, stage_index: int, adaptive_stage: int
) -> Dictionary:
	return {
		"arena_index": _offset_arena(base_arena_index, spec.arena_offset, arena_count),
		"enemies": spec.enemies.duplicate(),
		"pace_scale": spec.pace_scale,
		"target_percent": spec.target_percent,
		"adaptive_chaser": _adaptive(stage_index, adaptive_stage),
	}


static func _offset_arena(base: int, offset: int, count: int) -> int:
	if count <= 0:
		return 0
	return posmod(base + offset, count)


static func _adaptive(stage_index: int, threshold: int) -> bool:
	return threshold >= 0 and stage_index >= threshold


static func _arena_for(daily: bool, seed: int, base: int, stage_index: int, count: int) -> int:
	if count <= 0:
		return 0
	if daily:
		return DailySeed.to_index(seed, ARENA_SALT, count)  # the single daily arena draw
	return (base + stage_index) % count
