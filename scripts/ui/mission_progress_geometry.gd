class_name MissionProgressGeometry
extends Control

## Real-valued arena capture or one checkpoint per integer objective unit.

const PALETTE: PaletteData = preload("res://config/palette.tres")
@export var arena_height: float = 130.0
@export_range(1, 12, 1) var arena_columns: int = 8
@export_range(1, 8, 1) var arena_rows: int = 4
@export var checkpoint_radius: float = 32.0
@export var checkpoint_spacing: float = 440.0
@export_range(1, 20, 1) var grid_columns: int = 10
@export var grid_row_spacing: float = 24.0
@export var frontier_width: float = 3.0
var _ratio: float = 0.0
var _current: int = 0
var _goal: int = 0
var _complete: bool = false
var _discrete: bool = false
var _goal_type: int = MissionDef.GoalType.REACH_SCORE


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 130.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(queue_redraw)


## Binds display state only; the source mission remains untouched.
func configure(current: int, goal: int, ratio: float, complete: bool, goal_type: int) -> void:
	_current = current
	_goal = goal
	_ratio = ratio
	_complete = complete
	_goal_type = goal_type
	_discrete = goal_type in [MissionDef.GoalType.WIN_RUNS, MissionDef.GoalType.TOTAL_AREAS,
		MissionDef.GoalType.REACH_STAGE, MissionDef.GoalType.COMPLETE_RUNS]
	var rows: int = ceili(float(maxi(goal, 1)) / grid_columns) if _discrete else 1
	custom_minimum_size.y = maxf(130.0, (rows - 1) * grid_row_spacing + 40.0)
	queue_redraw()


## Continuous captured territory has exactly the canonical progress ratio.
func captured_area_ratio() -> float:
	if _goal_type == MissionDef.GoalType.REACH_PERCENT:
		var total: float = 0.0
		for width in territory_row_ratios():
			total += width
		return total / arena_rows
	return _ratio


## Equal-height strips have zero-sum width offsets: exact coverage with a connected silhouette.
func territory_row_ratios() -> Array[float]:
	var widths: Array[float] = []
	var weights: Array[float] = [0.65, -0.15, 0.30, -0.80]
	var mean: float = 0.0
	for row in arena_rows:
		mean += weights[row % weights.size()]
	mean /= arena_rows
	var amplitude: float = minf(_ratio, 1.0 - _ratio) * 0.60
	for row in arena_rows:
		widths.append(_ratio + (weights[row % weights.size()] - mean) * amplitude)
	return widths


## One captured cell represents one actual completed area, never a decorative fraction.
func captured_cell_count() -> int:
	return clampi(_current, 0, _goal)


## Captured, next and future states correspond directly to integer progress.
func checkpoint_state(index: int) -> StringName:
	if index < _current:
		return &"captured"
	if index == _current and not _complete:
		return &"next"
	return &"future"


func _draw() -> void:
	match _goal_type:
		MissionDef.GoalType.TOTAL_AREAS:
			_draw_area_field()
		MissionDef.GoalType.REACH_PERCENT:
			_draw_percent_territory()
		MissionDef.GoalType.WIN_RUNS, MissionDef.GoalType.REACH_STAGE, MissionDef.GoalType.COMPLETE_RUNS:
			_draw_checkpoints()
		_:
			_draw_arena()


func _draw_area_field() -> void:
	var columns: int = mini(maxi(_goal, 1), grid_columns)
	var rows: int = ceili(float(maxi(_goal, 1)) / columns)
	var field := Rect2(8.0, (size.y - arena_height) * 0.5, size.x - 16.0, arena_height)
	var cell_size := Vector2(field.size.x / columns, field.size.y / rows)
	for index in _goal:
		var row: int = floori(float(index) / columns)
		var captured: bool = index < captured_cell_count()
		var cell := Rect2(field.position + Vector2(index % columns, row) * cell_size, cell_size)
		var shade: float = float((index + row) % 3) * 0.08
		var fill: Color = PALETTE.accent.darkened(0.10 + shade) if captured else PALETTE.void_bg.darkened(0.28)
		if captured:
			draw_rect(cell, fill)
			draw_rect(cell, _alpha(PALETTE.accent, 0.09), false, 1.0)
		else:
			_draw_area_cell(cell.grow(-0.7), fill, false)
	if not _complete:
		_draw_area_frontier(field, cell_size, columns, rows)


