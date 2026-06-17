class_name Mission
extends RefCounted

## Runtime state for one mission: progress toward its def's goal + claimed flag.
## advance() is evaluated at run end with {score, percent, areas, won}. REACH_* take the
## best single-run value (max); TOTAL_AREAS / WIN_RUNS accumulate across runs. claim() is
## idempotent — the reward is paid exactly once (no double reward). Pure, GUT-testable.

const MissionDefScript = preload("res://scripts/meta/mission_def.gd")

var def  # MissionDef
var progress: int = 0
var claimed: bool = false


func _init(p_def = null) -> void:
	def = p_def


func advance(stats: Dictionary) -> void:
	match def.goal_type:
		MissionDefScript.GoalType.REACH_SCORE:
			progress = maxi(progress, int(stats.get("score", 0)))
		MissionDefScript.GoalType.REACH_PERCENT:
			progress = maxi(progress, int(stats.get("percent", 0)))
		MissionDefScript.GoalType.TOTAL_AREAS:
			progress += int(stats.get("areas", 0))
		MissionDefScript.GoalType.WIN_RUNS:
			progress += 1 if stats.get("won", false) else 0
	progress = mini(progress, def.goal_amount)  # cap at goal (display 3/3, not 5/3)


func is_complete() -> bool:
	return progress >= def.goal_amount


## Pays the reward once: returns reward the first time it's complete-and-unclaimed, else 0.
func claim() -> int:
	if is_complete() and not claimed:
		claimed = true
		return def.reward
	return 0


func to_dict() -> Dictionary:
	return {"progress": progress, "claimed": claimed}


func apply_dict(d: Dictionary) -> void:
	progress = int(d.get("progress", 0))
	claimed = bool(d.get("claimed", false))
