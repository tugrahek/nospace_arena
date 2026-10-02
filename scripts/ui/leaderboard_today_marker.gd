class_name LeaderboardTodayMarker
extends Control

## A small player-diamond marks only a saved score whose date is actually today.

const MARKER_COLOR: Color = Color(0.3, 0.95, 1.0, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(20.0, 20.0)
	resized.connect(queue_redraw)


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.28
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius, 0.0), center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0), center + Vector2(0.0, radius),
	]), MARKER_COLOR)
