class_name DpadControl
extends "res://scripts/gameplay/controls/control_scheme.gd"

## Floating d-pad: the first accepted touch establishes a temporary origin.
## Its dominant-axis offset steers until that same finger releases. Works with the
## mouse on desktop via emulate_touch_from_mouse.

const DEAD_ZONE: float = 18.0
const RADIUS: float = 90.0

var _touch_pos: Vector2 = Vector2.ZERO
var touch_origin: Vector2 = Vector2.ZERO
var _touch_index: int = -1


func _init() -> void:
	auto_advance = false


func handle_input(event: InputEvent, viewport_size: Vector2) -> void:
	if event is InputEventScreenTouch:
		if event.index == _touch_index and (not event.pressed or event.canceled):
			reset()
		elif event.pressed and not event.canceled and not is_held():
			if not Rect2(Vector2.ZERO, viewport_size).has_point(event.position):
				return
			_touch_index = event.index
			touch_origin = event.position
			_touch_pos = event.position
	elif event is InputEventScreenDrag and event.index == _touch_index and is_held():
		_touch_pos = event.position


func poll(_viewport_size: Vector2, _current_dir: Vector2i) -> Vector2i:
	if not is_held():
		return Vector2i.ZERO
	return pos_to_dir(_touch_pos, touch_origin, DEAD_ZONE)


func reset() -> void:
	_touch_index = -1
	_touch_pos = Vector2.ZERO
	touch_origin = Vector2.ZERO


## Whether a controlling finger owns the current gesture.
func is_held() -> bool:
	return _touch_index >= 0


## Pure: maps a touch position relative to center to a cardinal direction.
## Within dead_zone -> ZERO. Tie resolves to horizontal.
static func pos_to_dir(touch: Vector2, center_pos: Vector2, dead_zone: float) -> Vector2i:
	var v: Vector2 = touch - center_pos
	if v.length() <= dead_zone:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0 else -1)
