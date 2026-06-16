class_name PushEffect
extends "res://scripts/core/territory_effect.gd"

## Steers enemies AWAY from player-captured territory, as if the void repels them.
## Magnitude preserved (heading only) so the constant-speed bounce invariant holds.

const TerritoryMotion = preload("res://scripts/gameplay/territory_motion.gd")

@export var push_radius: float = 80.0       # world px; influence range
@export var push_max_turn_deg: float = 8.0  # max heading turn per frame at full strength


func steer(velocity: Vector2, world_pos: Vector2, arena: ArenaController) -> Vector2:
	if velocity == Vector2.ZERO:
		return velocity
	var nearest: Vector2 = arena.nearest_player_captured(world_pos, push_radius)
	if is_inf(nearest.x):
		return velocity
	var dist: float = world_pos.distance_to(nearest)
	var strength: float = TerritoryMotion.strength_for(dist, push_radius)
	var away: Vector2 = world_pos - nearest
	return TerritoryMotion.steer(velocity, away, strength, deg_to_rad(push_max_turn_deg))
