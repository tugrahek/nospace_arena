class_name PushEffect
extends "res://scripts/core/territory_effect.gd"

## Living-territory effect: enemies near player-captured territory are steered away,
## as if the void region repels them. Speed magnitude is preserved — only heading
## turns — so the existing constant-speed bounce invariant stays intact.

const PushMotion = preload("res://scripts/gameplay/push_motion.gd")

@export var push_radius: float = 80.0       # world px; influence range
@export var push_max_turn_deg: float = 8.0  # max heading turn per frame at full strength


func compute_velocity(velocity: Vector2, world_pos: Vector2, arena: ArenaController) -> Vector2:
	if velocity == Vector2.ZERO:
		return velocity
	var center: Vector2i = arena.world_to_cell(world_pos)
	var r: int = ceili(push_radius / arena.cell_size) + 1
	var nearest: Vector2 = Vector2.ZERO
	var best_dist: float = push_radius  # cells at/beyond radius are ignored
	var found: bool = false
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not arena.is_player_captured(cell):
				continue
			var wp: Vector2 = arena.cell_to_world(cell)
			var d: float = world_pos.distance_to(wp)
			if d < best_dist:
				best_dist = d
				nearest = wp
				found = true
	if not found:
		return velocity
	var strength: float = PushMotion.strength_for(best_dist, push_radius)
	var away: Vector2 = world_pos - nearest
	return PushMotion.steer(velocity, away, strength, deg_to_rad(push_max_turn_deg))
