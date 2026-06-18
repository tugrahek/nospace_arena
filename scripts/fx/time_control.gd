class_name TimeControl
extends Node

## Single owner / arbiter of Engine.time_scale. Effects (hit-stop, near-miss slow-mo)
## register a scale request under a key; the SMALLEST active request wins (a freeze beats
## a mild slow). Each request expires via its own ignore-time-scale, process-always timer.
## When none remain, time returns to 1.0. This prevents effects from fighting over time_scale.

var _requests: Dictionary = {}  # key:String -> {scale:float, gen:int}
var _gen: int = 0


func _ready() -> void:
	Engine.time_scale = 1.0  # safety on (re)load


## True while any time request is active (time_scale != 1.0). Used to gate ghost recording.
func is_active() -> bool:
	return not _requests.is_empty()


## Applies `scale` for `duration` real seconds under `key`. A same-key request replaces the
## previous one and restarts its timer (stale timers are ignored via the generation token).
func request(key: String, scale: float, duration: float) -> void:
	_gen += 1
	var g: int = _gen
	_requests[key] = {"scale": scale, "gen": g}
	_apply()
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_release.bind(key, g))


func _release(key: String, g: int) -> void:
	if _requests.has(key) and int(_requests[key]["gen"]) == g:
		_requests.erase(key)
		_apply()


func _apply() -> void:
	if _requests.is_empty():
		Engine.time_scale = 1.0
		return
	var lo: float = 1.0
	for v in _requests.values():
		lo = minf(lo, float(v["scale"]))
	Engine.time_scale = lo
