extends Control

## In-engine "?" help icon (polyline hook + dot), drawn from the palette (no asset, no font
## glyph). mouse_filter IGNORE so the parent Button gets the tap. Square, centered.

const PALETTE = preload("res://config/palette.tres")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.42
	var w: float = maxf(s * 0.08, 3.0)
	var col: Color = PALETTE.accent
	# "?" hook stroke (left -> over the top -> right -> curl into the stem).
	var p := func(dx: float, dy: float) -> Vector2: return Vector2(cx + dx * s, cy + dy * s)
	var hook := PackedVector2Array([
		p.call(-0.16, -0.04), p.call(-0.12, -0.18), p.call(0.0, -0.22),
		p.call(0.14, -0.16), p.call(0.15, -0.01), p.call(0.02, 0.08), p.call(0.0, 0.18),
	])
	draw_polyline(hook, col, w, true)
	draw_circle(Vector2(cx, cy + s * 0.30), w * 0.75, col)
