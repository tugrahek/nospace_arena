class_name BorderMath

## Pure static math for rectangular border parametric representation.
## t in [0, 1) moves clockwise from the top-left corner.

static func perimeter(rect: Rect2) -> float:
	return 2.0 * (rect.size.x + rect.size.y)


## Returns the world position on rect's border for the given t in [0, 1).
static func position_at(rect: Rect2, t: float) -> Vector2:
	t = fposmod(t, 1.0)
	var dist: float = t * perimeter(rect)
	var w: float = rect.size.x
	var h: float = rect.size.y
	if dist < w:
		return Vector2(rect.position.x + dist, rect.position.y)
	dist -= w
	if dist < h:
		return Vector2(rect.position.x + w, rect.position.y + dist)
	dist -= h
	if dist < w:
		return Vector2(rect.position.x + w - dist, rect.position.y + h)
	dist -= w
	return Vector2(rect.position.x, rect.position.y + h - dist)


## Snaps pos to the nearest point on rect's border and returns its t value.
static func nearest_t(rect: Rect2, pos: Vector2) -> float:
	var p: float = perimeter(rect)
	var w: float = rect.size.x
	var h: float = rect.size.y
	var dist_top: float = absf(pos.y - rect.position.y)
	var dist_right: float = absf(pos.x - (rect.position.x + w))
	var dist_bottom: float = absf(pos.y - (rect.position.y + h))
	var dist_left: float = absf(pos.x - rect.position.x)
	var min_dist: float = minf(minf(dist_top, dist_right), minf(dist_bottom, dist_left))
	var dist_along: float
	if absf(dist_top - min_dist) < 0.001:
		dist_along = clampf(pos.x - rect.position.x, 0.0, w)
	elif absf(dist_right - min_dist) < 0.001:
		dist_along = w + clampf(pos.y - rect.position.y, 0.0, h)
	elif absf(dist_bottom - min_dist) < 0.001:
		dist_along = w + h + clampf(rect.position.x + w - pos.x, 0.0, w)
	else:
		dist_along = w + h + w + clampf(rect.position.y + h - pos.y, 0.0, h)
	return dist_along / p


## Returns t advanced by delta_t, wrapping within [0, 1).
static func advance(t: float, delta_t: float) -> float:
	return fposmod(t + delta_t, 1.0)
