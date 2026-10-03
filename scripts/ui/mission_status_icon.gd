class_name MissionStatusIcon
extends Control

## Restrained frontier and player marker for the compact in-run mission count.

const PALETTE: PaletteData = preload("res://config/palette.tres")


func _draw() -> void:
	var tip := Vector2(16.0, 13.0)
	draw_line(Vector2(4.0, 3.0), Vector2(4.0, 13.0), PALETTE.accent_alt, 2.0, true)
	draw_line(Vector2(4.0, 13.0), tip, PALETTE.accent_alt, 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		tip + Vector2(0.0, -3.0), tip + Vector2(3.0, 0.0),
		tip + Vector2(0.0, 3.0), tip + Vector2(-3.0, 0.0)
	]), PALETTE.text_primary)
