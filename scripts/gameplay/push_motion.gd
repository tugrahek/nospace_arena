class_name PushMotion
extends RefCounted

## Pure steering math for the push territory effect — no scene/grid deps, testable.


## Influence strength 0..1 by distance: 1 at the captured edge (dist 0),
## falling linearly to 0 at/beyond radius. Guards radius <= 0.
static func strength_for(distance: float, radius: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 0.0
	return 1.0 - distance / radius


## Rotates velocity toward away_dir by up to (strength * max_turn) radians,
## preserving magnitude. Zero velocity / away_dir / strength leaves it unchanged.
static func steer(velocity: Vector2, away_dir: Vector2, strength: float, max_turn: float) -> Vector2:
	if velocity == Vector2.ZERO or away_dir == Vector2.ZERO or strength <= 0.0:
		return velocity
	var cur: Vector2 = velocity.normalized()
	var target: Vector2 = away_dir.normalized()
	var desired: float = cur.angle_to(target)  # signed shortest angle
	var limit: float = max_turn * strength
	var step: float = clampf(desired, -limit, limit)
	return cur.rotated(step) * velocity.length()
