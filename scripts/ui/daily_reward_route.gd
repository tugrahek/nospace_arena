class_name DailyRewardRoute
extends Control

## Ten presentation-only checkpoints; no reward mutation or date logic.
signal day_selected(day: int)
const PALETTE: PaletteData = preload("res://config/palette.tres")
const DAYS: int = 10
const COLUMNS: int = 5
const ROWS: int = 2
const CELL_HEIGHT: float = 108.0
const CELL_GAP: float = 8.0
@export var checkpoint_radius: float = 14.0
@export var endpoint_scale: float = 1.4
var current_day: int = 1
var completed_days: int = 0
var selected_day: int = 1
var checkpoints: Array[Button] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, CELL_HEIGHT * ROWS + CELL_GAP)
	for index in DAYS:
		var button := Button.new()
		button.flat = true
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(func() -> void: day_selected.emit(index + 1))
		add_child(button)
		checkpoints.append(button)
		var label := Label.new()
		label.text = str(index + 1)
		label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		label.offset_top = -40.0
		label.offset_bottom = -8.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
	resized.connect(_layout)
	_layout()


## Binds the canonical day and a read-only preview selection.
func bind(day: int, completed: int, selected: int, _rewards: Array[int]) -> void:
	current_day = day
	completed_days = completed
	selected_day = selected
	queue_redraw()


## Canonical center of each checkpoint, also used by the hit targets.
func checkpoint_center(index: int) -> Vector2:
	var row: int = index / COLUMNS
	var row_height: float = (size.y - CELL_GAP) / ROWS
	return Vector2(size.x * (float(index % COLUMNS) + 0.5) / COLUMNS,
		float(row) * (row_height + CELL_GAP) + row_height * 0.35)


func _layout() -> void:
	var row_height: float = (size.y - CELL_GAP) / ROWS
	for index in checkpoints.size():
		var row: int = index / COLUMNS
		checkpoints[index].position = Vector2(size.x * (index % COLUMNS) / COLUMNS + CELL_GAP * 0.5,
			float(row) * (row_height + CELL_GAP))
		checkpoints[index].size = Vector2(size.x / COLUMNS - CELL_GAP, row_height)
	queue_redraw()


func _draw() -> void:
	for row: int in ROWS:
		draw_line(checkpoint_center(row * COLUMNS), checkpoint_center((row + 1) * COLUMNS - 1),
			PALETTE.text_secondary.darkened(0.6), 2.0, true)
	for index in DAYS:
		var day: int = index + 1
		var center: Vector2 = checkpoint_center(index)
		var radius: float = checkpoint_radius * (endpoint_scale if day == DAYS else 1.0)
		var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
		var final_accent: Color = PALETTE.coin.lerp(PALETTE.accent, 0.2)
		var color: Color = final_accent.darkened(0.5) if day == DAYS else PALETTE.text_secondary.darkened(0.45)
		if day <= completed_days:
			var completed_color: Color = PALETTE.accent.lerp(PALETTE.coin, 0.2) if day == DAYS else PALETTE.accent
			draw_colored_polygon(points, completed_color.darkened(0.35))
			color = completed_color
		elif day == current_day:
			draw_colored_polygon(points, PALETTE.coin.darkened(0.15))
			color = final_accent if day == DAYS else PALETTE.coin
		else:
			draw_colored_polygon(points, PALETTE.void_bg)
		points.append(points[0])
		draw_polyline(points, color, 2.0, true)
		if day == selected_day:
			draw_line(center + Vector2(-radius, radius + 10), center + Vector2(radius, radius + 10), PALETTE.coin, 2.0, true)
