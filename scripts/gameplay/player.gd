class_name Player
extends Node2D

## Grid-based player with a pluggable control scheme. Movement logic is written
## once here; the active ControlScheme only reports a desired direction.
## Keyboard is always-on hold-to-move and takes priority over the touch scheme.

signal trail_started()
signal returned_to_safe()
signal loop_closed()
signal control_scheme_changed(id: int)

enum SchemeId { TAP_TURN, SWIPE, DPAD }

@export var move_interval: float = 0.04  # seconds per one-cell step (~250 px/s)
@export var control_scheme: SchemeId = SchemeId.SWIPE

var _arena: ArenaController
var _grid_pos: Vector2i = Vector2i.ZERO
var _safe_cell: Vector2i = Vector2i.ZERO  # last safe cell, used on respawn
var _direction: Vector2i = Vector2i.ZERO
var _queued_dir: Vector2i = Vector2i.ZERO
var _is_drawing: bool = false
var _trail_path: Array[Vector2i] = []  # ordered trail cells; back() == _grid_pos while drawing
var _move_timer: float = 0.0
var _start_world: Vector2 = Vector2.ZERO
var _target_world: Vector2 = Vector2.ZERO

var _scheme: ControlScheme
var _kb_was_held: bool = false


## True while drawing a trail in the open (vulnerable). State-aware enemies hunt only
## then; while safe on captured territory the player is not a target.
func is_exposed() -> bool:
	return _is_drawing


## Wires the player to the arena, builds the control scheme, and rests it on the
## top-left frame corner. Always starts still regardless of auto_advance scheme.
func setup(arena: ArenaController) -> void:
	_arena = arena
	_grid_pos = Vector2i.ZERO
	_safe_cell = Vector2i.ZERO
	_trail_path.clear()
	_queued_dir = Vector2i.ZERO
	_is_drawing = false
	_move_timer = 0.0
	_apply_scheme(control_scheme)
	# Always start still — first input initiates movement.
	_direction = Vector2i.ZERO
	_queued_dir = Vector2i.ZERO
	_start_world = _arena.cell_to_world(_grid_pos)
	_target_world = _start_world
	position = _start_world


## Returns the player to its last safe cell after a life loss and drops the trail
## state. Always starts still so the player can orient before re-entering the void.
func respawn() -> void:
	_is_drawing = false
	_trail_path.clear()
	_grid_pos = _safe_cell
	_queued_dir = Vector2i.ZERO
	_direction = Vector2i.ZERO  # always still on respawn
	_move_timer = 0.0
	_start_world = _arena.cell_to_world(_grid_pos)
	_target_world = _start_world
	position = _start_world


func _apply_scheme(id: SchemeId) -> void:
	control_scheme = id
	_scheme = _make_scheme(id)
	_kb_was_held = false
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
	if _arena == null or not GameState.is_playing():
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


## Advances one cell. Handles: trail extension, loop close, backtracking (undo
## last trail cell), and backtrack-cancel (abort trail with zero cells left).
## Blocked steps (edge / non-adjacent trail) keep heading so player stays steerable.
func _try_step() -> void:
	if _direction == Vector2i.ZERO:
		return
	var target: Vector2i = _grid_pos + _direction
	if not _arena.in_bounds_cell(target):
		return
	var state: int = _arena.cell_state(target)
	if state == CaptureGrid.Cell.CAPTURED:
		if _is_drawing and _trail_path.size() == 1 and target == _safe_cell:
			# Backtrack-cancel: only one trail cell, stepping back to safe start.
			_arena.remove_trail(_grid_pos)
			_trail_path.clear()
			_grid_pos = target
			_is_drawing = false
		else:
			_grid_pos = target
			_safe_cell = target
			if _is_drawing:
				_is_drawing = false
				_trail_path.clear()
				loop_closed.emit()  # Game performs the capture with enemy seeds
				returned_to_safe.emit()
	elif state == CaptureGrid.Cell.FREE:
		if not _is_drawing:
			_is_drawing = true
			_safe_cell = _grid_pos  # the captured cell we dove from
			trail_started.emit()
		_arena.add_trail(target)
		_trail_path.append(target)
		_grid_pos = target
	elif state == CaptureGrid.Cell.TRAIL:
		if _is_drawing and _trail_path.size() >= 2 and target == _trail_path[_trail_path.size() - 2]:
			# Backtrack: undo the last trail step, freeing the current cell.
			_arena.remove_trail(_grid_pos)
			_trail_path.pop_back()
			_grid_pos = target
		# else: non-adjacent trail (loop) — blocked, keep heading


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
