class_name EnemyMotion
extends RefCounted

## Pure motion math for enemies — no scene / grid dependencies, fully testable.


## Reflects velocity on the blocked axes (wall bounce).
static func reflect(velocity: Vector2, block_x: bool, block_y: bool) -> Vector2:
	var v: Vector2 = velocity
	if block_x:
		v.x = -v.x
	if block_y:
		v.y = -v.y
	return v


## Clamps a 1-D center coordinate so a body of `body_radius` stays on the near side
## of a wall face at `wall`. moving_sign = +1 (approaching from the low side) or
## -1 (from the high side). Guarantees |result - wall| >= body_radius on that side,
## so the body never overlaps the wall. Pure geometry — deterministic.
static func clamp_to_wall(center: float, wall: float, body_radius: float, moving_sign: float) -> float:
	if moving_sign > 0.0:
		return minf(center, wall - body_radius)
	return maxf(center, wall + body_radius)


## True when the straight grid line from `from` to `to` crosses no `blocked` cell (integer
## Bresenham over a raw row-major cell buffer — the grid's read-only view). Endpoints are never
## treated as blockers: the walker stands on its own cell and the target cell is the goal.
## Used by sight-based behaviors (Chaser) so they lose track of a player behind captured
## territory instead of pinning themselves against it. Pure + deterministic (no RNG, ints only).
static func line_of_sight(cells: PackedByteArray, cols: int, from: Vector2i, to: Vector2i, blocked: int) -> bool:
	if cols <= 0 or cells.is_empty():
		return true  # no grid knowledge -> behave as before (always sighted)
	var rows: int = cells.size() / cols
	var dx: int = absi(to.x - from.x)
	var dy: int = -absi(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx + dy
	var x: int = from.x
	var y: int = from.y
	while x != to.x or y != to.y:
		var e2: int = err * 2
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		if x == to.x and y == to.y:
			break  # target cell itself is the goal, not a blocker
		if x < 0 or y < 0 or x >= cols or y >= rows:
			return false  # left the board: nothing to see through
		if cells[y * cols + x] == blocked:
			return false
	return true


## Nudges a roaming velocity off a near-axis-aligned heading into a deterministic diagonal derived
## from `variation` (no RNG) and re-normalizes to `base_speed`. Roam keeps whatever heading the
## enemy last had (a wall reflection, a peel result, ...), which can end up perfectly axis-aligned
## between two walls and ping-pong there forever (device finding B7, fix-pass #20). `axis_lock_ratio`
## is the per-axis speed fraction below which that axis counts as "locked" (<= 0 disables the nudge
## -- returns `velocity` unchanged). Already-diagonal input (both axes above the ratio) is untouched.
static func unstick_axis(velocity: Vector2, base_speed: float, variation: float, axis_lock_ratio: float) -> Vector2:
	if base_speed <= 0.0 or axis_lock_ratio <= 0.0:
		return velocity
	var speed: float = velocity.length()
	if speed < 0.001:
		return Vector2(1.0, 1.0).normalized() * base_speed  # no heading at all -> pick a diagonal
	if absf(velocity.x) / speed > axis_lock_ratio and absf(velocity.y) / speed > axis_lock_ratio:
		return velocity  # already has a real component on both axes -> leave it
	var qx: float = 1.0 if velocity.x > 0.0 else (-1.0 if velocity.x < 0.0 else (1.0 if variation >= 0.0 else -1.0))
	var qy: float = 1.0 if velocity.y > 0.0 else (-1.0 if velocity.y < 0.0 else (1.0 if variation >= 0.0 else -1.0))
	return Vector2(qx, qy).normalized() * base_speed


## Deterministic starting velocity for enemy `index` at `speed` (no RNG).
## Varies direction per index so multiple enemies diverge (free-play default).
static func start_velocity(index: int, speed: float) -> Vector2:
	var dirs: Array[Vector2] = [
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1),
	]
	return dirs[index % dirs.size()].normalized() * speed


## Starting velocity from a seed-derived direction index (0..3) — daily mode picks the
## direction from the daily seed so the layout is the same for everyone that day.
static func start_velocity_seeded(dir_index: int, speed: float) -> Vector2:
	return start_velocity(dir_index, speed)


## Evenly spreads `index` of `total` across [-1, 1] (single item -> 0). Used to give each
## enemy of a type a distinct variation so multiple chasers don't home onto the exact same
## point. Deterministic (no RNG) -> daily/ghost reproduce intact.
static func even_spread(index: int, total: int) -> float:
	if total <= 1:
		return 0.0
	return float(index) / float(total - 1) * 2.0 - 1.0


## Deterministic spawn offset so `total` enemies don't stack on the arena center: evenly spaced on
## a ring by index (2 -> opposite sides, 3 -> triangle, ...). Single enemy -> no offset. No RNG.
static func spawn_offset(index: int, total: int, radius: float) -> Vector2:
	if total <= 1:
		return Vector2.ZERO
	var ang: float = TAU * float(index) / float(total)
	return Vector2(cos(ang), sin(ang)) * radius


## Edge-walker (Sparx) start row on the left border, spread across [1, max_row] by index so multiple
## patrol far apart on the loop instead of trailing 1 cell apart. Single -> row 1. Deterministic.
static func edge_start_row(index: int, total: int, max_row: int) -> int:
	if total <= 1:
		return 1
	return clampi(1 + index * int(max_row / total), 1, max_row)


## 90° rotations of a cardinal grid direction (screen space, y-down).
static func turn_right(dir: Vector2i) -> Vector2i:
	return Vector2i(-dir.y, dir.x)


static func turn_left(dir: Vector2i) -> Vector2i:
	return Vector2i(dir.y, -dir.x)


## Right-hand wall-follow next heading (Sparx): keep the wall (CAPTURED) on the right by
## preferring right -> forward -> left -> back, taking the first OPEN direction. `free_*` is
## true when the cell that way is walkable (not a wall). Pure / deterministic -> ghost-safe.
static func wall_follow_turn(heading: Vector2i, free_right: bool, free_front: bool, free_left: bool) -> Vector2i:
	if free_right:
		return turn_right(heading)
	if free_front:
		return heading
	if free_left:
		return turn_left(heading)
	return -heading
