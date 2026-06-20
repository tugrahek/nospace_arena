extends Control

## Mini control-scheme glyph (swipe arrow / tap ring+dot / d-pad cross). Motoriçi, paletten.

const PALETTE = preload("res://config/palette.tres")

@export var kind: int = 0  # 0 swipe, 1 tap, 2 dpad


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var w: float = maxf(s * 0.08, 2.0)
	var col: Color = PALETTE.accent
	match kind:
		0:  # swipe: a right arrow
			var a: Vector2 = c + Vector2(-s * 0.3, 0)
			var b: Vector2 = c + Vector2(s * 0.3, 0)
			draw_line(a, b, col, w)
			draw_line(b, b + Vector2(-s * 0.14, -s * 0.14), col, w)
			draw_line(b, b + Vector2(-s * 0.14, s * 0.14), col, w)
		1:  # tap: a dot inside a ring
			draw_arc(c, s * 0.28, 0.0, TAU, 28, Color(col.r, col.g, col.b, 0.5), w)
			draw_circle(c, s * 0.12, col)
		2:  # d-pad: a plus
			draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.3), col, w)
			draw_line(c + Vector2(-s * 0.3, 0), c + Vector2(s * 0.3, 0), col, w)
