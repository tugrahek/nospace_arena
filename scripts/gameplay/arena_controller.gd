class_name ArenaController
extends Node2D

@export var arena_rect: Rect2 = Rect2(40.0, 100.0, 640.0, 1100.0)
@export var border_color: Color = Color(0.25, 0.65, 1.0, 1.0)
@export var border_width: float = 3.0
@export var void_color: Color = Color(0.03, 0.02, 0.08, 1.0)


func get_rect() -> Rect2:
	return arena_rect


func _draw() -> void:
	draw_rect(arena_rect, void_color)
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
