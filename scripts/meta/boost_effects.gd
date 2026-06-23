class_name BoostEffects
extends RefCounted

## Pure resolver for the run-start boost effect. Given the play mode and the player's armed/owned
## boosts, it returns what to apply (extra lives, slow-start) and which boost ids to consume.
## Honors BoostPolicy (Daily / disallowed modes -> nothing applied, nothing consumed). No IO, no
## RNG -> daily/ghost reproduce. game.gd builds the inputs from Economy and applies the result.

## `armed`  : { id_string -> bool }  (is this boost armed for the next run)
## `counts` : { id_string -> int }   (owned charges)
## Returns  : { extra_lives:int, slow_scale:float, slow_duration:float, consume:Array[StringName] }
static func resolve(mode: int, boosts: Array, armed: Dictionary, counts: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"extra_lives": 0,
		"slow_scale": 1.0,
		"slow_duration": 0.0,
		"consume": [],
	}
	if not BoostPolicy.boosts_allowed(mode):
		return out  # Daily / disallowed -> no effect, no charge spent
	for b in boosts:
		var key: String = String(b.id)
		if not armed.get(key, false) or int(counts.get(key, 0)) <= 0:
			continue
		out["consume"].append(b.id)
		match b.effect:
			BoostData.Effect.EXTRA_LIFE:
				out["extra_lives"] += int(b.magnitude)
			BoostData.Effect.SLOW_START:
				out["slow_scale"] = b.magnitude
				out["slow_duration"] = b.duration
	return out
