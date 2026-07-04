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


static func _arena_for(daily: bool, seed: int, base: int, stage_index: int, count: int) -> int:
	if count <= 0:
		return 0
	if daily:
		return DailySeed.to_index(seed, ARENA_SALT, count)  # the single daily arena draw
	return (base + stage_index) % count
