extends Control

## Small character-effect symbol for the Store: push (out arrows) / slow (clock) / freeze
## (snowflake). Motoriçi, paletten. Set `kind` (0 push, 1 slow, 2 freeze).

const PALETTE = preload("res://config/palette.tres")

@export var kind: int = 0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var w: float = maxf(s * 0.09, 2.0)
	var col: Color = PALETTE.accent
	match kind:
		0:  # push: two arrows pointing outward
			_arrow(c, Vector2(1, 0), s, w, col)
			_arrow(c, Vector2(-1, 0), s, w, col)
		1:  # slow: a clock (ring + two hands)
			draw_arc(c, s * 0.3, 0.0, TAU, 28, col, w)
			draw_line(c, c + Vector2(0, -s * 0.2), col, w)
			draw_line(c, c + Vector2(s * 0.13, 0), col, w)
		2:  # freeze: a snowflake (three crossing spokes)
			for deg in [0.0, 60.0, 120.0]:
				var d: Vector2 = Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * s * 0.3
				draw_line(c - d, c + d, col, w)


func _arrow(c: Vector2, dir: Vector2, s: float, w: float, col: Color) -> void:
	var tip: Vector2 = c + dir * s * 0.32
	draw_line(c, tip, col, w)
	var back: Vector2 = dir * s * 0.12
	var perp: Vector2 = Vector2(-dir.y, dir.x) * s * 0.1
	draw_line(tip, tip - back + perp, col, w)
	draw_line(tip, tip - back - perp, col, w)
