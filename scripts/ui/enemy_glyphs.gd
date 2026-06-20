extends Control

## Enemy silhouettes for the how-to: Bouncer (circle) + Stalker (triangle), matching the
## in-game shapes. Motoriçi, palette danger color.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var r: float = s * 0.34
	var col: Color = PALETTE.danger
	var lc: Vector2 = Vector2(size.x * 0.3, size.y * 0.5)   # bouncer (circle)
	var rc: Vector2 = Vector2(size.x * 0.7, size.y * 0.5)   # stalker (triangle)
	draw_circle(lc, r, col)
	draw_colored_polygon(
		PackedVector2Array([rc + Vector2(0, -r), rc + Vector2(r, r), rc + Vector2(-r, r)]),
		col
	)
