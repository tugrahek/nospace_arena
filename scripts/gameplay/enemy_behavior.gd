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


## Whether this behavior only counts the player as exposed while it can actually SEE them
## (no captured territory on the straight line between). The enemy resolves the sight check —
## behaviors stay grid-free. Base: false (position-only behaviors are never blinded).
func needs_line_of_sight() -> bool:
	return false


## Whether this behavior actually aims at the player, so the enemy should pick the best target
## point for it (head vs nearest trail point, where the adaptive rule is on). Base: false —
## position-blind behaviors (Bouncer) never need the extra work.
func hunts_player() -> bool:
	return false


## Weight for that choice: the head wins while head_distance <= trail_distance * this. 1.0 is
## pure distance. Only meaningful for behaviors that hunt the player.
func target_bias() -> float:
	return 1.0
