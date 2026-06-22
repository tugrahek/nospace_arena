extends GutTest

# Behaviors are pure (Vector2/float/bool only), safe to preload under GUT's isolated loader.
const EnemyBehavior = preload("res://scripts/gameplay/enemy_behavior.gd")
const BouncerBehavior = preload("res://scripts/gameplay/bouncer_behavior.gd")
const ChaserBehavior = preload("res://scripts/gameplay/chaser_behavior.gd")


func test_base_behavior_is_identity() -> void:
	var v := Vector2(3, 4)
	assert_eq(EnemyBehavior.new().decide(v, Vector2(1, 1), Vector2(9, 9), true, 100.0), v)


func test_bouncer_ignores_player_state() -> void:
	var v := Vector2(-5, 2)
	# Same result whether the player is exposed or safe.
	assert_eq(BouncerBehavior.new().decide(v, Vector2(10, 10), Vector2(99, 0), true, 100.0), v)
	assert_eq(BouncerBehavior.new().decide(v, Vector2(10, 10), Vector2(99, 0), false, 100.0), v)


func test_chaser_roams_when_player_safe() -> void:
	# Not exposed -> keep current velocity (roam like a bouncer), no homing.
	var v := Vector2(7, -3)
	assert_eq(ChaserBehavior.new().decide(v, Vector2(0, 0), Vector2(200, 0), false, 100.0), v)


func test_chaser_homes_when_player_exposed() -> void:
	# Exposed -> head straight to the player at base speed.
	var out: Vector2 = ChaserBehavior.new().decide(Vector2(0, 1), Vector2(0, 0), Vector2(10, 0), true, 100.0)
	assert_almost_eq(out.length(), 100.0, 0.001)
	assert_gt(out.x, 0.0, "oyuncuya doğru (+x)")
	assert_almost_eq(out.y, 0.0, 0.001)


func test_chaser_same_position_keeps_velocity() -> void:
	var v := Vector2(7, 0)
	assert_eq(ChaserBehavior.new().decide(v, Vector2(5, 5), Vector2(5, 5), true, 100.0), v)


func test_chaser_is_deterministic() -> void:
	var a: Vector2 = ChaserBehavior.new().decide(Vector2(1, 0), Vector2(2, 3), Vector2(8, 9), true, 60.0)
	var b: Vector2 = ChaserBehavior.new().decide(Vector2(1, 0), Vector2(2, 3), Vector2(8, 9), true, 60.0)
	assert_eq(a, b)


func test_chaser_variation_zero_is_straight() -> void:
	# variation 0 (default) must match the legacy straight-homing behavior.
	var ch := ChaserBehavior.new()
	var out: Vector2 = ch.decide(Vector2(0, 1), Vector2(0, 0), Vector2(10, 0), true, 100.0, 0.0)
	assert_almost_eq(out.y, 0.0, 0.001, "no offset at variation 0")
	assert_gt(out.x, 0.0)


func test_chaser_variation_offsets_angle() -> void:
	var ch := ChaserBehavior.new()
	ch.spread_rad = 0.5
	# Player straight to the right; +variation and -variation tilt the approach opposite ways.
	var pos: Vector2 = ChaserBehavior.new().decide(Vector2(0, 1), Vector2(0, 0), Vector2(10, 0), true, 100.0, 1.0)
	var neg: Vector2 = ChaserBehavior.new().decide(Vector2(0, 1), Vector2(0, 0), Vector2(10, 0), true, 100.0, -1.0)
	assert_almost_eq(pos.length(), 100.0, 0.001, "speed preserved")
	assert_ne(pos.y, 0.0, "offset tilts the heading")
	assert_true((pos.y > 0.0) != (neg.y > 0.0), "opposite variations tilt opposite ways")


func test_chaser_variation_ignored_when_safe() -> void:
	var v := Vector2(7, -3)
	assert_eq(ChaserBehavior.new().decide(v, Vector2(0, 0), Vector2(200, 0), false, 100.0, 1.0), v)
