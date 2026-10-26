extends Control

## Existing neon d-pad visual, shown around the controlling touch only while held.
## Geometry is read from DpadControl so the visual and the input mapping match.

@export var color: Color = Color(0.2, 0.95, 1.0, 0.5)

var _active: bool = false
var _origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	# The directional overlay must match physical input coordinates in every locale.
	layout_direction = Control.LAYOUT_DIRECTION_LTR


func set_active(active: bool) -> void:
	_active = active
	visible = false
	queue_redraw()


## Receives viewport-space gesture presentation without interpreting raw input.
func set_gesture(held: bool, origin: Vector2) -> void:
	visible = _active and held
	_origin = get_global_transform_with_canvas().affine_inverse() * origin
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var c: Vector2 = _origin
	var r: float = DpadControl.RADIUS
	draw_line(c, c + Vector2(0, -r), color, 4.0)
	draw_line(c, c + Vector2(0, r), color, 4.0)
	draw_line(c, c + Vector2(-r, 0), color, 4.0)
	draw_line(c, c + Vector2(r, 0), color, 4.0)
	draw_circle(c, DpadControl.DEAD_ZONE, Color(color.r, color.g, color.b, 0.25))
