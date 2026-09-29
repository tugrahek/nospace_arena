class_name ModeSelectGrid
extends Control

## A quiet shared arena surface for the four ModeSelect hit targets.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var inset: float = 2.0
	var rect := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0)
	var outline := StyleBoxFlat.new()
	outline.draw_center = false
	outline.border_color = _with_alpha(PALETTE.border, 0.58)
	outline.set_border_width_all(2)
	outline.set_corner_radius_all(int(minf(size.x, size.y) * 0.08))
	draw_style_box(outline, rect)

	# Deliberately discontinuous: this suggests four zones without repeating B1's full cross.
	var divider: Color = _with_alpha(PALETTE.border, 0.16)
	var center := size * 0.5
	var gap: float = minf(size.x, size.y) * 0.12
	draw_line(Vector2(center.x, 26.0), Vector2(center.x, center.y - gap), divider, 1.0, true)
	draw_line(Vector2(center.x, center.y + gap), Vector2(center.x, size.y - 26.0), divider, 1.0, true)
	draw_line(Vector2(34.0, center.y), Vector2(center.x - gap, center.y), divider, 1.0, true)
	draw_line(Vector2(center.x + gap, center.y), Vector2(size.x - 34.0, center.y), divider, 1.0, true)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
