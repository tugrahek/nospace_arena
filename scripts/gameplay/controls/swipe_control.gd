class_name SwipeControl
extends "res://scripts/gameplay/controls/control_scheme.gd"

## Swipe: drag past a threshold sets the dominant-axis cardinal direction.
## Auto-advance (always moving); one direction change per swipe.

@export var swipe_threshold: float = 24.0

var _start_pos: Vector2 = Vector2.ZERO
var _tracking: bool = false
var _consumed: bool = false
var _pending: Vector2i = Vector2i.ZERO


func _init() -> void:
	auto_advance = true


func handle_input(event: InputEvent, _viewport_size: Vector2) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_pos = event.position
			_tracking = true
			_consumed = false
		else:
			_tracking = false
			_consumed = false
	elif event is InputEventScreenDrag and _tracking and not _consumed:
		var d: Vector2i = vector_to_dir(event.position - _start_pos, swipe_threshold)
		if d != Vector2i.ZERO:
			_pending = d
			_consumed = true


func poll(_viewport_size: Vector2, _current_dir: Vector2i) -> Vector2i:
	var d: Vector2i = _pending
	_pending = Vector2i.ZERO
	return d


func reset() -> void:
	_tracking = false
	_consumed = false
	_pending = Vector2i.ZERO


## Pure: converts a drag vector to a cardinal direction, or ZERO under threshold.
## Tie (|x| == |y|) resolves to horizontal for determinism.
static func vector_to_dir(v: Vector2, threshold: float) -> Vector2i:
	if v.length() < threshold:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0 else -1)
