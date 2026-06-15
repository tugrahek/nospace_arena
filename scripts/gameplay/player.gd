class_name Player
extends Node2D

## Grid-based player with a pluggable control scheme. Movement logic is written
## once here; the active ControlScheme only reports a desired direction.
## Keyboard is always-on hold-to-move and takes priority over the touch scheme.

signal trail_started()
signal returned_to_safe()
signal control_scheme_changed(id: int)

enum SchemeId { TAP_TURN, SWIPE, DPAD }

@export var move_interval: float = 0.04  # seconds per one-cell step (~250 px/s)
@export var control_scheme: SchemeId = SchemeId.SWIPE

var _arena: ArenaController
var _grid_pos: Vector2i = Vector2i.ZERO
var _direction: Vector2i = Vector2i.ZERO
var _queued_dir: Vector2i = Vector2i.ZERO
var _is_drawing: bool = false
var _move_timer: float = 0.0
var _start_world: Vector2 = Vector2.ZERO
var _target_world: Vector2 = Vector2.ZERO

var _scheme: ControlScheme
var _kb_was_held: bool = false


## Wires the player to the arena, builds the control scheme, and rests it on the
## top-left frame corner.
func setup(arena: ArenaController) -> void:
	_arena = arena
	_grid_pos = Vector2i.ZERO
	_queued_dir = Vector2i.ZERO
	_is_drawing = false
	_move_timer = 0.0
	_apply_scheme(control_scheme)
	_start_world = _arena.cell_to_world(_grid_pos)
	_target_world = _start_world
	position = _start_world


func _apply_scheme(id: SchemeId) -> void:
	control_scheme = id
	_scheme = _make_scheme(id)
	_kb_was_held = false
	# Auto-advance schemes start gliding; hold schemes wait for input.
	_direction = Vector2i.RIGHT if _scheme.auto_advance else Vector2i.ZERO
	_queued_dir = Vector2i.ZERO
	control_scheme_changed.emit(int(id))


func _make_scheme(id: SchemeId) -> ControlScheme:
	match id:
		SchemeId.TAP_TURN:
			return TapTurnControl.new()
		SchemeId.DPAD:
			return DpadControl.new()
		_:
			return SwipeControl.new()


func _process(delta: float) -> void:
	if _arena == null:
		return
	_update_intent()
	_move_timer += delta
	if _move_timer >= move_interval:
		_move_timer -= move_interval
		if _queued_dir != Vector2i.ZERO:
			_direction = _queued_dir
			_queued_dir = Vector2i.ZERO
		_start_world = _arena.cell_to_world(_grid_pos)
		_try_step()
		_target_world = _arena.cell_to_world(_grid_pos)
	var t: float = clampf(_move_timer / move_interval, 0.0, 1.0)
	position = _start_world.lerp(_target_world, t)


## Resolves this frame's movement intent: keyboard hold takes priority, otherwise
## the active scheme drives. Hold schemes (and keyboard release) stop on idle.
func _update_intent() -> void:
	var kb: Vector2i = _keyboard_dir()
	if kb != Vector2i.ZERO:
		_queued_dir = kb
		_kb_was_held = true
		return
	if _kb_was_held:
		_kb_was_held = false
		_direction = Vector2i.ZERO
		_queued_dir = Vector2i.ZERO
		return
	var sdir: Vector2i = _scheme.poll(get_viewport_rect().size, _direction)
	if sdir != Vector2i.ZERO:
		_queued_dir = sdir
	elif not _scheme.auto_advance:
		_direction = Vector2i.ZERO
		_queued_dir = Vector2i.ZERO


## Advances one cell. Blocked steps (edge / own trail) keep the heading so the
## player stays steerable instead of freezing (real death comes in Step 04).
func _try_step() -> void:
	if _direction == Vector2i.ZERO:
		return
	var target: Vector2i = _grid_pos + _direction
	if not _arena.in_bounds_cell(target):
		return
	var state: int = _arena.cell_state(target)
	if state == CaptureGrid.Cell.CAPTURED:
		_grid_pos = target
		if _is_drawing:
			_is_drawing = false
			_arena.close_capture([])
			returned_to_safe.emit()
	elif state == CaptureGrid.Cell.FREE:
		if not _is_drawing:
			_is_drawing = true
			trail_started.emit()
		_arena.add_trail(target)
		_grid_pos = target
	# else: TRAIL -> blocked, keep heading


func _keyboard_dir() -> Vector2i:
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		return Vector2i.UP
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_apply_scheme(SchemeId.TAP_TURN)
				print("Kontrol şeması: TAP_TURN")
			KEY_2:
				_apply_scheme(SchemeId.SWIPE)
				print("Kontrol şeması: SWIPE")
			KEY_3:
				_apply_scheme(SchemeId.DPAD)
				print("Kontrol şeması: DPAD")
	if _scheme != null:
		_scheme.handle_input(event, get_viewport_rect().size)
