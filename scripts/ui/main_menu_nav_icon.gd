class_name MainMenuNavIcon
extends Control

## Procedural destination icons for the shared MainMenu navigation arena.

enum IconKind { STORE, MISSIONS, LEADERBOARD, CREDITS }

const PALETTE = preload("res://config/palette.tres")

@export var icon_kind: IconKind = IconKind.STORE


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	match icon_kind:
		IconKind.STORE:
			_draw_store()
		IconKind.MISSIONS:
			_draw_missions()
		IconKind.LEADERBOARD:
			_draw_leaderboard()
		IconKind.CREDITS:
			_draw_credits()


func _draw_store() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.28
	draw_circle(center, radius, PALETTE.coin)
	draw_arc(center, radius * 0.62, 0.0, TAU, 20, _with_alpha(PALETTE.void_bg, 0.7), maxf(radius * 0.16, 2.0), true)
	draw_line(center + Vector2(-radius * 0.3, 0.0), center + Vector2(radius * 0.3, 0.0), PALETTE.void_bg, maxf(radius * 0.14, 2.0), true)


func _draw_missions() -> void:
	var center := size * 0.5
	var unit: float = minf(size.x, size.y) * 0.28
	var line: PackedVector2Array = PackedVector2Array([
		center + Vector2(-unit, -unit), center + Vector2(-unit, unit * 0.45), center + Vector2(unit, unit * 0.45)
	])
	draw_polyline(line, PALETTE.accent_alt, maxf(unit * 0.25, 3.0), true)
	var tip := center + Vector2(unit, unit * 0.45)
	draw_colored_polygon(PackedVector2Array([
		tip + Vector2(0.0, -unit * 0.34), tip + Vector2(unit * 0.34, 0.0),
		tip + Vector2(0.0, unit * 0.34), tip + Vector2(-unit * 0.34, 0.0)
	]), PALETTE.accent.lightened(0.35))


func _draw_leaderboard() -> void:
	var center := size * 0.5
	var unit: float = minf(size.x, size.y) * 0.24
	var bar_width: float = unit * 0.42
	var gap: float = unit * 0.18
	var heights := PackedFloat32Array([unit * 0.8, unit * 1.45, unit * 1.1])
	for index in heights.size():
		var x: float = center.x + (float(index) - 1.0) * (bar_width + gap)
		var bar := Rect2(x - bar_width * 0.5, center.y + unit * 0.65 - heights[index], bar_width, heights[index])
		draw_rect(bar, _with_alpha(PALETTE.accent, 0.85), true)
	var diamond_center := Vector2(center.x, center.y - unit * 0.98)
	draw_colored_polygon(PackedVector2Array([
		diamond_center + Vector2(0.0, -unit * 0.28), diamond_center + Vector2(unit * 0.28, 0.0),
		diamond_center + Vector2(0.0, unit * 0.28), diamond_center + Vector2(-unit * 0.28, 0.0)
	]), PALETTE.accent.lightened(0.5))


func _draw_credits() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.27
	var muted: Color = _with_alpha(PALETTE.text_secondary, 0.9)
	draw_arc(center, radius, 0.0, TAU, 20, muted, maxf(radius * 0.12, 2.0), true)
	draw_circle(center + Vector2(0.0, -radius * 0.35), radius * 0.12, PALETTE.accent)
	draw_line(center + Vector2(0.0, -radius * 0.05), center + Vector2(0.0, radius * 0.45), PALETTE.accent, maxf(radius * 0.14, 2.0), true)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
