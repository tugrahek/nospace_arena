class_name Enemy
extends Node2D

## Roams the FREE arena area, bouncing off CAPTURED cells and the arena edge.
## Touching the active TRAIL is lethal to the player (emits hit_trail).
## Living-territory effects act via the active effect: Push steers, Drag slows,
## Stasis freezes ON CONTACT with player-captured territory.

signal hit_trail()

enum Shape { CIRCLE, TRIANGLE, SQUARE }

# Sparx lifecycle: patrols the edge; when the player seals it off from the main region it is
# CONTAINED (invisible breather), then re-emerges via a non-lethal TELEGRAPH blink back to PATROL.
enum SparxState { PATROL, CONTAINED, TELEGRAPH }

@export var radius: float = 9.0
@export var color: Color = Color(1.0, 0.25, 0.2, 1.0)
@export var recovery_time: float = 0.18  # after a bounce/freeze, briefly suppress homing so the
                                          # enemy peels off the wall on its reflected heading
                                          # instead of re-homing into it (no boundary pin/stall)
@export var edge_catch_cooldown: float = 1.0  # Sparx: grace after catching the player (no chain-kill)
@export var contain_duration: float = 5.0     # Sparx: invisible breather while CONTAINED
@export var emerge_telegraph: float = 0.4     # Sparx: warning blink on re-emerge before lethal again
@export var trap_pocket_max_cells: int = 400  # Sparx: secondary safety -> also trapped if region <= this
@export var safe_emerge_distance: int = 7      # Sparx: re-emerge >= this many cells from the player
@export var loop_check_steps: int = 64         # Sparx: window of steps to detect a degenerate loop
@export var loop_min_cells: int = 24           # Sparx: <= this many distinct cells in the window = stuck loop

var shape: int = Shape.CIRCLE  # placeholder type tell (Step 14 sprites)

var _arena: ArenaController
var _behavior: EnemyBehavior = null
var _base_speed_px: float = 0.0
var _variation: float = 0.0  # per-enemy [-1,1] offset so same-type enemies don't overlap

# Edge-follow (Sparx) movement state — grid wall-follower along the captured perimeter.
var _edge_follow: bool = false
var _grid_cell: Vector2i = Vector2i.ZERO
var _heading: Vector2i = Vector2i.DOWN
var _step_from: Vector2 = Vector2.ZERO
var _step_to: Vector2 = Vector2.ZERO
var _step_timer: float = 0.0
var _last_player_pos: Vector2 = Vector2.ZERO
var _has_player: bool = false  # set once LivingTerritory reports the player (gates edge catch)
var _catch_cd: float = 0.0     # Sparx catch cooldown
var _sparx_state: int = SparxState.PATROL
var _contain_timer: float = 0.0    # CONTAINED countdown (fixed physics-step, grid-independent)
var _telegraph_timer: float = 0.0  # TELEGRAPH countdown (non-lethal warning blink)
var _loop_seen: Dictionary = {}    # distinct cells visited in the current loop-detection window
var _loop_steps: int = 0           # steps taken in the current window
var _velocity: Vector2 = Vector2.ZERO
var _speed_scale: float = 1.0  # transient per-frame slow from territory effects (Drag)
var run_speed_scale: float = 1.0  # run-start boost (Slow Start): < 1 slows; game resets to 1 on expiry
var _active_effect: TerritoryEffect = null  # set each frame by LivingTerritory
var _freeze_timer: float = 0.0  # > 0 while contact-frozen (Stasis); no movement
var _freeze_cooldown_timer: float = 0.0  # blocks re-freeze (prevents boundary jitter re-lock)
var _pending_cooldown: float = 0.0
var _recovery_timer: float = 0.0  # post-freeze: behavior suppressed, moves on reflected heading
var _steered: bool = false  # TEMP: debug tint while steered/slowed (Step 15 juice replaces)
var _frozen: bool = false  # TEMP: distinct tint while contact-frozen


