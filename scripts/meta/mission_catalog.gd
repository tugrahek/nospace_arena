class_name MissionCatalog
extends RefCounted

## Date-seeded distinct definitions, with stateless neighboring-day anti-repeat selection.
## Similar families within a day remain legal. DailySeed's arena derivation is unchanged.

const DailySeed = preload("res://scripts/meta/daily_seed.gd")
const MISSION_SALT: int = 0x300
const ROTATION_SALT: int = 0x400
const CANDIDATE_LIMIT: int = 128
const SECONDS_PER_DAY: int = 86400
const EpochDay = preload("res://scripts/meta/epoch_day.gd")


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


## Stateless date rotation. Anchor days are seeded draws; intervening days compare both
## adjacent anchors, so no recursive yesterday state or within-day family quotas are needed.
static func pick_for_date(pool: Array, seed: int, count: int) -> Array[int]:
	var want: int = clampi(count, 0, pool.size())
	if want == 0:
		return []
	var date: Dictionary = Time.get_datetime_dict_from_datetime_string(DailySeed.date_string(seed), false)
	var day: int = EpochDay.from_date(date.year, date.month, date.day)
	if pool.size() <= want + 1:
		var cyclic: Array[int] = []
		for slot in want:
			cyclic.append(posmod(day + slot, pool.size()))
		return cyclic
	if posmod(day, 2) == 0:
		return pick_daily(pool.size(), seed, want)
	var neighbors: Array[Array] = [pick_daily(pool.size(), _seed_for_day(day - 1), want),
		pick_daily(pool.size(), _seed_for_day(day + 1), want)]
	var best: Array[int] = pick_daily(pool.size(), seed, want)
	var best_cost: int = _cost(best, pool, neighbors)
	for attempt in CANDIDATE_LIMIT:
		var candidate: Array[int] = pick_daily(pool.size(), DailySeed.derive(seed, ROTATION_SALT + attempt), want)
		var cost: int = _cost(candidate, pool, neighbors)
		if cost < best_cost:
			best = candidate
			best_cost = cost
		if best_cost == 0:
			return best
	return _improve_by_replacement(best, pool, neighbors)


static func _seed_for_day(day: int) -> int:
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(day * SECONDS_PER_DAY)
	return DailySeed.seed_for_date(date.year, date.month, date.day)


static func _composition(indices: Array, pool: Array) -> Dictionary:
	var families: Dictionary = {}
	for index in indices:
		var family: int = pool[index].goal_type
		families[family] = int(families.get(family, 0)) + 1
	return families


static func _same_set(first: Array, second: Array) -> bool:
	var a: Array = first.duplicate()
	var b: Array = second.duplicate()
	a.sort()
	b.sort()
	return a == b


static func _cost(candidate: Array, pool: Array, neighbors: Array[Array]) -> int:
	var cost: int = 0
	for neighbor in neighbors:
		cost += 1000 if _same_set(candidate, neighbor) else 0
		cost += 100 if _composition(candidate, pool) == _composition(neighbor, pool) else 0
		for slot in candidate.size():
			cost += 1 if candidate[slot] == neighbor[slot] else 0
	return cost


static func _improve_by_replacement(best: Array[int], pool: Array, neighbors: Array[Array]) -> Array[int]:
	# Exhaust all single replacements as a bounded fallback; exact-set repeats have priority.
	var best_cost: int = _cost(best, pool, neighbors)
	for slot in best.size():
		for index in pool.size():
			if best.has(index):
				continue
			var candidate: Array[int] = best.duplicate()
			candidate[slot] = index
			var cost: int = _cost(candidate, pool, neighbors)
			if cost < best_cost:
				best = candidate
				best_cost = cost
	return best
