extends Control

## Distinct procedural icon per boost effect; no image assets.

const COIN_BONUS_ICON: int = 3
@export var effect: int = 0  # BoostData.Effect or COIN_BONUS_ICON.
var optical_offset_y: float = 0.0
var visual_scale: float = 1.0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_set_transform(Vector2(size * 0.5 + Vector2(0.0, optical_offset_y)), 0.0, Vector2.ONE * visual_scale)
	var s: float = minf(size.x, size.y)
	var c: Vector2 = Vector2.ZERO
	var r: float = s * 0.42
	match effect:
		BoostData.Effect.SLOW_START:
			_draw_clock(c, r)
		COIN_BONUS_ICON:
			_draw_coin_bonus(c, r)
		BoostData.Effect.COIN_BONUS:
			_draw_coin(c, r)
		_:
			_draw_heart(c, r)
	draw_set_transform(Vector2.ZERO)


func _draw_heart(c: Vector2, r: float) -> void:
	var col := Color(1.0, 0.42, 0.46)
	var pts := PackedVector2Array()
	var n: int = 28
	for i in n:
		var t: float = TAU * float(i) / float(n)
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(c + Vector2(x, -y) * (r / 16.0))
	draw_colored_polygon(pts, col)


func _draw_coin(c: Vector2, r: float) -> void:
	var gold := Color(1.0, 0.82, 0.28)
	var dark := Color(0.72, 0.52, 0.12)
	draw_circle(c, r, gold)
	draw_arc(c, r * 0.94, 0.0, TAU, 32, dark, maxf(2.0, r * 0.12), true)
	draw_arc(c, r * 0.5, 0.0, TAU, 24, dark, maxf(1.5, r * 0.08), true)


func _draw_coin_bonus(c: Vector2, r: float) -> void:
	_draw_coin(c, r * 0.78)
	var accent := Color(0.35, 0.98, 0.88)
	var badge := c + Vector2(r * 0.62, -r * 0.62)
	var badge_radius: float = maxf(4.0, r * 0.38)
	draw_circle(badge, badge_radius, Color(0.035, 0.055, 0.13))
	draw_arc(badge, badge_radius, 0.0, TAU, 20, accent, maxf(1.5, r * 0.1), true)
	draw_line(badge - Vector2(badge_radius * 0.48, 0.0), badge + Vector2(badge_radius * 0.48, 0.0), accent, maxf(1.5, r * 0.1), true)
	draw_line(badge - Vector2(0.0, badge_radius * 0.48), badge + Vector2(0.0, badge_radius * 0.48), accent, maxf(1.5, r * 0.1), true)


func _draw_clock(c: Vector2, r: float) -> void:
	var blue := Color(0.45, 0.8, 1.0)
	draw_arc(c, r, 0.0, TAU, 32, blue, maxf(2.0, r * 0.12), true)
	draw_line(c, c + Vector2(0.0, -r * 0.62), blue, maxf(2.0, r * 0.1))
	draw_line(c, c + Vector2(r * 0.46, r * 0.05), blue, maxf(2.0, r * 0.1))
	draw_circle(c, maxf(1.5, r * 0.1), blue)
