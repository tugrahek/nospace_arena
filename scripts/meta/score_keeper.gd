class_name ScoreKeeper
extends RefCounted

## Pure scoring logic — no scene or singleton deps. Fully testable.
## Combo multiplier grows with rapid successive captures within combo_window seconds.

var base_points: int = 10
var combo_window: float = 2.0

var score: int = 0
var combo: int = 0

var _last_capture_time: float = -999.0


## Records a capture of cell_count cells at time now (seconds).
## Returns the points earned this capture.
func register_capture(cell_count: int, now: float) -> int:
	if now - _last_capture_time <= combo_window:
		combo += 1
	else:
		combo = 0
	_last_capture_time = now
	var earned: int = cell_count * base_points * (combo + 1)
	score += earned
	return earned


func reset() -> void:
	score = 0
	combo = 0
	_last_capture_time = -999.0
