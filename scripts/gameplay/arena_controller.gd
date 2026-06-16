class_name ArenaController
extends Node2D

## Owns the CaptureGrid (source of truth for territory) and renders it:
## void background, captured region (neon fill), active trail, and frame border.
## Exposes a thin API the Player uses to move on / draw into the grid.

signal area_captured(percent: float, cells: Array)
signal capture_failed()

@export var arena_rect: Rect2 = Rect2(40.0, 100.0, 640.0, 1100.0)
@export var cell_size: float = 10.0
@export var border_color: Color = Color(0.25, 0.65, 1.0, 1.0)
@export var border_width: float = 3.0
@export var void_color: Color = Color(0.03, 0.02, 0.08, 1.0)
@export var captured_color: Color = Color(0.12, 0.5, 0.95, 0.55)
@export var trail_color: Color = Color(0.2, 0.95, 1.0, 0.95)

var grid: CaptureGrid


func _ready() -> void:
	var cols: int = int(arena_rect.size.x / cell_size)
	var rows: int = int(arena_rect.size.y / cell_size)
	grid = CaptureGrid.new(cols, rows, cell_size, arena_rect.position)
	queue_redraw()


func get_rect() -> Rect2:
	return arena_rect


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return grid.world_to_cell(world_pos)


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid.cell_to_world(cell)


func cell_state(cell: Vector2i) -> int:
	return grid.cell_at(cell.x, cell.y)


func in_bounds_cell(cell: Vector2i) -> bool:
	return grid.in_bounds(cell.x, cell.y)


## True if the cell is captured AND not part of the starting outer frame ring,
## i.e. territory the player actually claimed. Living-territory effects emanate
## only from this — the initial border must never trigger them.
func is_player_captured(cell: Vector2i) -> bool:
	if not in_bounds_cell(cell):
		return false
	if cell_state(cell) != CaptureGrid.Cell.CAPTURED:
		return false
	return not (cell.x == 0 or cell.y == 0 or cell.x == grid.cols - 1 or cell.y == grid.rows - 1)


## Returns the world-space center of the nearest player-captured cell within
## max_radius of world_pos, or Vector2(INF, INF) if none. Shared by territory effects.
func nearest_player_captured(world_pos: Vector2, max_radius: float) -> Vector2:
	var center: Vector2i = world_to_cell(world_pos)
	var r: int = ceili(max_radius / cell_size) + 1
	var best: Vector2 = Vector2(INF, INF)
	var best_dist: float = max_radius  # cells at/beyond radius are ignored
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not is_player_captured(cell):
				continue
			var wp: Vector2 = cell_to_world(cell)
			var d: float = world_pos.distance_to(wp)
			if d < best_dist:
				best_dist = d
				best = wp
	return best


func add_trail(cell: Vector2i) -> bool:
	var ok: bool = grid.add_trail_cell(cell)
	if ok:
		queue_redraw()
	return ok


func close_capture(danger_seeds: Array = []) -> void:
	var result: CaptureResult = grid.close_and_capture(danger_seeds)
	queue_redraw()
	area_captured.emit(result.percent, result.newly_captured)


func fail_trail() -> void:
	grid.clear_trail()
	queue_redraw()
	capture_failed.emit()


## Reverts a single trail cell to FREE during player backtracking.
func remove_trail(cell: Vector2i) -> void:
	grid.remove_trail_cell(cell)
	queue_redraw()


func _draw() -> void:
	draw_rect(arena_rect, void_color)
	if grid == null:
		return
	_draw_state_runs(CaptureGrid.Cell.CAPTURED, captured_color)
	_draw_state_runs(CaptureGrid.Cell.TRAIL, trail_color)
	var r: Rect2 = arena_rect
	draw_polyline(
		PackedVector2Array([
			r.position,
			Vector2(r.position.x + r.size.x, r.position.y),
			r.position + r.size,
			Vector2(r.position.x, r.position.y + r.size.y),
			r.position,
		]),
		border_color,
		border_width,
		true
	)


## Draws all cells of one state, merging horizontal runs into single rects
## to keep the draw-call count low (instead of one rect per cell).
func _draw_state_runs(state: int, color: Color) -> void:
	for y in grid.rows:
		var run_start: int = -1
		for x in grid.cols + 1:
			var matches: bool = x < grid.cols and grid.cell_at(x, y) == state
			if matches and run_start < 0:
				run_start = x
			elif not matches and run_start >= 0:
				var px: float = arena_rect.position.x + run_start * cell_size
				var py: float = arena_rect.position.y + y * cell_size
				var w: float = (x - run_start) * cell_size
				draw_rect(Rect2(px, py, w, cell_size), color)
				run_start = -1