func setup(arena: ArenaController, start_pos: Vector2, velocity: Vector2, behavior: EnemyBehavior, base_speed_px: float, variation: float = 0.0, edge_follow: bool = false, start_cell: Vector2i = Vector2i.ZERO, heading: Vector2i = Vector2i.DOWN) -> void:
	_arena = arena
	position = start_pos
	_velocity = velocity
	_behavior = behavior
	_base_speed_px = base_speed_px
	_variation = variation
	_edge_follow = edge_follow
	_grid_cell = start_cell
	_heading = heading
	_step_from = start_pos
	_step_to = start_pos
	_step_timer = 0.0
	_has_player = false
	_catch_cd = 0.0
	_sparx_state = SparxState.PATROL
	_contain_timer = 0.0
	_telegraph_timer = 0.0
	_loop_seen = {}
	_loop_steps = 0
	visible = true
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
	_last_player_pos = player_pos  # cached for Sparx edge-catch (LivingTerritory runs first)
	_has_player = true
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
	if _edge_follow:
		_edge_process(delta)
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


## Sparx lifecycle dispatch (PATROL -> CONTAINED -> TELEGRAPH -> PATROL). Timers run on the fixed
## physics step so they are grid-independent and frame-deterministic (daily/ghost reproduce).
func _edge_process(delta: float) -> void:
	if _catch_cd > 0.0:
		_catch_cd -= delta
	match _sparx_state:
		SparxState.CONTAINED:
			# Invisible breather. ALWAYS expires on its own timer -> re-emerge (no capture needed).
			_contain_timer -= delta
			if _contain_timer <= 0.0:
				_begin_telegraph()
		SparxState.TELEGRAPH:
			# Visible non-lethal warning blink at the re-emerge cell, then back to patrol.
			_telegraph_timer -= delta
			queue_redraw()
			if _telegraph_timer <= 0.0:
				_sparx_state = SparxState.PATROL
		_:
			_patrol(delta)


## PATROL: edge-locked wall-follow. Every step lands on a FREE cell adjacent to a wall; never the
## open interior. Lethal via the trail and the player-cell catch (19b-2). Engulf or a degenerate
## (no walkable neighbour) cell triggers re-projection instead of spinning.
func _patrol(delta: float) -> void:
	# Engulf safety: the cell got captured under it -> contain (connectivity trigger also covers this).
	if _arena.cell_state(_grid_cell) == CaptureGrid.Cell.CAPTURED:
		_enter_contain()
		return
	var interval: float = maxf(_arena.cell_size / maxf(_base_speed_px * run_speed_scale, 0.001), 0.001)
	_step_timer += delta
	while _step_timer >= interval:
		_step_timer -= interval
		_grid_cell = _arena.world_to_cell(_step_to)  # arrived at the previous target
		if _is_stuck_in_loop():  # circling a tiny sub-loop (e.g. a captured island) -> relocate
			_begin_telegraph()
			return
		_heading = _next_edge_heading()
		_step_from = _arena.cell_to_world(_grid_cell)
		var next_cell: Vector2i = _grid_cell + _heading
		if not _edge_open(next_cell):
			# Boxed on all four sides (isolated cell) -> relocate, never step into a wall or spin.
			_begin_telegraph()
			return
		if _arena.cell_state(next_cell) == CaptureGrid.Cell.TRAIL:
			hit_trail.emit()
			return
		_step_to = _arena.cell_to_world(next_cell)
	position = _step_from.lerp(_step_to, clampf(_step_timer / interval, 0.0, 1.0))
	# Threat (b): Sparx catches the player at the edge even when safe -> can't linger on the
	# border. Cell-adjacent; a cooldown after a catch prevents chain-kills on respawn.
	if _has_player and _catch_cd <= 0.0:
		var pc: Vector2i = _arena.world_to_cell(_last_player_pos)
		if absi(pc.x - _grid_cell.x) + absi(pc.y - _grid_cell.y) <= 1:
			_catch_cd = edge_catch_cooldown
			hit_trail.emit()
			return
	queue_redraw()


