extends Control

## Draws the small frontier mark beneath the credits wordmark.

const PALETTE: PaletteData = preload("res://config/palette.tres")

@export var line_length: float = 54.0
@export var diamond_radius: float = 5.0
@export var line_width: float = 1.5
@export var line_gap_multiplier: float = 1.8


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var cyan: Color = PALETTE.accent
	var magenta: Color = PALETTE.accent_alt
	var line_gap: float = diamond_radius * line_gap_multiplier
	draw_line(center - Vector2(line_length, 0.0), center - Vector2(line_gap, 0.0), cyan, line_width)
	draw_line(center + Vector2(line_gap, 0.0), center + Vector2(line_length, 0.0), magenta, line_width)
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -diamond_radius),
		center + Vector2(diamond_radius, 0.0),
		center + Vector2(0.0, diamond_radius),
		center + Vector2(-diamond_radius, 0.0),
	])
	draw_colored_polygon(points, cyan)
