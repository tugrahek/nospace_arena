extends Control

## In-engine MainMenu emblem: shows the core mechanic at a glance — a rounded-square arena
## (neon border), captured territory reaching the arena edges, the player diamond INSIDE the
## arena, and the trail behind it carving the frontier of a new region being enclosed.
## Drawn from the palette (no PNG/AI-art). Square / centered / padded -> future app icon.

const PALETTE = preload("res://config/palette.tres")
const CORNER_STEPS: int = 8

@export var trail_reveal_duration: float = 1.20
@export var diamond_settle_duration: float = 0.18
@export var diamond_settle_scale: float = 1.07

var _trail_progress: float = 0.0:
	set(value):
		_trail_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var _diamond_scale: float = 1.0:
	set(value):
		_diamond_scale = value
		queue_redraw()
var _glow_strength: float = 0.0:
	set(value):
		_glow_strength = clampf(value, 0.0, 1.0)
		queue_redraw()
var _intro_started: bool = false
var _intro_finished: bool = false


func _ready() -> void:
	resized.connect(queue_redraw)


## Runs once per Logo instance; scene recreation deliberately gets a fresh intro.
func play_intro() -> void:
	if _intro_started:
		return
	_intro_started = true
	_trail_progress = 0.0
	_diamond_scale = 1.0
	_glow_strength = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_trail_progress", 1.0, trail_reveal_duration)
	tween.parallel().tween_property(self, "_glow_strength", 0.45, trail_reveal_duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_diamond_scale", diamond_settle_scale, diamond_settle_duration * 0.5)
	tween.parallel().tween_property(self, "_glow_strength", 0.75, diamond_settle_duration * 0.5)
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "_diamond_scale", 1.0, diamond_settle_duration * 0.5)
	tween.parallel().tween_property(self, "_glow_strength", 0.0, diamond_settle_duration * 0.5)
	tween.tween_callback(_finish_intro)


func trail_progress() -> float:
	return _trail_progress


func intro_finished() -> bool:
	return _intro_finished


func intro_started() -> bool:
	return _intro_started


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
	var trail_start := Vector2(m, ay)
	var trail_corner := Vector2(m, k)
	var head := Vector2(ar - a.size.x * 0.13, k)
	var animated_head := _draw_revealed_trail(trail_start, trail_corner, head, trail_col, tw)
	if not _intro_finished:
		_draw_trail_energy(trail_start, trail_corner, head, animated_head, trail_col, tw, s)

	# Player diamond — bright near-white core, clearly NOT the trail.
	var d: float = s * 0.07 * _diamond_scale
	var player_col: Color = PALETTE.accent.lightened(0.6)
	draw_colored_polygon(
		PackedVector2Array([
			animated_head + Vector2(0, -d), animated_head + Vector2(d, 0), animated_head + Vector2(0, d), animated_head + Vector2(-d, 0)
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


## Restores the accepted clean static state even if a tween is interrupted at its endpoint.
func _finish_intro() -> void:
	_diamond_scale = 1.0
	_glow_strength = 0.0
	_intro_finished = true
	queue_redraw()


## A short magenta afterimage energizes only the actively drawn trail, never the player diamond.
func _draw_trail_energy(start: Vector2, corner: Vector2, end: Vector2, tip: Vector2,
		trail_color: Color, width: float, scale: float) -> void:
	if _glow_strength <= 0.0:
		return
	var tangent := (corner - start).normalized() if _trail_progress <= _corner_progress(start, corner, end) else (end - corner).normalized()
	var tail := tip - tangent * minf(scale * 0.12, tip.distance_to(start))
	var soft_magenta := Color(trail_color.r, trail_color.g, trail_color.b, 0.24 * _glow_strength)
	var bright_magenta := Color(trail_color.r, trail_color.g, trail_color.b, 0.62 * _glow_strength)
	draw_line(tail, tip, soft_magenta, width * 2.2, true)
	draw_line(tail, tip, bright_magenta, width * 1.15, true)


func _corner_progress(start: Vector2, corner: Vector2, end: Vector2) -> float:
	var first_length := start.distance_to(corner)
	return first_length / maxf(first_length + corner.distance_to(end), 1.0)


## Draws a contiguous prefix of the locked L route and returns its active visual tip.
func _draw_revealed_trail(start: Vector2, corner: Vector2, end: Vector2, color: Color, width: float) -> Vector2:
	if _trail_progress >= 1.0:
		draw_polyline(PackedVector2Array([start, corner, end]), color, width, true)
		return end
	var first_length := start.distance_to(corner)
	var second_length := corner.distance_to(end)
	var reveal_length := (first_length + second_length) * _trail_progress
	if reveal_length <= first_length:
		var tip := path_tip(start, corner, end, _trail_progress)
		draw_line(start, tip, color, width, true)
		return tip
	var tip := path_tip(start, corner, end, _trail_progress)
	draw_line(start, corner, color, width, true)
	draw_line(corner, tip, color, width, true)
	return tip


## Returns the exact path-length-normalized tip, including the continuous corner transition.
func path_tip(start: Vector2, corner: Vector2, end: Vector2, progress: float) -> Vector2:
	var first_length := start.distance_to(corner)
	var second_length := corner.distance_to(end)
	var reveal_length := (first_length + second_length) * clampf(progress, 0.0, 1.0)
	if reveal_length <= first_length:
		return start.lerp(corner, reveal_length / maxf(first_length, 1.0))
	return corner.lerp(end, (reveal_length - first_length) / maxf(second_length, 1.0))


## Appends a clockwise or counter-clockwise sampled rounded-boundary arc, including its end.
func _append_arc(points: PackedVector2Array, center: Vector2, radius: float, from_angle: float, to_angle: float) -> void:
	for i in range(1, CORNER_STEPS + 1):
		var t: float = float(i) / float(CORNER_STEPS)
		var angle: float = lerpf(from_angle, to_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
