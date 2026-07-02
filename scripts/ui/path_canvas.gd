extends Control

## Draws the winding connector line between campaign level nodes. level_select.gd positions the
## node buttons on this canvas and feeds the ordered node centers via set_points().

const PALETTE = preload("res://config/palette.tres")

var _points: PackedVector2Array = PackedVector2Array()


func set_points(points: PackedVector2Array) -> void:
	_points = points
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return
	var col: Color = PALETTE.accent
	col.a = 0.4
	for i in range(_points.size() - 1):
		draw_line(_points[i], _points[i + 1], col, 5.0, true)
