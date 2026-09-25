class_name TrailHeadLayer
extends Node2D

## Presentation-only overlay for the moving end of a live trail. The CaptureGrid owns
## the real trail; this node merely clips the newest visual segment to the Player.

enum Mode { NONE, FORWARD, RETRACT }

var _mode: Mode = Mode.NONE
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _visual_position: Vector2 = Vector2.ZERO
var _head_cell: Vector2i = Vector2i(-1, -1)
var _cell_size: float = 0.0
var _trail_color: Color = Color.WHITE
var _glow_width: float = 0.0
var _glow_alpha: float = 0.0
var _head_brightness: float = 0.0


func configure(cell_size: float, trail_color: Color, glow_width: float, glow_alpha: float,
		head_brightness: float) -> void:
	_cell_size = cell_size
	_trail_color = trail_color
	_glow_width = glow_width
	_glow_alpha = glow_alpha
	_head_brightness = head_brightness
	queue_redraw()


func begin_forward(from: Vector2, to: Vector2, head_cell: Vector2i) -> void:
	if not _is_cardinal_step(from, to) or _cell_size <= 0.0:
		clear()
		return
	_mode = Mode.FORWARD
	_from = from
	_to = to
	_visual_position = from
	_head_cell = head_cell
	queue_redraw()


func begin_retract(from: Vector2, to: Vector2) -> void:
	if not _is_cardinal_step(from, to) or _cell_size <= 0.0:
		clear()
		return
	_mode = Mode.RETRACT
	_from = from
	_to = to
	_visual_position = from
	_head_cell = Vector2i(-1, -1)
	queue_redraw()


func update_visual_position(value: Vector2) -> void:
	if _mode == Mode.NONE:
		return
	if _visual_position.is_equal_approx(value):
		return
	_visual_position = value
	if _mode == Mode.RETRACT and _visual_position.distance_to(_to) <= 0.001:
		_mode = Mode.NONE
	queue_redraw()


func clear() -> void:
	if _mode == Mode.NONE:
		return
	_mode = Mode.NONE
	_head_cell = Vector2i(-1, -1)
	queue_redraw()


## True only when this layer fully owns the current logical forward head's rendering.
func covers_head(cell: Vector2i) -> bool:
	return _mode == Mode.FORWARD and _head_cell == cell and _is_cardinal_step(_from, _to)


func _draw() -> void:
	var rect: Rect2 = forward_rect(_from, _to, _visual_position, _cell_size) \
		if _mode == Mode.FORWARD else retract_rect(_from, _to, _visual_position, _cell_size)
	if _mode == Mode.NONE or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if _glow_width > 0.0 and _glow_alpha > 0.0:
		var halo: Color = _trail_color
		halo.a = _trail_color.a * _glow_alpha
		draw_rect(rect.grow(_glow_width), halo)
	draw_rect(rect, _trail_color)
	if _head_brightness > 0.0:
		draw_rect(rect, _trail_color.lightened(_head_brightness))


## Returns the portion of the new head cell reached by the visual Player. At `to`,
## the full cell is visible; no diagonal geometry is produced for an invalid step.
static func forward_rect(from: Vector2, to: Vector2, visual_position: Vector2,
		cell_size: float) -> Rect2:
	if not _is_cardinal_step(from, to) or cell_size <= 0.0:
		return Rect2()
	var direction: Vector2 = (to - from) / cell_size
	var progress: float = clampf((visual_position - from).dot(direction), 0.0, cell_size)
	var half: float = cell_size * 0.5
	if absf(direction.x) > 0.0:
		var x: float = to.x - half if direction.x > 0.0 else to.x + half - progress
		return Rect2(x, to.y - half, progress, cell_size)
	var y: float = to.y - half if direction.y > 0.0 else to.y + half - progress
	return Rect2(to.x - half, y, cell_size, progress)


## Draws a shrinking presentation-only remnant while the Player backtracks. The
## removed cell stays absent from the grid; this geometry is never read by gameplay.
static func retract_rect(from: Vector2, to: Vector2, visual_position: Vector2,
		cell_size: float) -> Rect2:
	if not _is_cardinal_step(from, to) or cell_size <= 0.0:
		return Rect2()
	var direction: Vector2 = (to - from) / cell_size
	var half: float = cell_size * 0.5
	var near_boundary: Vector2 = from + direction * half
	var remaining: float = clampf((visual_position - near_boundary).dot(-direction), 0.0, half)
	if absf(direction.x) > 0.0:
		var x: float = near_boundary.x if direction.x < 0.0 else near_boundary.x - remaining
		return Rect2(x, from.y - half, remaining, cell_size)
	var y: float = near_boundary.y if direction.y < 0.0 else near_boundary.y - remaining
	return Rect2(from.x - half, y, cell_size, remaining)


static func _is_cardinal_step(from: Vector2, to: Vector2) -> bool:
	var delta: Vector2 = to - from
	return (is_equal_approx(absf(delta.x), 0.0) and not is_equal_approx(absf(delta.y), 0.0)) \
		or (is_equal_approx(absf(delta.y), 0.0) and not is_equal_approx(absf(delta.x), 0.0))
