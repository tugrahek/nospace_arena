extends GutTest

# enemy_motion.gd is dependency-free, so it's safe under GUT's isolated loader.
const EnemyMotion = preload("res://scripts/gameplay/enemy_motion.gd")


func test_reflect_x() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), true, false), Vector2(-3, 4))


func test_reflect_y() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), false, true), Vector2(3, -4))


func test_reflect_both() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), true, true), Vector2(-3, -4))


func test_reflect_none() -> void:
	assert_eq(EnemyMotion.reflect(Vector2(3, 4), false, false), Vector2(3, 4))


func test_start_velocity_magnitude() -> void:
	assert_almost_eq(EnemyMotion.start_velocity(0, 100.0).length(), 100.0, 0.001)


func test_start_velocity_varies_by_index() -> void:
	assert_ne(EnemyMotion.start_velocity(0, 100.0), EnemyMotion.start_velocity(1, 100.0))


func test_start_velocity_deterministic() -> void:
	assert_eq(EnemyMotion.start_velocity(2, 100.0), EnemyMotion.start_velocity(2, 100.0))


func test_spawn_offset_single_is_zero() -> void:
	assert_eq(EnemyMotion.spawn_offset(0, 1, 30.0), Vector2.ZERO)


func test_spawn_offset_two_are_opposite() -> void:
	var a: Vector2 = EnemyMotion.spawn_offset(0, 2, 30.0)
	var b: Vector2 = EnemyMotion.spawn_offset(1, 2, 30.0)
	assert_almost_eq(a.length(), 30.0, 0.001, "on the ring")
	assert_almost_eq((a + b).length(), 0.0, 0.001, "two enemies spawn on opposite sides")


func test_spawn_offset_deterministic() -> void:
	assert_eq(EnemyMotion.spawn_offset(1, 3, 30.0), EnemyMotion.spawn_offset(1, 3, 30.0))


func test_edge_start_row_single_is_one() -> void:
	assert_eq(EnemyMotion.edge_start_row(0, 1, 94), 1)


func test_edge_start_row_two_are_far_apart() -> void:
	var a: int = EnemyMotion.edge_start_row(0, 2, 94)
	var b: int = EnemyMotion.edge_start_row(1, 2, 94)
	assert_eq(a, 1)
	assert_gt(b - a, 20, "two sparx start far apart on the loop, not adjacent")
	assert_true(b <= 94, "within bounds")


# --- clamp_to_wall (radius-aware bounce: body never overlaps captured) ---

func test_clamp_positive_pulls_body_off_wall() -> void:
	# Moving +, center 92, wall 100, radius 9 -> clamp to 91 (body edge exactly at wall)
	assert_almost_eq(EnemyMotion.clamp_to_wall(92.0, 100.0, 9.0, 1.0), 91.0, 0.0001)


func test_clamp_positive_leaves_safe_center() -> void:
	# Already > radius from wall -> unchanged
	assert_eq(EnemyMotion.clamp_to_wall(50.0, 100.0, 9.0, 1.0), 50.0)


func test_clamp_negative_pulls_body_off_wall() -> void:
	# Moving -, center 22, wall 20, radius 9 -> clamp to 29
	assert_almost_eq(EnemyMotion.clamp_to_wall(22.0, 20.0, 9.0, -1.0), 29.0, 0.0001)


func test_clamp_negative_leaves_safe_center() -> void:
	assert_eq(EnemyMotion.clamp_to_wall(80.0, 20.0, 9.0, -1.0), 80.0)


func test_clamp_guarantees_radius_gap() -> void:
	# After clamp, center-to-wall distance is at least radius (body doesn't overlap)
	var c: float = EnemyMotion.clamp_to_wall(98.0, 100.0, 9.0, 1.0)
	assert_true(100.0 - c >= 9.0, "gövde duvara binmemeli")


# --- Directional post-bounce recovery (chaser homing regression fix) ---

func test_peel_adjust_pure_into_wall_keeps_reflected() -> void:
	var e := Enemy.new()
	add_child_autofree(e)
	e.set("_recovery_normal", Vector2(-1, 0))  # wall on +x, outward -x
	e.set("_velocity", Vector2(-5, 0))         # reflected (peel) heading
	# Homing straight into the wall (+x) -> keep the reflected heading (peel), no pin.
	assert_eq(e.call("_peel_adjust", Vector2(10, 0)), Vector2(-5, 0))


func test_peel_adjust_slides_tangential() -> void:
	var e := Enemy.new()
	add_child_autofree(e)
	e.set("_recovery_normal", Vector2(-1, 0))
	var v: Vector2 = e.call("_peel_adjust", Vector2(10, 5))  # into wall (+x) + tangential (+y)
	assert_almost_eq(v.x, 0.0, 0.01, "inward x removed")
	assert_gt(v.y, 0.0, "tangential kept -> slides along the wall toward target")
	assert_almost_eq(v.length(), Vector2(10, 5).length(), 0.01, "speed preserved")


func test_peel_adjust_away_homes_freely() -> void:
	var e := Enemy.new()
	add_child_autofree(e)
	e.set("_recovery_normal", Vector2(-1, 0))
	assert_eq(e.call("_peel_adjust", Vector2(-10, 3)), Vector2(-10, 3), "away from wall -> unchanged")


func test_chaser_homes_during_recovery_not_circling() -> void:
	# Exposed player beyond a wall on +x: with recovery active the chaser must still home (along
	# the wall), not drift on its reflected heading (the old blanket-suppression regression).
	var arena := ArenaController.new()
	add_child_autofree(arena)
	arena.configure(load("res://resources/arenas/arena_frost.tres"), Rect2(40, 100, 640, 1100))
	GameState.start_run(3)
	var e := Enemy.new()
	add_child_autofree(e)
	e.setup(arena, arena.cell_to_world(Vector2i(5, 5)), Vector2(-100, 0), ChaserBehavior.new(), 100.0)
	e.set("_recovery_timer", 0.18)
	e.set("_recovery_normal", Vector2(-1, 0))  # just bounced off a +x wall
	var into_wall_player: Vector2 = e.position + Vector2(60, 60)  # +x (behind wall) and +y
	var v: Vector2 = e.decide_velocity(into_wall_player, true)
	assert_lt(v.x, 1.0, "does not home straight into the wall")
	assert_gt(v.y, 0.0, "homes tangentially toward the player (no edge-circling)")
	# Player NOT behind the wall -> homes freely (component toward -x).
	var open_player: Vector2 = e.position + Vector2(-60, 60)
	assert_lt(e.decide_velocity(open_player, true).x, 0.0, "free homing when not into the wall")
	GameState.reset()
