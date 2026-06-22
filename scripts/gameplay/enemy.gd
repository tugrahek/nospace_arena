class_name Enemy
extends Node2D

## Roams the FREE arena area, bouncing off CAPTURED cells and the arena edge.
## Touching the active TRAIL is lethal to the player (emits hit_trail).
## Living-territory effects act via the active effect: Push steers, Drag slows,
## Stasis freezes ON CONTACT with player-captured territory.

signal hit_trail()

enum Shape { CIRCLE, TRIANGLE }

@export var radius: float = 9.0
@export var color: Color = Color(1.0, 0.25, 0.2, 1.0)
@export var recovery_time: float = 0.18  # after a bounce/freeze, briefly suppress homing so the
                                          # enemy peels off the wall on its reflected heading
                                          # instead of re-homing into it (no boundary pin/stall)

var shape: int = Shape.CIRCLE  # placeholder type tell (Step 14 sprites)

var _arena: ArenaController
var _behavior: EnemyBehavior = null
var _base_speed_px: float = 0.0
var _variation: float = 0.0  # per-enemy [-1,1] offset so same-type enemies don't overlap
var _velocity: Vector2 = Vector2.ZERO
var _speed_scale: float = 1.0  # transient per-frame slow from territory effects (Drag)
var _active_effect: TerritoryEffect = null  # set each frame by LivingTerritory
var _freeze_timer: float = 0.0  # > 0 while contact-frozen (Stasis); no movement
var _freeze_cooldown_timer: float = 0.0  # blocks re-freeze (prevents boundary jitter re-lock)
var _pending_cooldown: float = 0.0
var _recovery_timer: float = 0.0  # post-freeze: behavior suppressed, moves on reflected heading
var _steered: bool = false  # TEMP: debug tint while steered/slowed (Step 15 juice replaces)
var _frozen: bool = false  # TEMP: distinct tint while contact-frozen


func setup(arena: ArenaController, start_pos: Vector2, velocity: Vector2, behavior: EnemyBehavior, base_speed_px: float, variation: float = 0.0) -> void:
	_arena = arena
	position = start_pos
	_velocity = velocity
	_behavior = behavior
	_base_speed_px = base_speed_px
	_variation = variation
	_speed_scale = 1.0
	_active_effect = null
	_freeze_timer = 0.0
	_freeze_cooldown_timer = 0.0
	_pending_cooldown = 0.0
	_recovery_timer = 0.0
	_steered = false
	_frozen = false
	queue_redraw()


## This frame's behavior decision (homing/heading), before any effect or collision.
## Pure per type; the effect + collision layer is applied on top by apply_territory/_move.
func decide_velocity(player_pos: Vector2, player_exposed: bool) -> Vector2:
	# While frozen or recovering, keep the reflected heading (peel off the wall) instead
	# of re-deciding — avoids a re-freeze loop right after a Halt freeze.
	if _behavior == null or EnemyMotion.is_behavior_suppressed(_freeze_timer, _recovery_timer):
		return _velocity
	return _behavior.decide(_velocity, position, player_pos, player_exposed, _base_speed_px, _variation)


## Applies the living-territory effect on top of the behavior's base velocity. steer
## changes the heading (Push, magnitude kept); speed_scale transiently slows (Drag).
## The effect is cached so a contact bounce can trigger Stasis freeze. Pipeline order:
## behavior.decide -> steer -> speed_scale -> (collision/contact-freeze in _move).
func apply_territory(effect: TerritoryEffect, arena: ArenaController, base_velocity: Vector2) -> void:
	_active_effect = effect
	_velocity = effect.steer(base_velocity, position, arena)
	_speed_scale = effect.speed_scale(position, arena)
	var active: bool = (not _velocity.is_equal_approx(base_velocity)) or _speed_scale < 0.999
	if active != _steered:
		_steered = active
		queue_redraw()


func _physics_process(delta: float) -> void:
	if _arena == null or not GameState.is_playing():
		return
	# Contact freeze (Stasis): hold still while the timer runs, then start cooldown.
	if _freeze_timer > 0.0:
		_freeze_timer -= delta
		if _freeze_timer <= 0.0:
			_freeze_cooldown_timer = _pending_cooldown
			_recovery_timer = recovery_time  # peel off the wall before homing resumes
			_frozen = false
			queue_redraw()
		return
	if _freeze_cooldown_timer > 0.0:
		_freeze_cooldown_timer -= delta
	if _recovery_timer > 0.0:
		_recovery_timer -= delta
	_move(delta)


