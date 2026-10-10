class_name SafeAreaMargin
extends MarginContainer

## Opt-in, screen-aligned UI margin. Owns only the four native margin constants.
## Keep backgrounds and gameplay outside this container; inherit the existing theme.
## Padding order is left, top, right, bottom, in local UI units (not display pixels).
@export var content_padding: Vector4i = Vector4i.ZERO:
	set(value):
		content_padding = Vector4i(maxi(value.x, 0), maxi(value.y, 0), maxi(value.z, 0), maxi(value.w, 0))
		_queue_refresh()

const MARGIN_NAMES: Array[StringName] = [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]
var _safe_insets: Vector4i = Vector4i.ZERO
var _refresh_pending: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _enter_tree() -> void:
	if not get_viewport().size_changed.is_connected(_queue_refresh):
		get_viewport().size_changed.connect(_queue_refresh)
	_queue_refresh()


func _ready() -> void:
	resized.connect(_queue_refresh)
	set_notify_transform(true)
	_queue_refresh()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_TRANSFORM_CHANGED, NOTIFICATION_APPLICATION_RESUMED,
			NOTIFICATION_APPLICATION_FOCUS_IN]:
		_queue_refresh()


func _exit_tree() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_queue_refresh):
		viewport.size_changed.disconnect(_queue_refresh)
	_refresh_pending = false


## Re-reads current platform bounds; safe after resize, resume or native form dismissal.
## The complete screen transform already contains stretch, canvas and window placement.
func refresh_safe_area() -> void:
	_refresh_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_safe_insets = calculate_insets(_get_display_safe_area(), _get_local_to_display(), size)
	var margins: Vector4i = _safe_insets + content_padding
	for index: int in MARGIN_NAMES.size():
		if not has_theme_constant_override(MARGIN_NAMES[index]) or get_theme_constant(MARGIN_NAMES[index]) != margins[index]:
			add_theme_constant_override(MARGIN_NAMES[index], margins[index])


## Returns platform-only margins in local UI units, excluding authored content padding.
func safe_insets() -> Vector4i:
	return _safe_insets


func _queue_refresh() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or _refresh_pending:
		return
	_refresh_pending = true
	refresh_safe_area.call_deferred()


## Desktop/headless usable-work-area bounds are not mobile safe-area insets.
func _get_display_safe_area() -> Rect2:
	if OS.get_name() not in ["Android", "iOS"]:
		return Rect2()
	return Rect2(DisplayServer.get_display_safe_area())


func _get_local_to_display() -> Transform2D:
	return get_screen_transform()


## Pure conversion for positive, axis-aligned UI roots. Rotation/skew is unsupported.
## Clamp to this container, so already excluded system or ancestor insets are not added twice.
## Empty platform bounds mean unavailable/zero insets. Round outward once for pixel safety.
static func calculate_insets(display_safe_area: Rect2, local_to_display: Transform2D,
		local_size: Vector2) -> Vector4i:
	if not display_safe_area.has_area() or local_size.x <= 0.0 or local_size.y <= 0.0:
		return Vector4i.ZERO
	if local_to_display.x.x <= 0.0 or local_to_display.y.y <= 0.0 \
			or not is_zero_approx(local_to_display.x.y) or not is_zero_approx(local_to_display.y.x):
		return Vector4i.ZERO
	var local_safe: Rect2 = local_to_display.affine_inverse() * display_safe_area
	var start: Vector2 = local_safe.position.clamp(Vector2.ZERO, local_size)
	var end: Vector2 = local_safe.end.clamp(Vector2.ZERO, local_size)
	return Vector4i(ceili(start.x), ceili(start.y), ceili(local_size.x - end.x), ceili(local_size.y - end.y))
