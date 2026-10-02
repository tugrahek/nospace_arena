class_name HowToPageProgress
extends Control

## Four visible trail stops and a player diamond at the current tutorial page.

const PALETTE = preload("res://config/palette.tres")

@export_range(0, 3) var page_index: int = 0:
	set(value):
		page_index = clampi(value, 0, STEP_COUNT - 1)
		queue_redraw()

const STEP_COUNT: int = 4
const LINE_WIDTH: float = 3.0
const NODE_RADIUS: float = 5.0


func _ready() -> void:
	resized.connect(queue_redraw)


## Exposes the actual four positions used by drawing for structural tests.
func get_step_positions() -> PackedVector2Array:
	var span: float = maxf(0.0, minf(size.x - 24.0, 236.0))
	var start_x: float = (size.x - span) * 0.5
	var step: float = span / float(STEP_COUNT - 1)
	var points := PackedVector2Array()
	for index in STEP_COUNT:
		points.append(Vector2(start_x + step * index, size.y * 0.5))
	return points


func _draw() -> void:
	var points: PackedVector2Array = get_step_positions()
	for index in STEP_COUNT - 1:
		var color: Color = PALETTE.accent if index < page_index else Color(PALETTE.border, 0.55)
		draw_line(points[index], points[index + 1], color, LINE_WIDTH, true)
	for index in STEP_COUNT:
		if index == page_index:
			_draw_diamond(points[index])
		else:
			var color: Color = PALETTE.accent if index < page_index else Color(PALETTE.border, 0.9)
			draw_circle(points[index], NODE_RADIUS, color)


func _draw_diamond(center: Vector2) -> void:
	var radius: float = 10.0
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	]), PALETTE.text_primary)
