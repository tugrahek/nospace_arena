class_name DailyRewardRoute
extends Control

## Seven presentation-only checkpoints; no reward mutation or date logic.
signal day_selected(day: int)
const PALETTE: PaletteData = preload("res://config/palette.tres")
const DAYS: int = 7
@export var checkpoint_radius: float = 11.0
@export var endpoint_scale: float = 1.25
var current_day: int = 1
var completed_days: int = 0
var selected_day: int = 1
var checkpoints: Array[Button] = []


func _ready() -> void:
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
	return Vector2(size.x * (float(index) + 0.5) / DAYS, size.y * 0.45)


func _layout() -> void:
	for index in checkpoints.size():
		checkpoints[index].position = Vector2(size.x * index / DAYS, 0.0)
		checkpoints[index].size = Vector2(size.x / DAYS, size.y)
	queue_redraw()


func _draw() -> void:
	draw_line(checkpoint_center(0), checkpoint_center(DAYS - 1), PALETTE.text_secondary.darkened(0.6), 2.0, true)
	for index in DAYS:
		var day: int = index + 1
		var center: Vector2 = checkpoint_center(index)
		var radius: float = checkpoint_radius * (endpoint_scale if day == DAYS else 1.0)
		var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
		var color: Color = PALETTE.coin.darkened(0.5) if day == DAYS else PALETTE.text_secondary.darkened(0.45)
		if day <= completed_days:
			draw_colored_polygon(points, PALETTE.accent.darkened(0.35))
			color = PALETTE.accent
		elif day == current_day:
			draw_colored_polygon(points, PALETTE.coin.darkened(0.15))
			color = PALETTE.coin
		else:
			draw_colored_polygon(points, PALETTE.void_bg)
		points.append(points[0])
		draw_polyline(points, color, 2.0, true)
		if day == selected_day:
			draw_line(center + Vector2(-radius, radius + 10), center + Vector2(radius, radius + 10), PALETTE.coin, 2.0, true)
