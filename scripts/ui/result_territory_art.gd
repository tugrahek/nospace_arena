class_name ResultTerritoryArt
extends Control

## Presentation-only result motif. Actual capture and target have independent positions.

const PALETTE: PaletteData = preload("res://config/palette.tres")

@export var outer_margin: float = 4.0
@export var corner_radius: float = 10.0
@export var border_width: float = 2.0
@export var diamond_radius: float = 6.0

var completion_percent: float = 0.0
var target_percent: float = 0.0
var won: bool = false


## Updates the visual from real HUD capture progress and target without changing result logic.
func set_result(percent: float, target: float, did_win: bool) -> void:
	completion_percent = clampf(percent, 0.0, 100.0)
	target_percent = clampf(target, 0.0, 100.0)
	won = did_win
	queue_redraw()


func _draw() -> void:
	if size.x <= (outer_margin + border_width) * 2.0 or size.y <= (outer_margin + border_width) * 2.0:
		return
	var outer: Rect2 = Rect2(Vector2.ONE * outer_margin, size - Vector2.ONE * outer_margin * 2.0)
	_draw_box(outer, PALETTE.void_bg, PALETTE.border, border_width, corner_radius)
	var geometry: Dictionary = progress_geometry()
	var fill: Rect2 = geometry["fill"]
	if fill.size.x > 0.0:
		draw_rect(fill, Color(PALETTE.accent, 0.55), true)
	var bar: Rect2 = geometry["bar"]
	var target_x: float = geometry["target_x"]
	draw_line(Vector2(target_x, bar.position.y), Vector2(target_x, bar.end.y),
		PALETTE.accent_alt, border_width, true)
	_draw_diamond(geometry["diamond"])


## Supplies the exact axis-aligned geometry used for rendering and regression checks.
func progress_geometry() -> Dictionary:
	var inset: float = outer_margin + border_width
	var bar: Rect2 = Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0)
	var actual_x: float = bar.position.x + bar.size.x * completion_percent / 100.0
	var target_x: float = bar.position.x + bar.size.x * target_percent / 100.0
	return {
		"bar": bar,
		"fill": Rect2(bar.position, Vector2(actual_x - bar.position.x, bar.size.y)),
		"target_x": target_x,
		"diamond": Vector2(actual_x, bar.position.y),
	}


func _draw_diamond(center: Vector2) -> void:
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -diamond_radius),
		center + Vector2(diamond_radius, 0.0),
		center + Vector2(0.0, diamond_radius),
		center + Vector2(-diamond_radius, 0.0),
	])
	draw_colored_polygon(diamond, PALETTE.text_primary)


func _draw_box(rect: Rect2, fill: Color, border: Color, width: float, radius: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(roundi(width))
	box.set_corner_radius_all(roundi(maxf(radius, 0.0)))
	draw_style_box(box, rect)
