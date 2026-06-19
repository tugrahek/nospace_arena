class_name StagePlan
extends RefCounted

## Pure, deterministic per-stage spec for the progression spine (D1=A). No nodes, no RNG.
## Daily stages derive from the seed so everyone plays the same escalating sequence (fair
## leaderboard/ghost); free-play cycles arenas + ramps difficulty. GUT-testable.
##
## ARENA_SALT mirrors game.gd's ARENA_SALT and stage 0 uses it unshifted, so stage 0 == the
## existing daily arena draw (today's arena is unchanged). Later stages are salt-shifted.

const ARENA_SALT: int = 1
const STAGE_STRIDE: int = 101      # spaces per-stage arena salts apart (avoid collisions)
const STAGE_SEED_SALT: int = 0x1000


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
	var stage_seed: int = 0
	if daily:
		stage_seed = seed if stage_index == 0 else DailySeed.derive(seed, STAGE_SEED_SALT + stage_index)
	return {
		"arena_index": _arena_for(daily, seed, base_arena_index, stage_index, arena_count),
		"speed_scale": speed_scale,
		"enemy_bonus": enemy_bonus,
		"target_bonus": target_ramp * float(stage_index),
		"stage_seed": stage_seed,
	}


static func _arena_for(daily: bool, seed: int, base: int, stage_index: int, count: int) -> int:
	if count <= 0:
		return 0
	if daily:
		return DailySeed.to_index(seed, ARENA_SALT + stage_index * STAGE_STRIDE, count)
	return (base + stage_index) % count
