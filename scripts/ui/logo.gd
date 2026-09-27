extends Control

## In-engine MainMenu emblem: shows the core mechanic at a glance — a rounded-square arena
## (neon border), captured territory reaching the arena edges, the player diamond INSIDE the
## arena, and the trail behind it carving the frontier of a new region being enclosed.
## Drawn from the palette (no PNG/AI-art). Square / centered / padded -> future app icon.

const PALETTE = preload("res://config/palette.tres")
const CORNER_STEPS: int = 8


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var pad: float = s * 0.08
	var rect := Rect2(pad, pad, s - 2.0 * pad, s - 2.0 * pad)
	var radius: int = int(s * 0.16)
	var bw: float = maxf(s * 0.025, 3.0)

	# Let fills overlap the border's inner edge very slightly, then draw the border last.
	# This removes the dark seam without letting territory escape the outer silhouette.
	var fill_overlap: float = maxf(s * 0.01, 1.5)
	var a: Rect2 = rect.grow(-maxf(bw - fill_overlap, 0.0))
	var ax: float = a.position.x
	var ay: float = a.position.y
	var ab: float = a.position.y + a.size.y
	var ar: float = a.position.x + a.size.x
	var inner_radius: float = maxf(float(radius) - bw + fill_overlap, 0.0)
	# The carve cuts cross at (m, k): cyan owns the lower-left, coral owns the upper-right.
	var m: float = ax + a.size.x * 0.44
	var k: float = ay + a.size.y * 0.42

	# Cyan territory is a complete lower-left capture: its straight right edge shares the
	# vertical frontier x-coordinate, and its outer edge follows the inner rounded corner.
	var cyan := PackedVector2Array([
		Vector2(ax, k), Vector2(m, k), Vector2(m, ab), Vector2(ax + inner_radius, ab)
	])
	_append_arc(cyan, Vector2(ax + inner_radius, ab - inner_radius), inner_radius, PI * 0.5, PI)
	cyan.append(Vector2(ax, k))
	draw_colored_polygon(cyan, _alpha(PALETTE.accent, 0.85))

	# Coral mirrors cyan in the upper-right, following that inner rounded corner with no
	# diagonal guard or floating gap between the territory and arena boundary.
	var coral := PackedVector2Array([Vector2(m, ay), Vector2(ar - inner_radius, ay)])
	_append_arc(coral, Vector2(ar - inner_radius, ay + inner_radius), inner_radius, -PI * 0.5, 0.0)
	coral.append(Vector2(ar, k))
	coral.append(Vector2(m, k))
	draw_colored_polygon(coral, _alpha(PALETTE.warm, 0.85))

	# Trail (magenta): one L-shaped active route from the top boundary through the center to
	# the diamond. Completed cyan territory needs no extra magenta outline.
	var trail_col: Color = PALETTE.accent_alt.lightened(0.42)
	var tw: float = maxf(s * 0.027, 3.0)
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

	# Arena border is last so it cleanly masks the small fill overlap at the rounded edge.
	var border := StyleBoxFlat.new()
	border.draw_center = false
	border.border_color = PALETTE.border
	border.set_border_width_all(int(bw))
	border.set_corner_radius_all(radius)
	draw_style_box(border, rect)


## Same color at a given alpha.
func _alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


## Appends a clockwise or counter-clockwise sampled rounded-boundary arc, including its end.
func _append_arc(points: PackedVector2Array, center: Vector2, radius: float, from_angle: float, to_angle: float) -> void:
	for i in range(1, CORNER_STEPS + 1):
		var t: float = float(i) / float(CORNER_STEPS)
		var angle: float = lerpf(from_angle, to_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
