class_name MissionCatalog
extends RefCounted

## Deterministic daily mission selection: distinct indices from the pool, derived from
## the day's seed (DailySeed) — everyone gets the same missions that day. No RNG.

const DailySeed = preload("res://scripts/meta/daily_seed.gd")
const MISSION_SALT: int = 0x300


## `count` distinct pool indices for `seed` (clamped to pool size). Deterministic.
static func pick_daily(pool_size: int, seed: int, count: int) -> Array[int]:
	var result: Array[int] = []
	if pool_size <= 0:
		return result
	var want: int = mini(count, pool_size)
	var salt: int = 0
	while result.size() < want and salt < pool_size * 8:
		var idx: int = DailySeed.to_index(seed, MISSION_SALT + salt, pool_size)
		if not result.has(idx):
			result.append(idx)
		salt += 1
	# Safety fill (collisions exhausted): append remaining in order, deterministic.
	for i in pool_size:
		if result.size() >= want:
			break
		if not result.has(i):
			result.append(i)
	return result
