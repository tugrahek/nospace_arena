class_name HitStop
extends Node

## Brief time freeze on impact. Delegates to TimeControl (the single owner of
## Engine.time_scale) so it never fights with near-miss slow-mo. `time_control` is injected
## by the game in _ready. Capture-freeze feel knobs are @export.

@export var capture_duration: float = 0.06  # real seconds of freeze on a capture
@export var scale_during: float = 0.02       # near-frozen (not exactly 0 to avoid edge cases)

var time_control: TimeControl = null


## True while any time effect is active (delegates to the arbiter).
func is_active() -> bool:
	return time_control != null and time_control.is_active()


## Freezes time briefly. `duration` < 0 uses capture_duration.
func stop(duration: float = -1.0) -> void:
	if time_control == null:
		return
	var d: float = capture_duration if duration < 0.0 else duration
	time_control.request("hitstop", scale_during, d)
