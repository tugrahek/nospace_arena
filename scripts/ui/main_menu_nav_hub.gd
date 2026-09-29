class_name MainMenuNavHub
extends Control

## Shared arena-like surface behind the four MainMenu destination hit targets.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var inset: float = 2.0
	var rect := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0)
	var radius: int = int(minf(size.x, size.y) * 0.11)
	var border_width: int = 2
	var outline := StyleBoxFlat.new()
	outline.draw_center = false
	outline.border_color = _with_alpha(PALETTE.border, 0.68)
	outline.set_border_width_all(border_width)
	outline.set_corner_radius_all(radius)
	draw_style_box(outline, rect)

	# Dividers stay deliberately quieter than the shared arena boundary and destination icons.
	var divider: Color = _with_alpha(PALETTE.border, 0.18)
	var margin: float = minf(size.x, size.y) * 0.15
	var center := size * 0.5
	draw_line(Vector2(center.x, margin), Vector2(center.x, size.y - margin), divider, 1.0, true)
	draw_line(Vector2(margin, center.y), Vector2(size.x - margin, center.y), divider, 1.0, true)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
