class_name MissionService
extends RefCounted

## Builds today's missions from a pool + seed + saved progress. Pure (no IO) — game.gd
## (active) and the menu (read-only) both use it, so they show the identical 3 missions.

const MissionScript = preload("res://scripts/meta/mission.gd")
const MissionCatalogScript = preload("res://scripts/meta/mission_catalog.gd")


## `count` seed-picked missions from `pool`, each with its saved {progress, claimed}
## applied (saved keyed by mission id string). Returns Array[Mission].
static func build(pool: Array, seed: int, count: int, saved: Dictionary) -> Array[Mission]:
	var result: Array[Mission] = []
	var indices: Array[int] = MissionCatalogScript.pick_daily(pool.size(), seed, count)
	for idx in indices:
		var def = pool[idx]
		var m: Mission = MissionScript.new(def)
		var id_str: String = String(def.id)
		if saved.has(id_str):
			m.apply_dict(saved[id_str])
		result.append(m)
	return result
