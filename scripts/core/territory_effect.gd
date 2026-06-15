class_name TerritoryEffect
extends Resource

## Base living-territory effect: captured territory influences nearby enemies.
## No-op by default. Concrete effects (PushEffect) and Step 07 characters override.

## Returns the (possibly modified) velocity for an enemy at world_pos.
func compute_velocity(velocity: Vector2, _world_pos: Vector2, _arena: ArenaController) -> Vector2:
	return velocity