## Degenerate-loop detector: records each arrival cell; once a window of loop_check_steps passes, if
## only a tiny distinct set was visited (<= loop_min_cells) AND the reachable FREE area is far larger
## than that loop, Sparx is circling a sub-loop (e.g. a captured island) and can't reach the main
## edge -> signal a relocate. Otherwise resets the window. The FREE-area gate avoids thrash when the
## whole remaining arena IS that small (near-win, nowhere better). Deterministic (no RNG).
func _is_stuck_in_loop() -> bool:
	_loop_seen[_grid_cell] = true
	_loop_steps += 1
	if _loop_steps < loop_check_steps:
		return false
	var tiny: bool = _loop_seen.size() <= loop_min_cells
	var has_more: bool = _flood_free_set(_grid_cell, loop_min_cells * 4).size() > loop_min_cells
	_reset_loop_tracker()
	return tiny and has_more


func _reset_loop_tracker() -> void:
	_loop_seen.clear()
	_loop_steps = 0


## PATROL -> CONTAINED: invisible + inert breather on its own timer.
func _enter_contain() -> void:
	_reset_loop_tracker()
	_sparx_state = SparxState.CONTAINED
	_contain_timer = contain_duration
	visible = false
	queue_redraw()
	if OS.is_debug_build():
		print("[Sparx] CONTAINED @ ", _grid_cell)


## CONTAINED -> TELEGRAPH: snap onto a walkable perimeter of the MAIN region nearest the player
## (never the pocket), with a valid heading, then a non-lethal warning blink. Grid is read-only.
func _begin_telegraph() -> void:
	_reset_loop_tracker()
	var ref: Vector2i = _arena.world_to_cell(_last_player_pos) if _has_player else _grid_cell
	_reproject_to_main(ref)
	_sparx_state = SparxState.TELEGRAPH
	_telegraph_timer = emerge_telegraph
	visible = true
	queue_redraw()
	if OS.is_debug_build():
		print("[Sparx] RE-EMERGE @ ", _grid_cell, " heading ", _heading)


## Called after every capture (grid changed). Connectivity trigger: Sparx is trapped when its FREE
## region is NOT the main (largest) FREE region -- i.e. the player sealed it off from the play area
## -- or when its cell was engulfed (captured). Optional size safety: also trap a tiny pocket even
## inside the main region. Read-only flood-fill, deterministic; runs only on capture events.
func on_capture_event() -> void:
	if not _edge_follow or _sparx_state != SparxState.PATROL:
		return
	if _is_trapped():
		_enter_contain()


## True when the player has cut Sparx off from the main play area (or engulfed its cell).
func _is_trapped() -> bool:
	var g: CaptureGrid = _arena.grid
	if g.cell_at(_grid_cell.x, _grid_cell.y) != CaptureGrid.Cell.FREE:
		return true  # engulfed (pocket size 0)
	var main_seed: Vector2i = g._largest_free_component_seed()
	if main_seed.x < 0:
		return false  # no FREE region at all (board full) -> nothing to contain into
	var region: Dictionary = _flood_free_set(_grid_cell, g.cols * g.rows)  # Sparx's component
	if not region.has(main_seed):
		return true  # Sparx is in a smaller component than the main region -> sealed off
	return trap_pocket_max_cells > 0 and region.size() <= trap_pocket_max_cells  # tiny-pocket safety


