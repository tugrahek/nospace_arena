class_name DpadControl
extends "res://scripts/gameplay/controls/control_scheme.gd"

## Virtual d-pad: while a pointer is held, the direction is the dominant axis of
## the offset from the d-pad center. Release -> stop (hold model). Works with the
## mouse on desktop via emulate_touch_from_mouse.

const DEAD_ZONE: float = 18.0
const RADIUS: float = 90.0
const MARGIN_BOTTOM: float = 220.0

var _touch_pos: Vector2 = Vector2.ZERO
var _held: bool = false


func _init() -> void:
	auto_advance = false


func handle_input(event: InputEvent, _viewport_size: Vector2) -> void:
	if event is InputEventScreenTouch:
		_held = event.pressed
		_touch_pos = event.position
	elif event is InputEventScreenDrag and _held:
		_touch_pos = event.position


func poll(viewport_size: Vector2, _current_dir: Vector2i) -> Vector2i:
	if not _held:
		return Vector2i.ZERO
	return pos_to_dir(_touch_pos, center(viewport_size), DEAD_ZONE)


func reset() -> void:
	_held = false


## Fixed d-pad center in viewport coordinates (bottom-center).
static func center(viewport_size: Vector2) -> Vector2:
	return Vector2(viewport_size.x * 0.5, viewport_size.y - MARGIN_BOTTOM)


## Pure: maps a touch position relative to center to a cardinal direction.
## Within dead_zone -> ZERO. Tie resolves to horizontal.
static func pos_to_dir(touch: Vector2, center_pos: Vector2, dead_zone: float) -> Vector2i:
	var v: Vector2 = touch - center_pos
	if v.length() < dead_zone:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0 else -1)
