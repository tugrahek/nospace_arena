class_name EnemyBehavior
extends Resource

## Strategy for an enemy's per-frame MOVEMENT decision (heading + speed). The shared
## layer (territory effect steer/speed_scale, collision/reflect, contact-freeze) is
## applied on top by the enemy, so behaviors stay pure and deterministic (no arena/node,
## no RNG). Adding a behavior is cheap — subclass and override decide (like TerritoryEffect).

## Returns the desired velocity this frame. `player_exposed` is true while the player is
## drawing a trail in the open (vulnerable); false while safe on captured territory.
## `variation` ([-1,1], per-enemy) lets a behavior offset itself so identical enemies don't
## overlap (e.g. chaser homing angle). Base = identity (keep current heading).
func decide(velocity: Vector2, _enemy_pos: Vector2, _player_pos: Vector2, _player_exposed: bool, _base_speed_px: float, _variation: float = 0.0) -> Vector2:
	return velocity
