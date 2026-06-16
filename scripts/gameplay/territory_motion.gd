class_name TerritoryMotion
extends RefCounted

## Pure steering/scaling math for living-territory effects — no scene/grid deps, testable.
## (Step 06 PushMotion genelleştirildi: tüm bölge etkilerinin saf matematiği burada.)


## Influence strength 0..1 by distance: 1 at the captured edge (dist 0),
## falling linearly to 0 at/beyond radius. Guards radius <= 0.
static func strength_for(distance: float, radius: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 0.0
	return 1.0 - distance / radius


## Speed multiplier for a slow effect: 1.0 (no slow) at/beyond radius, falling to
## (1 - factor) at the captured edge. Transient — recomputed each frame to avoid
## compounding the stored velocity magnitude.
static func scale_for(distance: float, radius: float, factor: float) -> float:
	if radius <= 0.0 or distance >= radius:
		return 1.0
	var t: float = 1.0 - distance / radius
	return 1.0 - factor * t


## scale_for with a floor: never returns below min_scale. Keeps a slowed enemy
## moving (no zero-speed crawl onto the territory glow), so the bounce stays clean.
static func slow_scale(distance: float, radius: float, factor: float, min_scale: float) -> float:
	return maxf(scale_for(distance, radius, factor), min_scale)


## Rotates velocity toward target_dir by up to (strength * max_turn) radians,
## preserving magnitude. Zero velocity / target_dir / strength leaves it unchanged.
static func steer(velocity: Vector2, target_dir: Vector2, strength: float, max_turn: float) -> Vector2:
	if velocity == Vector2.ZERO or target_dir == Vector2.ZERO or strength <= 0.0:
		return velocity
	var cur: Vector2 = velocity.normalized()
	var target: Vector2 = target_dir.normalized()
	var desired: float = cur.angle_to(target)  # signed shortest angle
	var limit: float = max_turn * strength
	var step: float = clampf(desired, -limit, limit)
	return cur.rotated(step) * velocity.length()
