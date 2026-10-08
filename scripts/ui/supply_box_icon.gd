class_name SupplyBoxIcon
extends Control

## Small procedural supply prism and optional angular popup frame, using the shared palette.
const PALETTE: PaletteData = preload("res://config/palette.tres")
@export var frame: bool = false
@export var line_width: float = 2.0
@export var cut_size: float = 18.0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	if frame:
		var c: float = minf(cut_size, minf(size.x, size.y) * 0.1)
		var p := PackedVector2Array([Vector2(c, 0), Vector2(size.x - c, 0),
			Vector2(size.x, c), Vector2(size.x, size.y - c), Vector2(size.x - c, size.y),
			Vector2(c, size.y), Vector2(0, size.y - c), Vector2(0, c)])
		draw_colored_polygon(p, PALETTE.void_bg)
		p.append(p[0])
		draw_polyline(p, PALETTE.border, line_width, true)
		return
	var center: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.35
	var top: Vector2 = center + Vector2(0, -r)
	var left: Vector2 = center + Vector2(-r, -r * 0.4)
	var right: Vector2 = center + Vector2(r, -r * 0.4)
	var bottom: Vector2 = center + Vector2(0, r)
	draw_polyline(PackedVector2Array([top, right, right + Vector2(0, r), bottom,
		left + Vector2(0, r), left, top]), PALETTE.accent, line_width, true)
	draw_polyline(PackedVector2Array([left, center, right]), PALETTE.accent, line_width, true)
	draw_line(center, bottom, PALETTE.accent_alt, line_width, true)
