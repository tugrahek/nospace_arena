class_name Enemy
extends Node2D

## Roams the FREE arena area, bouncing off CAPTURED cells and the arena edge.
## Touching the active TRAIL is lethal to the player (emits hit_trail).

signal hit_trail()

@export var radius: float = 9.0
@export var color: Color = Color(1.0, 0.25, 0.2, 1.0)

var _arena: ArenaController
var _velocity: Vector2 = Vector2.ZERO


func setup(arena: ArenaController, start_pos: Vector2, velocity: Vector2) -> void:
	_arena = arena
	position = start_pos
	_velocity = velocity
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _arena == null or not GameState.is_playing():
		return
	_move(delta)


## Sub-stepped movement so a fast enemy cannot tunnel through a 1-cell trail/wall.
func _move(delta: float) -> void:
	if _velocity == Vector2.ZERO:
		return
	var remaining: float = _velocity.length() * delta
	var step_len: float = _arena.cell_size * 0.5
	while remaining > 0.0:
		var step: float = minf(step_len, remaining)
		remaining -= step
		if not _advance(step):
			return


## Advances one sub-step. Bounces off CAPTURED, dies on TRAIL (returns false).
func _advance(step: float) -> bool:
	var dir: Vector2 = _velocity.normalized()
	var next_pos: Vector2 = position + dir * step
	var sx: int = _state_at(Vector2(next_pos.x, position.y))
	var sy: int = _state_at(Vector2(position.x, next_pos.y))
	var sd: int = _state_at(next_pos)
	if sx == CaptureGrid.Cell.TRAIL or sy == CaptureGrid.Cell.TRAIL or sd == CaptureGrid.Cell.TRAIL:
		hit_trail.emit()
		return false
	var block_x: bool = sx == CaptureGrid.Cell.CAPTURED
	var block_y: bool = sy == CaptureGrid.Cell.CAPTURED
	if block_x or block_y:
		_velocity = EnemyMotion.reflect(_velocity, block_x, block_y)
		return true
	if sd == CaptureGrid.Cell.CAPTURED:
		_velocity = EnemyMotion.reflect(_velocity, true, true)  # diagonal corner
		return true
	position = next_pos
	queue_redraw()
	return true


func _state_at(world: Vector2) -> int:
	return _arena.cell_state(_arena.world_to_cell(world))


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
