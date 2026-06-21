class_name ScoreKeeper
extends RefCounted

## Pure scoring logic — no scene or singleton deps. Fully testable.
## Combo multiplier grows with rapid successive captures within combo_window seconds.

var base_points: int = 10
var combo_window: float = 2.0
var exposed_points_per_sec: float = 0.0  # risk reward; 0 = disabled (back-compat default)
var exposed_cap_sec: float = 0.0          # max exposed seconds counted per capture
var life_loss_penalty: int = 0            # score lost per life (floored at 0)

var score: int = 0
var combo: int = 0

var _last_capture_time: float = -999.0


## Records a capture of cell_count cells at time now (seconds), plus a small bonus for
## exposed_seconds spent drawing in the open (capped). Returns the points earned this capture.
func register_capture(cell_count: int, now: float, exposed_seconds: float = 0.0) -> int:
	if now - _last_capture_time <= combo_window:
		combo += 1
	else:
		combo = 0
	_last_capture_time = now
	var earned: int = cell_count * base_points * (combo + 1)
	earned += _exposed_bonus(exposed_seconds)
	score += earned
	return earned


## Risk bonus for time spent exposed (capped at exposed_cap_sec). Floored to whole points.
func _exposed_bonus(exposed_seconds: float) -> int:
	if exposed_points_per_sec <= 0.0 or exposed_seconds <= 0.0:
		return 0
	var secs: float = minf(exposed_seconds, exposed_cap_sec) if exposed_cap_sec > 0.0 else exposed_seconds
	return int(floor(secs * exposed_points_per_sec))


## Applies the per-life score penalty, floored at 0. Returns the points actually deducted.
func apply_life_penalty() -> int:
	var deducted: int = mini(life_loss_penalty, score)
	score -= deducted
	return deducted


func reset() -> void:
	score = 0
	combo = 0
	_last_capture_time = -999.0
