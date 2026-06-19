extends Control

## In-engine "sliders/mixer" settings icon: three horizontal tracks each with a knob, drawn
## from the palette (no external asset, no font glyph). mouse_filter is IGNORE so the parent
## Button receives the tap. Square, centered.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var pad: float = s * 0.22
	var x0: float = pad
	var x1: float = s - pad
	var thickness: float = maxf(s * 0.05, 2.0)
	var knob_r: float = s * 0.1
	# Three tracks at 30% / 55% / 75% height, knobs at varied positions (a mixer look).
	var rows := [
		{"y": s * 0.32, "knob": 0.7},
		{"y": s * 0.5, "knob": 0.35},
		{"y": s * 0.68, "knob": 0.6},
	]
	var colors := [PALETTE.accent, PALETTE.accent_alt, PALETTE.warm]
	for i in rows.size():
		var y: float = rows[i]["y"]
		draw_line(Vector2(x0, y), Vector2(x1, y), PALETTE.border, thickness, true)
		var kx: float = lerpf(x0, x1, rows[i]["knob"])
		draw_circle(Vector2(kx, y), knob_r, colors[i])
