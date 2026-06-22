extends GutTest

## Pure enemy motion math (EnemyMotion). Here: even_spread used for per-enemy variation.

const EnemyMotion = preload("res://scripts/gameplay/enemy_motion.gd")


func test_even_spread_single_is_zero() -> void:
	assert_eq(EnemyMotion.even_spread(0, 1), 0.0)


func test_even_spread_three_spans_minus_one_to_one() -> void:
	assert_almost_eq(EnemyMotion.even_spread(0, 3), -1.0, 0.0001)
	assert_almost_eq(EnemyMotion.even_spread(1, 3), 0.0, 0.0001)
	assert_almost_eq(EnemyMotion.even_spread(2, 3), 1.0, 0.0001)


func test_even_spread_values_are_distinct() -> void:
	var seen := {}
	for i in 5:
		var v: float = EnemyMotion.even_spread(i, 5)
		assert_false(seen.has(v), "each index -> distinct variation")
		seen[v] = true
