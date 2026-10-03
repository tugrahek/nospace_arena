extends Control

## Draws the winding connector line between campaign level nodes. level_select.gd positions the
## node buttons on this canvas and feeds the ordered node centers via set_points().

const PALETTE = preload("res://config/palette.tres")

var _points: PackedVector2Array = PackedVector2Array()
var _node_half_size: Vector2 = Vector2.ZERO


## Receives the authored route centers and trims each connector before it reaches a node surface.
func set_points(points: PackedVector2Array, node_half_size: Vector2 = Vector2.ZERO) -> void:
	_points = points
	_node_half_size = node_half_size
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return
	var col: Color = PALETTE.accent
	col.a = 0.32
	for i in range(_points.size() - 1):
		var start: Vector2 = _points[i]
		var end: Vector2 = _points[i + 1]
		var segment: Vector2 = end - start
		var length: float = segment.length()
		var direction: Vector2 = segment / length if length > 0.0 else Vector2.ZERO
		var trim: float = _boundary_distance(direction)
		if length <= trim * 2.0:
			continue
		draw_line(start + direction * trim, end - direction * trim, col, 4.0, true)


func _boundary_distance(direction: Vector2) -> float:
	var x_distance: float = INF if is_zero_approx(direction.x) else absf(_node_half_size.x / direction.x)
	var y_distance: float = INF if is_zero_approx(direction.y) else absf(_node_half_size.y / direction.y)
	return mini(x_distance, y_distance) + 4.0
