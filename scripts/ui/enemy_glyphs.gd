extends Control

## Enemy silhouettes for the how-to: Bouncer (circle) + Stalker (triangle) + Sparx (square),
## matching the in-game shapes. Motoriçi, palette danger color.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var r: float = s * 0.3
	var col: Color = PALETTE.danger
	var cy: float = size.y * 0.5
	var bc: Vector2 = Vector2(size.x * 0.25, cy)  # bouncer (circle)
	var tc: Vector2 = Vector2(size.x * 0.5, cy)   # stalker (triangle)
	var sc: Vector2 = Vector2(size.x * 0.75, cy)  # sparx (square)
	draw_circle(bc, r, col)
	draw_colored_polygon(
		PackedVector2Array([tc + Vector2(0, -r), tc + Vector2(r, r), tc + Vector2(-r, r)]),
		col
	)
	draw_rect(Rect2(sc.x - r, sc.y - r, r * 2.0, r * 2.0), col)
