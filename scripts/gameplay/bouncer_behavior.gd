class_name BouncerBehavior
extends "res://scripts/gameplay/enemy_behavior.gd"

## Keeps its heading; direction changes come only from wall bounces (S04 behavior).
## Ignores player state. Effects still apply on top — Push/Drag/Halt unchanged from before.

func decide(velocity: Vector2, _enemy_pos: Vector2, _player_pos: Vector2, _player_exposed: bool, _base_speed_px: float) -> Vector2:
	return velocity
