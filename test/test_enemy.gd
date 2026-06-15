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
