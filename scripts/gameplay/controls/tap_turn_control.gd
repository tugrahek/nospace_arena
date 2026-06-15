class_name TapTurnControl
extends "res://scripts/gameplay/controls/control_scheme.gd"

## Tap-to-turn: tapping the left half turns 90° counter-clockwise, the right half
## clockwise, relative to the current heading. Auto-advance (always moving).

var _pending_sign: int = 0


func _init() -> void:
	auto_advance = true


func handle_input(event: InputEvent, viewport_size: Vector2) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_pending_sign = 1 if event.position.x >= viewport_size.x * 0.5 else -1


func poll(_viewport_size: Vector2, current_dir: Vector2i) -> Vector2i:
	if _pending_sign == 0:
		return Vector2i.ZERO
	var s: int = _pending_sign
	_pending_sign = 0
	return rotate(current_dir, s)


func reset() -> void:
	_pending_sign = 0


## Pure: rotates a cardinal direction 90°. turn_sign > 0 = clockwise (screen
## coords, y down), else counter-clockwise. ZERO base defaults to RIGHT.
static func rotate(base: Vector2i, turn_sign: int) -> Vector2i:
	var b: Vector2i = base if base != Vector2i.ZERO else Vector2i.RIGHT
	if turn_sign > 0:
		return Vector2i(-b.y, b.x)
	return Vector2i(b.y, -b.x)