## Sub-stepped movement so a fast enemy cannot tunnel through a 1-cell trail/wall.
func _move(delta: float) -> void:
	if _velocity == Vector2.ZERO:
		return
	var remaining: float = _velocity.length() * _speed_scale * delta
	var step_len: float = _arena.cell_size * 0.5
	while remaining > 0.0:
		var step: float = minf(step_len, remaining)
		remaining -= step
		if not _advance(step):
			return


## Advances one sub-step. Enemies move diagonally (signf never 0). TRAIL is checked
## at the center path (lethality unchanged from S04); CAPTURED bounce is radius-aware
## (probes the body's leading edge + clamps the center so the body never overlaps).
## Bouncing off PLAYER-captured territory can trigger a contact freeze (Stasis).
func _advance(step: float) -> bool:
	var dir: Vector2 = _velocity.normalized()
	var next_pos: Vector2 = position + dir * step
	# TRAIL (lethal): center path, unchanged difficulty.
	if _state_at(Vector2(next_pos.x, position.y)) == CaptureGrid.Cell.TRAIL \
		or _state_at(Vector2(position.x, next_pos.y)) == CaptureGrid.Cell.TRAIL \
		or _state_at(next_pos) == CaptureGrid.Cell.TRAIL:
		hit_trail.emit()
		return false
	# CAPTURED bounce: probe the body's leading edge (radius ahead of center).
	var sgx: float = signf(_velocity.x)
	var sgy: float = signf(_velocity.y)
	var cx: Vector2i = _arena.world_to_cell(Vector2(next_pos.x + sgx * radius, position.y))
	var cy: Vector2i = _arena.world_to_cell(Vector2(position.x, next_pos.y + sgy * radius))
	var block_x: bool = _arena.cell_state(cx) == CaptureGrid.Cell.CAPTURED
	var block_y: bool = _arena.cell_state(cy) == CaptureGrid.Cell.CAPTURED
	if block_x:
		var face_x: float = _arena.cell_to_world(cx).x - sgx * _arena.cell_size * 0.5
		position.x = EnemyMotion.clamp_to_wall(position.x, face_x, radius, sgx)
	if block_y:
		var face_y: float = _arena.cell_to_world(cy).y - sgy * _arena.cell_size * 0.5
		position.y = EnemyMotion.clamp_to_wall(position.y, face_y, radius, sgy)
	if block_x or block_y:
		_velocity = EnemyMotion.reflect(_velocity, block_x, block_y)
		_recovery_timer = recovery_time  # peel off on the reflected heading (no homing pin)
		queue_redraw()
		var on_player: bool = (block_x and _arena.is_player_captured(cx)) \
			or (block_y and _arena.is_player_captured(cy))
		if on_player and _try_contact_freeze():
			return false  # frozen: stop this frame's substeps
		return true
	# Diagonal corner: leading-edge probe on both axes.
	var cd: Vector2i = _arena.world_to_cell(Vector2(next_pos.x + sgx * radius, next_pos.y + sgy * radius))
	if _arena.cell_state(cd) == CaptureGrid.Cell.CAPTURED:
		_velocity = EnemyMotion.reflect(_velocity, true, true)
		_recovery_timer = recovery_time  # peel off on the reflected heading (no homing pin)
		queue_redraw()
		if _arena.is_player_captured(cd) and _try_contact_freeze():
			return false
		return true
	position = next_pos
	queue_redraw()
	return true


## Starts a contact freeze if the active effect provides one and cooldown is clear.
## Returns true if a freeze began (caller should stop moving this frame).
func _try_contact_freeze() -> bool:
	if _active_effect == null or _freeze_cooldown_timer > 0.0:
		return false
	var dur: float = _active_effect.contact_freeze_duration()
	if dur <= 0.0:
		return false
	_freeze_timer = dur
	_pending_cooldown = _active_effect.contact_freeze_cooldown()
	_frozen = true
	queue_redraw()
	return true


func _state_at(world: Vector2) -> int:
	return _arena.cell_state(_arena.world_to_cell(world))


func _draw() -> void:
	# TEMP (Step 15): debug tints so effects are visible before real VFX exist.
	# Contact-frozen (Stasis) reads as near-white; other active effects just lighten.
	var draw_color: Color = color
	if _frozen:
		draw_color = color.lerp(Color.WHITE, 0.8)
	elif _steered:
		draw_color = color.lightened(0.5)
	if shape == Shape.TRIANGLE:
		var pts := PackedVector2Array([
			Vector2(0, -radius),
			Vector2(-radius * 0.866, radius * 0.5),
			Vector2(radius * 0.866, radius * 0.5),
		])
		draw_colored_polygon(pts, draw_color)
	else:
		draw_circle(Vector2.ZERO, radius, draw_color)
