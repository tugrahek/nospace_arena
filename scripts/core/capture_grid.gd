class_name CaptureGrid
extends RefCounted

## Pure grid-based territory capture logic (Qix/Volfied style).
## No Node, no rendering — fully unit-testable integer logic.
## The outer 1-cell ring is the safe frame; the interior starts FREE.
## A 4-connected TRAIL of FREE cells, once closed back onto CAPTURED, seals off
## every FREE region not reachable from the danger seeds (enemies in Step 04).

enum Cell { FREE = 0, CAPTURED = 1, TRAIL = 2 }

# Preloaded (not referenced via global class_name) so the type resolves under
# GUT's isolated script loader. See test-load notes in PROGRESS.
const CaptureResultScript = preload("res://scripts/core/capture_result.gd")

const _NEIGHBORS: Array[Vector2i] = [
	Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP,
]

var cols: int = 0
var rows: int = 0
var cell_size: float = 10.0
var origin: Vector2 = Vector2.ZERO  # world position of cell (0,0) top-left corner

var total_capturable: int = 0
var captured_interior: int = 0

var _cells: PackedByteArray = PackedByteArray()


func _init(p_cols: int, p_rows: int, p_cell_size: float = 10.0, p_origin: Vector2 = Vector2.ZERO) -> void:
	cols = p_cols
	rows = p_rows
	cell_size = p_cell_size
	origin = p_origin
	_cells.resize(cols * rows)
	init_frame()


## Sets the outer 1-cell ring to CAPTURED (safe frame), interior to FREE.
func init_frame() -> void:
	captured_interior = 0
	for y in rows:
		for x in cols:
			var is_edge: bool = x == 0 or y == 0 or x == cols - 1 or y == rows - 1
			_cells[_index(x, y)] = Cell.CAPTURED if is_edge else Cell.FREE
	total_capturable = (cols - 2) * (rows - 2) if cols > 2 and rows > 2 else 0


func _index(x: int, y: int) -> int:
	return y * cols + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < cols and y >= 0 and y < rows


## Returns the cell state; out-of-bounds is treated as a solid CAPTURED wall.
func cell_at(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return Cell.CAPTURED
	return _cells[_index(x, y)]


## Read-only view of the raw cell states (row-major, index = y * cols + x). Fast READ paths only
## (perf-pass rendering: avoids ~20k cell_at() calls per redraw; enemy line-of-sight walks) — all
## capture LOGIC keeps going through cell_at()/the mutating API. Callers must never write through this.
func cells() -> PackedByteArray:
	return _cells


func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = world_pos - origin
	return Vector2i(int(floor(local.x / cell_size)), int(floor(local.y / cell_size)))


## Returns the world-space center of the given cell.
func cell_to_world(cell: Vector2i) -> Vector2:
	return origin + Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size)


## Marks a single FREE cell as TRAIL during live drawing.
## Returns false if the cell is not FREE (invalid / self-intersection).
func add_trail_cell(cell: Vector2i) -> bool:
	if cell_at(cell.x, cell.y) != Cell.FREE:
		return false
	_cells[_index(cell.x, cell.y)] = Cell.TRAIL
	return true


## Reverts any TRAIL cells back to FREE (used on a failed/aborted line).
func clear_trail() -> void:
	for i in _cells.size():
		if _cells[i] == Cell.TRAIL:
			_cells[i] = Cell.FREE


## Reverts a single TRAIL cell to FREE (used during player backtracking).
func remove_trail_cell(cell: Vector2i) -> void:
	if cell_at(cell.x, cell.y) == Cell.TRAIL:
		_cells[_index(cell.x, cell.y)] = Cell.FREE


## Marks a contiguous 4-connected path of FREE cells as TRAIL in one shot.
## Returns false (leaving the grid unchanged) on out-of-bounds, non-FREE,
## non-adjacent, or self-intersecting paths. Used mainly by tests.
func lay_trail(path: Array) -> bool:
	var seen: Dictionary = {}
	for i in path.size():
		var c: Vector2i = path[i]
		if cell_at(c.x, c.y) != Cell.FREE:
			return false
		if seen.has(c):
			return false
		if i > 0:
			var d: Vector2i = c - path[i - 1]
			if absi(d.x) + absi(d.y) != 1:
				return false
		seen[c] = true
	for c in path:
		_cells[_index(c.x, c.y)] = Cell.TRAIL
	return true


