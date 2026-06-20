extends Control

## Motoriçi "X" close glyph. mouse_filter IGNORE so the parent Button gets the tap.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var r: float = s * 0.22
	var w: float = maxf(s * 0.1, 3.0)
	var col: Color = PALETTE.text_secondary
	draw_line(c + Vector2(-r, -r), c + Vector2(r, r), col, w)
	draw_line(c + Vector2(-r, r), c + Vector2(r, -r), col, w)
