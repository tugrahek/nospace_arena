class_name ArenaController
extends Node2D

## Owns the CaptureGrid (source of truth for territory) and renders it:
## void background, captured region (neon fill), active trail, and frame border.
## Exposes a thin API the Player uses to move on / draw into the grid.

signal area_captured(percent: float, cells: Array)
signal capture_failed()  # RESERVED (no listeners yet): fail-side twin of area_captured for future FX/analytics

@export var arena_rect: Rect2 = Rect2(40.0, 100.0, 640.0, 1100.0)
@export var cell_size: float = 10.0
@export var border_color: Color = Color(0.25, 0.65, 1.0, 1.0)
@export var border_width: float = 3.0
@export var void_color: Color = Color(0.03, 0.02, 0.08, 1.0)
@export var captured_color: Color = Color(0.12, 0.5, 0.95, 0.55)
@export var trail_color: Color = Color(0.2, 0.95, 1.0, 0.95)

# Feel-pass (visual layer ONLY — the grid state itself always updates instantly):
@export var flash_duration: float = 0.25   # each cell's bright pulse length before settling
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 0.85)  # blended over the captured fill
@export var wave_delay_per_cell: float = 0.007  # extra pulse delay per cell of distance from the
                                                # closure centroid -> the region reads as FILLING
                                                # outward (0 = all cells pulse at once)
@export var wave_max_duration: float = 0.4      # cap on the total sweep: when a region is so big
                                                # that per-cell delays would exceed this, they are
                                                # normalized (delay = dist/max_dist x cap) so huge
                                                # captures sweep as fast as small ones (no crawl)
@export var wave_quantize: float = 1.0 / 30.0   # pulse-start rounding for run merging (perf; ~33 ms
                                                # buckets are invisible to the eye)
@export var glow_width: float = 5.0        # fake-glow halo around the trail (px, gl_compat safe)
@export var glow_alpha: float = 0.28       # halo opacity (fraction of trail_color alpha)
@export var head_brightness: float = 0.45  # how much the trail HEAD cell is lightened

var grid: CaptureGrid

const Catalog = preload("res://scripts/meta/arena_catalog.gd")
const FlashLayerScript = preload("res://scripts/fx/capture_flash_layer.gd")

var _configured: bool = false
var _flash_layer: Node2D = null  # child wave layer — ONLY it redraws per frame during a flash
var _trail_head: Vector2i = Vector2i(-1, -1)  # most recently drawn trail cell (highlight)


func _ready() -> void:
	if not _configured:
		var cols: int = int(arena_rect.size.x / cell_size)
		var rows: int = int(arena_rect.size.y / cell_size)
		grid = CaptureGrid.new(cols, rows, cell_size, arena_rect.position)
	_ensure_flash_layer()
	queue_redraw()


## The wave layer is a code-built child (scene file unchanged); children render after the
## parent, so pulses sit above the base fill automatically.
func _ensure_flash_layer() -> void:
	if _flash_layer == null:
		_flash_layer = FlashLayerScript.new()
		_flash_layer.name = "FlashLayer"
		add_child(_flash_layer)


## Configures the arena from data: fit-to-rect sizing (cell_size/origin derived to
## center the logical grid in play_rect), theme colors, and a fresh grid. Captured
## glow is left to the character (applied after this). Call before Player.setup.
func configure(data, play_rect: Rect2) -> void:
	var fit: Dictionary = Catalog.compute_fit(data.cols, data.rows, play_rect)
	cell_size = fit["cell_size"]
	arena_rect = Rect2(fit["origin"], Vector2(data.cols * cell_size, data.rows * cell_size))
	if data.theme != null:
		void_color = data.theme.void_color
		border_color = data.theme.border_color
		trail_color = data.theme.trail_color
		border_width = data.theme.border_width
	grid = CaptureGrid.new(data.cols, data.rows, cell_size, arena_rect.position)
	_configured = true
	if _flash_layer != null:
		_flash_layer.clear_wave()
	_trail_head = Vector2i(-1, -1)
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
		_trail_head = cell  # newest cell = the head (drawn brighter)
		queue_redraw()
	return ok


func close_capture(danger_seeds: Array = []) -> void:
	var result: CaptureResult = grid.close_and_capture(danger_seeds)
	# Capture flash wave: PAINT-only layer. The grid is fully CAPTURED from this very frame
	# (enemy bounces/danger reads never diverge from what the player sees — the base captured
	# fill is drawn beneath immediately); only the bright pulse travels outward.
	if not result.newly_captured.is_empty() and flash_duration > 0.0:
		_queue_flash_wave(result.newly_captured)
	_trail_head = Vector2i(-1, -1)
	queue_redraw()
	area_captured.emit(result.percent, result.newly_captured)