func _draw_area_frontier(field: Rect2, cell_size: Vector2, columns: int, rows: int) -> void:
	var row: int = floori(float(captured_cell_count()) / columns)
	var remainder: int = captured_cell_count() % columns
	var y: float = field.position.y + row * cell_size.y
	var x: float = field.position.x + remainder * cell_size.x
	var boundary := PackedVector2Array()
	if row > 0:
		boundary.append(Vector2(field.end.x, y))
	boundary.append(Vector2(x, y))
	if remainder > 0 or _current == 0:
		boundary.append(Vector2(x, y + cell_size.y))
		if row + 1 < rows and remainder > 0:
			boundary.append(Vector2(field.position.x, y + cell_size.y))
	if boundary.size() >= 2:
		draw_polyline(boundary, PALETTE.accent_alt, frontier_width, true)
	var marker_y: float = y + cell_size.y * 0.5 if remainder > 0 or _current == 0 else y
	_draw_diamond(Vector2(x, marker_y), 5.0, PALETTE.accent, PALETTE.accent)


func _draw_area_cell(cell: Rect2, fill: Color, captured: bool) -> void:
	# Detached territory patches echo the module's clipped arena corners, not table rules.
	var cut: float = 3.0
	var points := PackedVector2Array([cell.position, Vector2(cell.end.x - cut, cell.position.y),
		Vector2(cell.end.x, cell.position.y + cut), cell.end,
		Vector2(cell.position.x + cut, cell.end.y), Vector2(cell.position.x, cell.end.y - cut)])
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, _alpha(PALETTE.accent if captured else PALETTE.text_secondary, 0.22 if captured else 0.055), 1.0, true)


func _draw_percent_territory() -> void:
	var arena := Rect2(8.0, (size.y - arena_height) * 0.5, size.x - 16.0, arena_height)
	var widths: Array[float] = territory_row_ratios()
	_draw_territory_cells(arena, widths)
	draw_rect(arena, _alpha(PALETTE.border, 0.45), false, 1.0)
	if _complete:
		_draw_check(Vector2(arena.end.x - 23.0, arena.position.y + 22.0), PALETTE.void_bg, 8.0)
		return
	var boundary := PackedVector2Array()
	var row_height: float = arena.size.y / arena_rows
	for row in arena_rows:
		var x: float = arena.position.x + arena.size.x * widths[row]
		boundary.append(Vector2(x, arena.position.y + row * row_height))
		boundary.append(Vector2(x, arena.position.y + (row + 1) * row_height))
	draw_polyline(boundary, PALETTE.accent_alt, frontier_width, true)
	var marker_row: int = mini(1, arena_rows - 1)
	var marker := Vector2(arena.position.x + arena.size.x * widths[marker_row], arena.position.y + (marker_row + 0.5) * row_height)
	_draw_diamond(marker, 8.0, PALETTE.accent.lightened(0.5), PALETTE.accent)


func _draw_arena() -> void:
	var arena := Rect2(8.0, (size.y - arena_height) * 0.5, size.x - 16.0, arena_height)
	draw_rect(arena, PALETTE.void_bg.darkened(0.35))
	_draw_territory_cells(arena)
	draw_rect(arena, _alpha(PALETTE.border, 0.45), false, 1.0)
	if _complete:
		_draw_check(Vector2(arena.end.x - 23.0, arena.position.y + 22.0), PALETTE.void_bg, 8.0)
	else:
		var frontier_x: float = arena.position.x + arena.size.x * _ratio
		draw_line(Vector2(frontier_x, arena.position.y), Vector2(frontier_x, arena.end.y), PALETTE.accent_alt, frontier_width, true)
		_draw_diamond(Vector2(frontier_x, arena.get_center().y), 8.0, PALETTE.accent.lightened(0.5), PALETTE.accent)


