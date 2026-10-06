class_name MissionService
extends RefCounted

## Builds today's missions from a pool + seed + saved progress. Pure (no IO) — game.gd
## (active) and the menu (read-only) both use it, so they show the identical 3 missions.

const MissionScript = preload("res://scripts/meta/mission.gd")
const MissionCatalogScript = preload("res://scripts/meta/mission_catalog.gd")


## Snapshots existing completed-run state; win/loss both complete a run. No new telemetry.
static func completed_run_stats(score: int, percent: float, areas: int, won: bool,
		stage: int, run_time: float) -> Dictionary:
	return {"score": score, "percent": percent, "areas": areas, "won": won,
		"stage": stage, "run_seconds": floori(run_time), "completed_runs": 1}


## `count` seed-picked missions from `pool`, each with its saved {progress, claimed}
## applied (saved keyed by mission id string). Returns Array[Mission].
static func build(pool: Array, seed: int, count: int, saved: Dictionary) -> Array[Mission]:
	var result: Array[Mission] = []
	var indices: Array[int] = MissionCatalogScript.pick_for_date(pool, seed, count)
	for idx in indices:
		var def = pool[idx]
		var m: Mission = MissionScript.new(def)
		var id_str: String = String(def.id)
		if saved.has(id_str):
			m.apply_dict(saved[id_str])
		result.append(m)
	return result
