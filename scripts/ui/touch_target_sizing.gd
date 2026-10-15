class_name TouchTargetSizing
extends Node2D

## Android-only minimum hit size using densityDpi and the complete UI-to-display transform.
const MINIMUM_DP: float = 48.0
const BASE_DPI: float = 160.0
const MINIMUM_SCALE: float = 0.001
var _button: Button
var _authored_minimum: Vector2
var _density_override: int = 0
var _pending: bool = false

## Attach locally to audited buttons; an explicit density is reserved for focused simulations.
static func attach(button: Button, density_dpi: int = 0) -> TouchTargetSizing:
	var existing: TouchTargetSizing = button.get_node_or_null("TouchTargetSizing") as TouchTargetSizing
	if existing != null:
		if density_dpi > 0:
			existing._density_override = density_dpi
			existing._queue_layout()
		return existing
	var guard := TouchTargetSizing.new()
	guard.name = "TouchTargetSizing"
	guard._density_override = density_dpi
	button.add_child(guard)
	return guard

## Convert physical pixels to Android dp; screen scale is not Android logical density.
static func size_in_dp(ui_size: Vector2, pixels_per_unit: Vector2, density_dpi: int) -> Vector2:
	return ui_size * pixels_per_unit * BASE_DPI / float(maxi(density_dpi, 1))

## Android's engine implementation returns logical DisplayMetrics.densityDpi.
static func android_density_dpi() -> int:
	return DisplayServer.screen_get_dpi() if OS.has_feature("android") else 0

## Required local size after removing a Control's transient visual punch scale.
static func minimum_ui_size(control: Control, density_dpi: int) -> Vector2:
	# Viewport screen transform includes canvas_items stretch; CanvasItem's popup transform does not.
	var transform: Transform2D = control.get_viewport().get_screen_transform() * control.get_global_transform_with_canvas()
	var scale := Vector2(transform.x.length() / maxf(absf(control.scale.x), MINIMUM_SCALE),
		transform.y.length() / maxf(absf(control.scale.y), MINIMUM_SCALE)).max(Vector2.ONE * MINIMUM_SCALE)
	return (Vector2.ONE * MINIMUM_DP * float(density_dpi) / BASE_DPI / scale).ceil()

func _ready() -> void:
	_button = get_parent() as Button
	_authored_minimum = _button.custom_minimum_size
	get_viewport().size_changed.connect(_queue_layout)
	_button.resized.connect(_queue_layout)
	_button.visibility_changed.connect(_queue_layout)
	# Inherited transform notifications include ancestor scaling without button resizing.
	set_notify_transform(true)
	_queue_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		# Refresh the lazy transform cache so subsequent ancestor changes notify again.
		get_global_transform()
	if what in [NOTIFICATION_TRANSFORM_CHANGED, NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		_queue_layout()

func _queue_layout() -> void:
	if _pending or not is_inside_tree():
		return
	_pending = true
	_refresh_layout.call_deferred()

## Ignore the button's temporary press punch; use parent/stretch scaling for stable hit sizes.
func pixels_per_unit() -> Vector2:
	var transform: Transform2D = _button.get_viewport().get_screen_transform() * _button.get_global_transform_with_canvas()
	return Vector2(transform.x.length() / maxf(absf(_button.scale.x), MINIMUM_SCALE),
		transform.y.length() / maxf(absf(_button.scale.y), MINIMUM_SCALE))

func _refresh_layout() -> void:
	_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var dpi: int = _density_override
	if dpi <= 0:
		dpi = android_density_dpi()
	if dpi <= 0:
		return
	var minimum: Vector2 = minimum_ui_size(_button, dpi)
	minimum = minimum.max(_authored_minimum)
	if _button.custom_minimum_size != minimum:
		if _button.anchor_left == 1.0 and _button.anchor_right == 1.0:
			_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_button.custom_minimum_size = minimum
