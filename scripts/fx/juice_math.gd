class_name JuiceMath
extends RefCounted

## Pure, deterministic helpers for juice. No nodes, no randomness -> unit-testable.
## (Camera shake, hit-stop etc. consume these; the visual side stays in their nodes.)


## Trauma after decaying `decay` units/second for `dt` seconds, clamped to [0, 1].
static func decay_trauma(trauma: float, decay: float, dt: float) -> float:
	return clampf(trauma - decay * dt, 0.0, 1.0)


## Shake magnitude from trauma. Quadratic so a light tap barely shakes while a big
## event punches; input is clamped to [0, 1] first.
static func shake_amount(trauma: float) -> float:
	var t: float = clampf(trauma, 0.0, 1.0)
	return t * t


## Minimum distance from `point` to the polyline `points` (the ordered active trail).
## INF for an empty polyline; for a single point, the distance to it. Used by near-miss
## detection (enemy ↔ trail), so a foe grazing the line — not just the head — counts.
static func min_distance_to_polyline(point: Vector2, points: PackedVector2Array) -> float:
	if points.is_empty():
		return INF
	if points.size() == 1:
		return point.distance_to(points[0])
	var best: float = INF
	for i in range(points.size() - 1):
		best = minf(best, _distance_to_segment(point, points[i], points[i + 1]))
	return best


## Continuous danger level [0, 1] from a distance: 0 at/beyond `radius`, 1 at distance 0,
## smoothstep in between. Drives the proximity vignette (closer enemy -> darker red).
static func danger_from_distance(dist: float, radius: float) -> float:
	if radius <= 0.0 or dist >= radius:
		return 0.0
	if dist <= 0.0:
		return 1.0
	return smoothstep(0.0, 1.0, (radius - dist) / radius)


## Shortest distance from `p` to the segment a–b (clamped projection).
static func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq == 0.0:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)
