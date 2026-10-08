class_name SupplyVideoIcon
extends Control

## Small geometric video/play action glyph; all colors come from the shared palette.
const PALETTE: PaletteData = preload("res://config/palette.tres")
@export var line_width: float = 2.0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(size * 0.12, size * 0.76)
	draw_rect(rect, PALETTE.accent, false, line_width, true)
	draw_colored_polygon(PackedVector2Array([size * Vector2(0.4, 0.3),
		size * Vector2(0.4, 0.7), size * Vector2(0.7, 0.5)]), PALETTE.accent)
