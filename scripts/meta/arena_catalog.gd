class_name ArenaCatalog
extends RefCounted

## Pure arena helpers (no scene/grid deps, testable): deterministic selection and
## fit-to-rect sizing. The dev cycle and Step 09's daily seed both route through
## select() — same path, no RNG.


## Deterministic index from a seed: seed mod count. Handles negative seeds via
## posmod. Returns -1 for an empty catalog.
static func select(count: int, seed: int) -> int:
	if count <= 0:
		return -1
	return posmod(seed, count)


## Fits a cols×rows logical grid into play_rect: the largest integer cell_size that
## fits both axes, with the grid centered. Returns {cell_size: float, origin: Vector2}.
static func compute_fit(cols: int, rows: int, play_rect: Rect2) -> Dictionary:
	var cs: float = floorf(minf(play_rect.size.x / float(cols), play_rect.size.y / float(rows)))
	if cs < 1.0:
		cs = 1.0
	var grid_size := Vector2(cols * cs, rows * cs)
	var origin: Vector2 = play_rect.position + (play_rect.size - grid_size) * 0.5
	return {"cell_size": cs, "origin": origin}