func _draw_territory_cells(arena: Rect2, widths: Array[float] = []) -> void:
	# Fixed spatial tessellation with deterministic surface shading, never synthetic progress.
	var cell_size := Vector2(arena.size.x / arena_columns, arena.size.y / arena_rows)
	for row in arena_rows:
		var row_ratio: float = widths[row] if not widths.is_empty() else _ratio
		var frontier_x: float = arena.position.x + arena.size.x * row_ratio
		for column in arena_columns:
			var cell := Rect2(arena.position + Vector2(column, row) * cell_size, cell_size)
			var shade: float = float((column + row * 2) % 4) / 3.0
			_draw_cell(cell, PALETTE.void_bg.darkened(0.16 + shade * 0.18))
			var captured_width: float = clampf(frontier_x - cell.position.x, 0.0, cell.size.x)
			if captured_width > 0.0:
				var captured := Rect2(cell.position, Vector2(captured_width, cell.size.y))
				_draw_cell(captured, PALETTE.accent.darkened(0.12 + shade * 0.22))
			draw_rect(cell, _alpha(PALETTE.text_secondary, 0.14), false, 1.0)


func _draw_cell(cell: Rect2, color: Color) -> void:
	draw_rect(cell, color)
	# Split faces suggest captured polygons while leaving the frontier's x coordinate exact.
	var points := PackedVector2Array([cell.position, Vector2(cell.end.x, cell.position.y),
		cell.position + cell.size * 0.5, Vector2(cell.position.x, cell.end.y)])
	draw_colored_polygon(points, color.lightened(0.06))


func _draw_checkpoints() -> void:
	var count: int = maxi(_goal, 1)
	var radius: float = checkpoint_radius if count <= grid_columns else 7.0
	for index in count - 1:
		var color: Color = _alpha(PALETTE.accent, 0.7) if index < _current else _alpha(PALETTE.text_secondary, 0.22)
		var start: Vector2 = _checkpoint_center(index)
		var end: Vector2 = _checkpoint_center(index + 1)
		var direction: Vector2 = (end - start).normalized()
		draw_line(start + direction * radius, end - direction * radius, _alpha(PALETTE.panel, 0.85), 14.0, true)
		draw_line(start + direction * radius, end - direction * radius, color, 4.0, true)
	for index in count:
		var center: Vector2 = _checkpoint_center(index)
		match checkpoint_state(index):
			&"captured":
				_draw_diamond(center, radius, PALETTE.accent, PALETTE.accent)
				_draw_check(center, PALETTE.void_bg, radius * 0.4)
			&"next":
				_draw_diamond(center, radius, PALETTE.void_bg, PALETTE.accent)
				draw_line(center + Vector2(-radius, 0), center + Vector2(0, -radius), PALETTE.accent_alt, frontier_width, true)
				if count <= grid_columns:
					_draw_diamond(center, 8.0, PALETTE.accent, PALETTE.accent)
			&"future":
				_draw_diamond(center, radius, PALETTE.void_bg, _alpha(PALETTE.text_secondary, 0.28))


func _checkpoint_center(index: int) -> Vector2:
	var columns: int = mini(maxi(_goal, 1), grid_columns)
	var row: int = floori(float(index) / columns)
	var column: int = index % columns
	if row % 2 == 1:
		column = columns - 1 - column
	var spacing: float = minf(checkpoint_spacing, (size.x - 96.0) / maxi(columns - 1, 1))
	var rows: int = ceili(float(maxi(_goal, 1)) / columns)
	return Vector2((size.x - (columns - 1) * spacing) * 0.5 + column * spacing,
		(size.y - (rows - 1) * grid_row_spacing) * 0.5 + row * grid_row_spacing)


func _draw_diamond(center: Vector2, radius: float, fill: Color, border: Color) -> void:
	var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0)])
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, border, 2.5 if radius > 10.0 else 1.5, true)


func _draw_check(center: Vector2, color: Color, radius: float) -> void:
	draw_polyline(PackedVector2Array([center + Vector2(-radius, 0), center + Vector2(-radius * 0.2, radius * 0.6),
		center + Vector2(radius, -radius * 0.6)]), color, 1.8, true)


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
