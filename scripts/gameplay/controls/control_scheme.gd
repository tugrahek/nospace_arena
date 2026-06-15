class_name ControlScheme
extends RefCounted

## Base interface for pluggable control schemes. Each scheme interprets raw input
## and reports a desired movement direction; it never touches movement directly.
## The Player owns one active scheme and reads it through poll().

## true: player keeps moving when idle (auto-advance); false: idle -> stop (hold).
var auto_advance: bool = false


## Feeds an input event to the scheme (touch / drag for pointer schemes).
func handle_input(_event: InputEvent, _viewport_size: Vector2) -> void:
	pass


## Returns the desired direction this frame. Vector2i.ZERO means "no input".
## current_dir lets relative schemes (tap-to-turn) rotate from the real heading.
func poll(_viewport_size: Vector2, _current_dir: Vector2i) -> Vector2i:
	return Vector2i.ZERO


## Clears any pending / held state (called on scheme switch).
func reset() -> void:
	pass