## The set of FREE cells 4-connected to `start`, stopping once it exceeds `cap` (so a huge main
## region stays cheap). Empty if `start` isn't FREE. Used both to detect a small pocket and to
## exclude that pocket on re-emerge. Deterministic (fixed neighbour order, no RNG).
func _flood_free_set(start: Vector2i, cap: int) -> Dictionary:
	var g: CaptureGrid = _arena.grid
	var seen: Dictionary = {}
	if g.cell_at(start.x, start.y) != CaptureGrid.Cell.FREE:
		return seen
	seen[start] = true
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		if seen.size() > cap:  # region is bigger than a pocket -> stop expanding
			break
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = c + d
			if not seen.has(n) and g.cell_at(n.x, n.y) == CaptureGrid.Cell.FREE:
				seen[n] = true
				stack.append(n)
	return seen


## Classic right-hand wall-follow: keep the wall on the right (right -> front -> left), reversing
## ONLY at a true dead-end (right, front and left all walls). This traces a full loop around a
## free region and rounds convex corners (where the next cell is only diagonally wall-adjacent)
## instead of U-turning early. Starting on a wall keeps it edge-locked; it never free-floats.
func _next_edge_heading() -> Vector2i:
	var fr: bool = _edge_open(_grid_cell + EnemyMotion.turn_right(_heading))
	var ff: bool = _edge_open(_grid_cell + _heading)
	var fl: bool = _edge_open(_grid_cell + EnemyMotion.turn_left(_heading))
	return EnemyMotion.wall_follow_turn(_heading, fr, ff, fl)


## Walkable for edge-follow: anything that isn't a CAPTURED wall (FREE or the player's TRAIL).
func _edge_open(cell: Vector2i) -> bool:
	return _arena.cell_state(cell) != CaptureGrid.Cell.CAPTURED


## Re-emerge target: a WALKABLE perimeter cell of the MAIN (largest) FREE region that is at least
## safe_emerge_distance (Manhattan) from the player AND not next to the active trail -> anti-insta-
## kill. Among safe cells, the one nearest the contained position (`_grid_cell`) wins (deterministic
## Manhattan + row-major tie-break). If none is safe (tiny board), the FARTHEST-from-player cell is
## chosen instead. The pocket is a different component, so never selected. No-op only if no walkable
## border exists anywhere (board ~fully captured).
func _reproject_to_main(player_cell: Vector2i) -> void:
	var grid: CaptureGrid = _arena.grid
	var main_seed: Vector2i = grid._largest_free_component_seed()
	var region: Dictionary = {}
	if main_seed.x >= 0:
		region = _flood_free_set(main_seed, grid.cols * grid.rows)  # the main region
	var prox: Vector2i = _grid_cell  # contained position -> proximity tie-break
	var best := Vector2i(-1, -1)
	var best_d: int = 1 << 30
	var far_best := Vector2i(-1, -1)  # fallback: farthest from the player
	var far_d: int = -1
	for y in grid.rows:
		for x in grid.cols:
			if not region.is_empty() and not region.has(Vector2i(x, y)):
				continue
			if not _is_walkable_border(x, y) or _has_trail_neighbor(x, y):
				continue
			var dp: int = absi(x - player_cell.x) + absi(y - player_cell.y)
			if dp > far_d:  # track the safest available fallback (row-major first on ties)
				far_d = dp
				far_best = Vector2i(x, y)
			if dp < safe_emerge_distance:
				continue  # too close to the player for the primary pick
			var dprox: int = absi(x - prox.x) + absi(y - prox.y)
			if dprox < best_d:
				best_d = dprox
				best = Vector2i(x, y)
	var target: Vector2i = best if best.x >= 0 else far_best
	if target.x < 0:
		target = _nearest_walkable_border(player_cell, {})  # last resort (any walkable border)
	if target.x < 0:
		return  # no walkable border anywhere -> no-op (run ending)
	_grid_cell = target
	_step_from = _arena.cell_to_world(target)
	_step_to = _step_from
	position = _step_from
	_step_timer = 0.0
	_heading = _wall_follow_start_heading(target)


