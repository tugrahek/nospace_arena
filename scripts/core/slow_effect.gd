class_name SlowEffect
extends "res://scripts/core/territory_effect.gd"

## Slows enemies near player-captured territory. Transient (no compounding): only
## scales this frame's travel via speed_scale, never the stored velocity magnitude.
## A min_scale floor keeps the enemy moving (no zero-speed crawl) so bounce stays clean.

const TerritoryMotion = preload("res://scripts/gameplay/territory_motion.gd")

@export var slow_radius: float = 80.0
@export var slow_factor: float = 0.55  # core slow strength: edge scale = 1 - factor
@export var min_scale: float = 0.40    # speed never drops below this fraction


func speed_scale(world_pos: Vector2, arena: ArenaController) -> float:
	var nearest: Vector2 = arena.nearest_player_captured(world_pos, slow_radius)
	if is_inf(nearest.x):
		return 1.0
	var dist: float = world_pos.distance_to(nearest)
	return TerritoryMotion.slow_scale(dist, slow_radius, slow_factor, min_scale)
