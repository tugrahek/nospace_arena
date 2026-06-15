extends Control

## Minimal neon d-pad visual, shown only while the DPAD control scheme is active.
## Geometry is read from DpadControl so the visual and the input mapping match.

@export var color: Color = Color(0.2, 0.95, 1.0, 0.5)

var _active: bool = false


func set_active(active: bool) -> void:
	_active = active
	visible = active
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var c: Vector2 = DpadControl.center(get_viewport_rect().size)
	var r: float = DpadControl.RADIUS
	draw_line(c, c + Vector2(0, -r), color, 4.0)
	draw_line(c, c + Vector2(0, r), color, 4.0)
	draw_line(c, c + Vector2(-r, 0), color, 4.0)
	draw_line(c, c + Vector2(r, 0), color, 4.0)
	draw_circle(c, DpadControl.DEAD_ZONE, Color(color.r, color.g, color.b, 0.25))