## Converts the current TRAIL into CAPTURED, then captures every FREE region
## not reachable (4-connectivity) from danger_seeds. With no seeds, the largest
## FREE component is treated as the danger side and the rest is captured.
func close_and_capture(danger_seeds: Array = []) -> CaptureResultScript:
	var result := CaptureResultScript.new()
	var newly: Array[Vector2i] = []

	for i in _cells.size():
		if _cells[i] == Cell.TRAIL:
			_cells[i] = Cell.CAPTURED
			newly.append(Vector2i(i % cols, i / cols))

	var seeds: Array[Vector2i] = []
	for s in danger_seeds:
		var sc: Vector2i = s
		if cell_at(sc.x, sc.y) == Cell.FREE:
			seeds.append(sc)
	if seeds.is_empty():
		var largest := _largest_free_component_seed()
		if largest.x >= 0:
			seeds.append(largest)

	var reachable: PackedByteArray = _flood_free(seeds)

	for i in _cells.size():
		if _cells[i] == Cell.FREE and reachable[i] == 0:
			_cells[i] = Cell.CAPTURED
			newly.append(Vector2i(i % cols, i / cols))

	captured_interior += newly.size()
	result.success = true
	result.newly_captured = newly
	result.captured_count = newly.size()
	result.percent = captured_percent()
	return result


## Flood-fills FREE cells reachable from the seeds; returns a row-major reachability mask
## (index = y * cols + x, 1 = reachable). Perf #5: the old Dictionary(Vector2i) bookkeeping
## dominated capture cost on mobile — this keeps the EXACT same traversal (LIFO stack, the
## _NEIGHBORS push order RIGHT/LEFT/DOWN/UP) and only changes the representation, so the
## reachable SET (and every capture result derived from it) is identical.
func _flood_free(seeds: Array) -> PackedByteArray:
	var total: int = cols * rows
	var mask := PackedByteArray()
	mask.resize(total)  # zero-filled
	var stack := PackedInt32Array()
	stack.resize(total)  # each cell is pushed at most once -> capacity bound
	var sp: int = 0
	for s in seeds:
		var sc: Vector2i = s
		if not in_bounds(sc.x, sc.y):
			continue
		var si: int = sc.y * cols + sc.x
		if mask[si] == 0:
			mask[si] = 1
			stack[sp] = si
			sp += 1
	while sp > 0:
		sp -= 1
		var i: int = stack[sp]
		var x: int = i % cols
		# Neighbours in the same order as _NEIGHBORS, with explicit bounds guards — the exact
		# equivalent of cell_at()'s out-of-bounds = CAPTURED wall (never trust the ring alone).
		if x + 1 < cols and _cells[i + 1] == Cell.FREE and mask[i + 1] == 0:  # RIGHT
			mask[i + 1] = 1
			stack[sp] = i + 1
			sp += 1
		if x > 0 and _cells[i - 1] == Cell.FREE and mask[i - 1] == 0:  # LEFT
			mask[i - 1] = 1
			stack[sp] = i - 1
			sp += 1
		if i + cols < total and _cells[i + cols] == Cell.FREE and mask[i + cols] == 0:  # DOWN
			mask[i + cols] = 1
			stack[sp] = i + cols
			sp += 1
		if i - cols >= 0 and _cells[i - cols] == Cell.FREE and mask[i - cols] == 0:  # UP
			mask[i - cols] = 1
			stack[sp] = i - cols
			sp += 1
	return mask


## Returns the row-major-first cell of the largest FREE component, or (-1,-1).
## Tie-break is deterministic (first found) for seed determinism.
## Perf #5: Dictionary(Vector2i) bookkeeping -> flat mask + int stack. The outer scan order
## (ascending row-major) and the strictly-greater tie-break are unchanged, and component
## sizes are set cardinalities (traversal-order independent) -> identical seed out.
func _largest_free_component_seed() -> Vector2i:
	var total: int = cols * rows
	var visited := PackedByteArray()
	visited.resize(total)
	var stack := PackedInt32Array()
	stack.resize(total)
	var best_seed := Vector2i(-1, -1)
	var best_size: int = 0
	for start in total:  # ascending index == the old for-y/for-x row-major scan
		if _cells[start] != Cell.FREE or visited[start] == 1:
			continue
		var size: int = 0
		var sp: int = 0
		stack[sp] = start
		sp += 1
		visited[start] = 1
		while sp > 0:
			sp -= 1
			var i: int = stack[sp]
			size += 1
			var x: int = i % cols
			if x + 1 < cols and _cells[i + 1] == Cell.FREE and visited[i + 1] == 0:  # RIGHT
				visited[i + 1] = 1
				stack[sp] = i + 1
				sp += 1
			if x > 0 and _cells[i - 1] == Cell.FREE and visited[i - 1] == 0:  # LEFT
				visited[i - 1] = 1
				stack[sp] = i - 1
				sp += 1
			if i + cols < total and _cells[i + cols] == Cell.FREE and visited[i + cols] == 0:  # DOWN
				visited[i + cols] = 1
				stack[sp] = i + cols
				sp += 1
			if i - cols >= 0 and _cells[i - cols] == Cell.FREE and visited[i - cols] == 0:  # UP
				visited[i - cols] = 1
				stack[sp] = i - cols
				sp += 1
		if size > best_size:
			best_size = size
			best_seed = Vector2i(start % cols, start / cols)
	return best_seed


func captured_percent() -> float:
	if total_capturable <= 0:
		return 0.0
	return clampf(float(captured_interior) / float(total_capturable) * 100.0, 0.0, 100.0)
