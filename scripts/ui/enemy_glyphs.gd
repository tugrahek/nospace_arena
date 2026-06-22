extends Control

## One enemy silhouette for the how-to legend, by `kind` (0 circle=Bouncer, 1 triangle=Stalker,
## 2 square=Sparx) — matching the in-game shapes. Motoriçi, palette danger color.

const PALETTE = preload("res://config/palette.tres")

@export var kind: int = 0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var r: float = s * 0.4
	var col: Color = PALETTE.danger
	match kind:
		1:
			draw_colored_polygon(
				PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r), c + Vector2(-r, r)]), col)
		2:
			draw_rect(Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), col)
		_:
			draw_circle(c, r, col)
