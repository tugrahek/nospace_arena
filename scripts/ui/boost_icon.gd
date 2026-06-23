extends Control

## Distinct procedural icon per boost effect so the three boosts read apart at a glance:
## Extra Life -> heart (red), Coin Bonus -> coin (gold), Slow Start -> clock (blue). Data-driven
## by BoostData.Effect; no image assets.

@export var effect: int = 0  # BoostData.Effect (0 EXTRA_LIFE, 1 SLOW_START, 2 COIN_BONUS)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var r: float = s * 0.42
	match effect:
		BoostData.Effect.SLOW_START:
			_draw_clock(c, r)
		BoostData.Effect.COIN_BONUS:
			_draw_coin(c, r)
		_:
			_draw_heart(c, r)


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


func _draw_clock(c: Vector2, r: float) -> void:
	var blue := Color(0.45, 0.8, 1.0)
	draw_arc(c, r, 0.0, TAU, 32, blue, maxf(2.0, r * 0.12), true)
	draw_line(c, c + Vector2(0.0, -r * 0.62), blue, maxf(2.0, r * 0.1))
	draw_line(c, c + Vector2(r * 0.46, r * 0.05), blue, maxf(2.0, r * 0.1))
	draw_circle(c, maxf(1.5, r * 0.1), blue)
