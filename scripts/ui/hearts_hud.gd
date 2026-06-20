class_name HeartsHud
extends Control

## In-engine lives display: N hearts drawn from the palette (2 circles + a triangle, no asset).
## A lost heart fades to a dim empty slot (so remaining lives stay readable) with a quick
## scale punch. Used in all modes. @export for feel.

const PALETTE = preload("res://config/palette.tres")

@export var heart_size: float = 26.0   # height of one heart
@export var spacing: float = 16.0      # gap between hearts
@export var fade_time: float = 0.35    # lost-heart fade duration
@export var empty_alpha: float = 0.18  # alpha of an emptied slot
@export var full_color: Color = Color(1.0, 0.42, 0.46, 1.0)  # palette danger (soft red)

var _max: int = 3
var _current: int = 3
var _alpha: Array[float] = []   # per-heart current alpha (animated)
var _scale: Array[float] = []   # per-heart current scale (punch)


func _ready() -> void:
	if _alpha.is_empty():
		set_max(_max)  # populate before the first _draw (setup() refreshes later)


func set_max(n: int) -> void:
	_max = maxi(n, 0)
	_current = _max
	_alpha = []
	_scale = []
	for i in _max:
		_alpha.append(1.0)
		_scale.append(1.0)
	custom_minimum_size = Vector2(_max * (heart_size + spacing), heart_size)
	queue_redraw()


## Sets remaining lives. Emptied hearts fade out (with a punch); regained hearts refill instantly.
func set_current(n: int) -> void:
	n = clampi(n, 0, _max)
	if n < _current:
		for i in range(n, _current):
			_fade_heart(i)
	elif n > _current:
		for i in _alpha.size():
			_alpha[i] = 1.0 if i < n else empty_alpha
			_scale[i] = 1.0
		queue_redraw()
	_current = n


func _fade_heart(i: int) -> void:
	if i < 0 or i >= _alpha.size():
		return
	var t: Tween = create_tween().set_parallel(true)
	t.tween_method(func(a: float) -> void: _alpha[i] = a; queue_redraw(), 1.0, empty_alpha, fade_time)
	# quick punch then settle
	_scale[i] = 1.4
	t.tween_method(func(s: float) -> void: _scale[i] = s; queue_redraw(), 1.4, 1.0, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	for i in mini(_max, _alpha.size()):  # guard: arrays sized by set_max
		var cx: float = i * (heart_size + spacing) + (heart_size + spacing) * 0.5
		var cy: float = size.y * 0.5
		_draw_heart(Vector2(cx, cy), (heart_size / 22.0) * _scale[i], Color(full_color.r, full_color.g, full_color.b, _alpha[i]))


## One smooth heart as a SINGLE filled polygon (parametric curve) — no overlapping shapes, so a
## dimmed heart has uniform alpha (no seam/centre line). `scale`: pixels per curve unit.
func _draw_heart(c: Vector2, scale: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 32
	for i in steps:
		var t: float = TAU * float(i) / float(steps)
		var s: float = sin(t)
		var x: float = 16.0 * s * s * s
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(c + Vector2(x * scale, -(y + 6.0) * scale))  # +6 centres it; flip y for screen
	draw_colored_polygon(pts, col)