## Schedules each new cell's pulse at wave_delay_per_cell x its distance (in cells) from the
## capture's centroid -> the region visibly "fills" outward from the closure point. All wave
## bookkeeping/redraw lives in the child FlashLayer (perf-pass): the expensive base fill is
## NOT re-scanned while the wave plays. Later captures merge onto the layer's running clock.
func _queue_flash_wave(newly: Array) -> void:
	if _flash_layer == null and is_inside_tree():
		_ensure_flash_layer()
	if _flash_layer == null:
		return  # logic-only use without a tree: no visual layer, no-op
	var centroid: Vector2 = Vector2.ZERO
	for c in newly:
		centroid += Vector2(c)
	centroid /= float(newly.size())
	var delays: PackedFloat32Array = PackedFloat32Array()
	delays.resize(newly.size())
	var max_dist: float = 0.0
	for i in newly.size():
		var d: float = Vector2(newly[i]).distance_to(centroid)
		delays[i] = d
		max_dist = maxf(max_dist, d)
	# Sweep-time cap: small regions keep the natural per-cell pace; a region big enough to
	# exceed wave_max_duration gets its delays compressed (normalized to the cap) so the wave
	# never crawls. Visual only — the base fill below is complete from frame one regardless.
	var per_cell: float = wave_delay_per_cell
	if wave_max_duration > 0.0 and max_dist * per_cell > wave_max_duration:
		per_cell = wave_max_duration / max_dist
	for i in delays.size():
		delays[i] *= per_cell
	_flash_layer.play(newly, delays, flash_duration, flash_color,
		cell_size, arena_rect.position, wave_quantize)


func fail_trail() -> void:
	grid.clear_trail()
	_trail_head = Vector2i(-1, -1)
	queue_redraw()
	capture_failed.emit()


## Reverts a single trail cell to FREE during player backtracking.
func remove_trail(cell: Vector2i) -> void:
	grid.remove_trail_cell(cell)
	if cell == _trail_head:
		_trail_head = Vector2i(-1, -1)  # head unknown until the next step (visual only)
	queue_redraw()


func _draw() -> void:
	draw_rect(arena_rect, void_color)
	if grid == null:
		return
	_draw_state_runs(CaptureGrid.Cell.CAPTURED, captured_color)
	# Trail fake glow (gl_compat safe): a widened, low-alpha pass UNDER the crisp trail pass.
	if glow_width > 0.0 and glow_alpha > 0.0:
		var halo: Color = trail_color
		halo.a = trail_color.a * glow_alpha
		_draw_state_runs(CaptureGrid.Cell.TRAIL, halo, glow_width)
	_draw_state_runs(CaptureGrid.Cell.TRAIL, trail_color)
	_draw_trail_head()
	# (Capture flash lives on the child FlashLayer — this base item never redraws for it.)
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
## to keep the draw-call count low (instead of one rect per cell). `grow` inflates each
## run rect on all sides (used for the trail's fake-glow under-pass).
## Perf-pass: scans the raw cell buffer directly (read-only) — ~20k cell_at() calls per
## redraw collapse into indexed array reads; identical cells, identical output.
func _draw_state_runs(state: int, color: Color, grow: float = 0.0) -> void:
	var cells: PackedByteArray = grid.cells()
	var cols: int = grid.cols
	for y in grid.rows:
		var base: int = y * cols
		var run_start: int = -1
		for x in cols + 1:
			var matches: bool = x < cols and cells[base + x] == state
			if matches and run_start < 0:
				run_start = x
			elif not matches and run_start >= 0:
				var px: float = arena_rect.position.x + run_start * cell_size
				var py: float = arena_rect.position.y + y * cell_size
				var w: float = (x - run_start) * cell_size
				draw_rect(Rect2(px, py, w, cell_size).grow(grow), color)
				run_start = -1


## Brightens the newest trail cell so the line visibly "leads" from its head.
func _draw_trail_head() -> void:
	if head_brightness <= 0.0 or _trail_head.x < 0:
		return
	if grid.cell_at(_trail_head.x, _trail_head.y) != CaptureGrid.Cell.TRAIL:
		return
	var px: float = arena_rect.position.x + _trail_head.x * cell_size
	var py: float = arena_rect.position.y + _trail_head.y * cell_size
	draw_rect(Rect2(px, py, cell_size, cell_size), trail_color.lightened(head_brightness))
