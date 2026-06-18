extends Control

## In-engine MainMenu emblem: shows the core mechanic at a glance — a rounded-square arena
## (neon border), a captured/won region filled with bright accent, the player diamond INSIDE
## the arena, and the trail behind it carving the frontier of a new region being enclosed.
## Drawn from the palette (no PNG/AI-art). Square / centered / padded -> future app icon.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var pad: float = s * 0.08
	var rect := Rect2(pad, pad, s - 2.0 * pad, s - 2.0 * pad)
	var radius: int = int(s * 0.16)
	var bw: float = maxf(s * 0.025, 3.0)

	# Playfield: the area inside the neon border.
	var a: Rect2 = rect.grow(-bw - s * 0.02)
	var ax: float = a.position.x
	var ay: float = a.position.y
	var ab: float = a.position.y + a.size.y
	var ar: float = a.position.x + a.size.x
	# The carve cuts cross at (m, k): cyan won the lower-left, coral the upper-right.
	var m: float = ax + a.size.x * 0.44
	var k: float = ay + a.size.y * 0.42

	# Won #1 (cyan): lower-left, fully enclosed by left/bottom walls + the trail cuts.
	draw_colored_polygon(
		PackedVector2Array([Vector2(ax, k), Vector2(m, k), Vector2(m, ab), Vector2(ax, ab)]),
		_alpha(PALETTE.accent, 0.85)
	)
	# Won #2 (coral): upper-right, enclosed by top/right walls + the trail cuts (being closed).
	draw_colored_polygon(
		PackedVector2Array([Vector2(m, ay), Vector2(ar, ay), Vector2(ar, k), Vector2(m, k)]),
		_alpha(PALETTE.warm, 0.85)
	)

	# Arena border (rounded-square neon outline) on top of the fills.
	var border := StyleBoxFlat.new()
	border.draw_center = false
	border.border_color = PALETTE.border
	border.set_border_width_all(int(bw))
	border.set_corner_radius_all(radius)
	draw_style_box(border, rect)

	# Trail (magenta): the player's path. It bounds the cyan region (left wall -> corner ->
	# bottom wall) and the coral region (top wall -> corner -> toward the right wall), so no
	# filled region floats free. The player diamond rides its live tip, inside the arena.
	var trail_col: Color = PALETTE.accent_alt.lightened(0.2)
	var tw: float = maxf(s * 0.022, 2.5)
	draw_polyline(PackedVector2Array([Vector2(ax, k), Vector2(m, k), Vector2(m, ab)]), trail_col, tw, true)
	var head := Vector2(ar - a.size.x * 0.13, k)
	draw_polyline(PackedVector2Array([Vector2(m, ay), Vector2(m, k), head]), trail_col, tw, true)

	# Player diamond — bright near-white core, clearly NOT the trail.
	var d: float = s * 0.07
	var player_col: Color = PALETTE.accent.lightened(0.6)
	draw_colored_polygon(
		PackedVector2Array([
			head + Vector2(0, -d), head + Vector2(d, 0), head + Vector2(0, d), head + Vector2(-d, 0)
		]),
		player_col
	)


## Same color at a given alpha.
func _alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)
