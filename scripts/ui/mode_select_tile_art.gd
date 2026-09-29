class_name ModeSelectTileArt
extends Control

## Presentation-only motifs that distinguish each existing game mode.

enum TileKind { DAILY, FREE, ENDLESS, CAMPAIGN }

const PALETTE = preload("res://config/palette.tres")

@export var tile_kind: TileKind = TileKind.DAILY


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	match tile_kind:
		TileKind.DAILY:
			_draw_daily()
		TileKind.FREE:
			_draw_free()
		TileKind.ENDLESS:
			_draw_endless()
		TileKind.CAMPAIGN:
			_draw_campaign()


func _draw_daily() -> void:
	var route := PackedVector2Array([
		Vector2(size.x * 0.24, size.y * 0.22), Vector2(size.x * 0.24, size.y * 0.7),
		Vector2(size.x * 0.68, size.y * 0.7)
	])
	draw_polyline(route, PALETTE.accent_alt, 3.0, true)
	_draw_diamond(route[2], PALETTE.accent.lightened(0.35), 7.0)


func _draw_free() -> void:
	var bounds := Rect2(size.x * 0.22, size.y * 0.2, size.x * 0.52, size.y * 0.52)
	draw_rect(bounds, _with_alpha(PALETTE.border, 0.45), false, 2.0, true)
	var captured := PackedVector2Array([
		bounds.position + Vector2(0.0, bounds.size.y), bounds.position + Vector2(0.0, bounds.size.y * 0.44),
		bounds.position + Vector2(bounds.size.x * 0.55, bounds.size.y * 0.44),
		bounds.position + Vector2(bounds.size.x * 0.55, bounds.size.y)
	])
	draw_colored_polygon(captured, _with_alpha(PALETTE.accent, 0.6))
	draw_line(captured[1], captured[2], PALETTE.accent, 2.0, true)


func _draw_endless() -> void:
	var origin := Vector2(size.x * 0.25, size.y * 0.72)
	var step := Vector2(size.x * 0.14, size.y * 0.14)
	for index in 3:
		var start := origin + Vector2(step.x * float(index), -step.y * float(index))
		var end := start + Vector2(step.x * 0.66, -step.y * 0.66)
		var color := PALETTE.warm if index == 2 else PALETTE.accent_alt
		draw_line(start, end, color, 3.0, true)
		draw_circle(end, 3.5, color)


func _draw_campaign() -> void:
	var points := PackedVector2Array([
		Vector2(size.x * 0.22, size.y * 0.62), Vector2(size.x * 0.43, size.y * 0.38),
		Vector2(size.x * 0.64, size.y * 0.58), Vector2(size.x * 0.78, size.y * 0.3)
	])
	draw_polyline(points, _with_alpha(PALETTE.accent, 0.74), 2.0, true)
	for point in points:
		_draw_diamond(point, PALETTE.accent, 5.0)


func _draw_diamond(center: Vector2, color: Color, radius: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius, 0.0)
	]), color)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