## True if any 4-neighbour of (x,y) is part of the player's active trail (avoid re-emerging on it).
func _has_trail_neighbor(x: int, y: int) -> bool:
	var g: CaptureGrid = _arena.grid
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if g.cell_at(x + d.x, y + d.y) == CaptureGrid.Cell.TRAIL:
			return true
	return false


## Nearest walkable border cell to `ref` (deterministic, row-major tie-break). When `only` is
## non-empty the search is restricted to that set (the player's region). Returns (-1,-1) if none.
func _nearest_walkable_border(ref: Vector2i, only: Dictionary) -> Vector2i:
	var grid: CaptureGrid = _arena.grid
	var best := Vector2i(-1, -1)
	var best_d: int = 1 << 30
	for y in grid.rows:
		for x in grid.cols:
			if not only.is_empty() and not only.has(Vector2i(x, y)):
				continue
			if not _is_walkable_border(x, y):
				continue
			var d: int = absi(x - ref.x) + absi(y - ref.y)
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
	return best


## A cell Sparx can actually patrol: FREE, touching at least one CAPTURED wall (something to hug)
## and with >= 2 open neighbours (a real edge, not an isolated cell or a dead-end spur that would
## make wall-follow ping-pong). cell_at treats out-of-bounds as CAPTURED (the arena frame).
func _is_walkable_border(x: int, y: int) -> bool:
	var g: CaptureGrid = _arena.grid
	if g.cell_at(x, y) != CaptureGrid.Cell.FREE:
		return false
	var walls: int = 0
	var open: int = 0
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if g.cell_at(x + d.x, y + d.y) == CaptureGrid.Cell.CAPTURED:
			walls += 1
		else:
			open += 1
	return walls >= 1 and open >= 2


## A start heading from `cell` that steps ALONG the edge: front open, border-adjacent, and a wall
## on the right (canonical right-hand follow). Falls back to any open border-adjacent front, then
## any open front. Deterministic direction order -> daily/ghost reproduce.
func _wall_follow_start_heading(cell: Vector2i) -> Vector2i:
	var dirs: Array[Vector2i] = [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]
	for h in dirs:
		var n: Vector2i = cell + h
		if _edge_open(n) and _has_captured_neighbor(n.x, n.y) \
				and _arena.cell_state(cell + EnemyMotion.turn_right(h)) == CaptureGrid.Cell.CAPTURED:
			return h
	for h in dirs:
		var n: Vector2i = cell + h
		if _edge_open(n) and _has_captured_neighbor(n.x, n.y):
			return h
	return Vector2i.DOWN


func _has_captured_neighbor(x: int, y: int) -> bool:
	var g: CaptureGrid = _arena.grid
	return g.cell_at(x + 1, y) == CaptureGrid.Cell.CAPTURED \
		or g.cell_at(x - 1, y) == CaptureGrid.Cell.CAPTURED \
		or g.cell_at(x, y + 1) == CaptureGrid.Cell.CAPTURED \
		or g.cell_at(x, y - 1) == CaptureGrid.Cell.CAPTURED


## Sub-stepped movement so a fast enemy cannot tunnel through a 1-cell trail/wall.
func _move(delta: float) -> void:
	if _velocity == Vector2.ZERO:
		return
	var remaining: float = _velocity.length() * _speed_scale * run_speed_scale * delta
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
	if _telegraph_timer > 0.0:  # re-emerge warning: blink (non-lethal window)
		draw_color.a *= 0.3 + 0.7 * absf(sin(_telegraph_timer * 26.0))
	if shape == Shape.TRIANGLE:
		var pts := PackedVector2Array([
			Vector2(0, -radius),
			Vector2(-radius * 0.866, radius * 0.5),
			Vector2(radius * 0.866, radius * 0.5),
		])
		draw_colored_polygon(pts, draw_color)
	elif shape == Shape.SQUARE:
		draw_rect(Rect2(-radius, -radius, radius * 2.0, radius * 2.0), draw_color)
	else:
		draw_circle(Vector2.ZERO, radius, draw_color)
