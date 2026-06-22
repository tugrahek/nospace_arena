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


## True while the enemy's behavior decision should be suppressed (keep the current,
## reflected heading): during a contact freeze and the short recovery window after it,
## so a homing enemy peels off the wall instead of camping + re-freezing. Pure.
static func is_behavior_suppressed(freeze_timer: float, recovery_timer: float) -> bool:
	return freeze_timer > 0.0 or recovery_timer > 0.0


## Clamps a 1-D center coordinate so a body of `body_radius` stays on the near side
## of a wall face at `wall`. moving_sign = +1 (approaching from the low side) or
## -1 (from the high side). Guarantees |result - wall| >= body_radius on that side,
## so the body never overlaps the wall. Pure geometry — deterministic.
static func clamp_to_wall(center: float, wall: float, body_radius: float, moving_sign: float) -> float:
	if moving_sign > 0.0:
		return minf(center, wall - body_radius)
	return maxf(center, wall + body_radius)


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
