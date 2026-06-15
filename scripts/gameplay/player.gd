class_name Player
extends Node2D

signal position_changed(new_pos: Vector2)

@export var speed: float = 300.0

var _border_t: float = 0.0
var _direction: int = 0
var _arena_rect: Rect2 = Rect2(0.0, 0.0, 100.0, 100.0)
var _perimeter: float = 400.0
var _touch_active: bool = false
var _touch_finger_id: int = -1


## Call once after the arena rect is known; positions the player at t=0.
func setup(arena_rect: Rect2) -> void:
	_arena_rect = arena_rect
	_perimeter = BorderMath.perimeter(arena_rect)
	_border_t = 0.0
	position = BorderMath.position_at(_arena_rect, _border_t)


func _process(delta: float) -> void:
	_read_keyboard()
	if _direction == 0:
		return
	var delta_t: float = speed * delta / _perimeter * float(_direction)
	_border_t = BorderMath.advance(_border_t, delta_t)
	position = BorderMath.position_at(_arena_rect, _border_t)
	position_changed.emit(position)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		if event.index == _touch_finger_id:
			_direction = _side_to_direction(event.position.x)


func _handle_touch(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed and _touch_finger_id == -1:
		_touch_finger_id = index
		_touch_active = true
		_direction = _side_to_direction(pos.x)
	elif not pressed and index == _touch_finger_id:
		_touch_finger_id = -1
		_touch_active = false
		_direction = 0


func _read_keyboard() -> void:
	if _touch_active:
		return
	var left: bool = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right: bool = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	if left and not right:
		_direction = -1
	elif right and not left:
		_direction = 1
	else:
		_direction = 0


func _side_to_direction(screen_x: float) -> int:
	return -1 if screen_x < get_viewport_rect().size.x * 0.5 else 1
