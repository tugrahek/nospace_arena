extends GutTest

# daily_seed.gd is pure integer math, safe to preload.
const DailySeed = preload("res://scripts/meta/daily_seed.gd")


func test_seed_for_date_golden() -> void:
	assert_eq(DailySeed.seed_for_date(2026, 6, 16), 20260616)


func test_derive_is_deterministic() -> void:
	assert_eq(DailySeed.derive(20260616, 1), DailySeed.derive(20260616, 1))


func test_derive_differs_by_salt() -> void:
	assert_ne(DailySeed.derive(20260616, 1), DailySeed.derive(20260616, 2))


func test_derive_stays_in_32_bits() -> void:
	var h: int = DailySeed.derive(20260616, 1)
	assert_true(h >= 0 and h <= 0xFFFFFFFF, "32-bit maskeli, işaretsiz")


func test_to_index_in_range() -> void:
	for s in [20260616, 20260617, 19991231, 1]:
		var i: int = DailySeed.to_index(s, 1, 3)
		assert_true(i >= 0 and i < 3, "0..2 aralığında")


func test_to_index_count_guard() -> void:
	assert_eq(DailySeed.to_index(20260616, 1, 0), 0)


func test_to_index_is_deterministic() -> void:
	assert_eq(DailySeed.to_index(20260616, 1, 3), DailySeed.to_index(20260616, 1, 3))


func test_dir_index_in_range() -> void:
	for i in 4:
		var d: int = DailySeed.dir_index(20260616, i)
		assert_true(d >= 0 and d < 4, "0..3 aralığında")


func test_dir_index_is_deterministic() -> void:
	assert_eq(DailySeed.dir_index(20260616, 0), DailySeed.dir_index(20260616, 0))


func test_different_dates_produce_different_seed() -> void:
	assert_ne(DailySeed.seed_for_date(2026, 6, 16), DailySeed.seed_for_date(2026, 6, 17))
	assert_ne(DailySeed.derive(20260616, 1), DailySeed.derive(20260617, 1))


func test_golden_values_for_known_seed() -> void:
	# Regression lock for seed 20260616 (2026-06-16): pins the exact hash outputs so a
	# future change to derive() that would break daily reproducibility is caught.
	assert_eq(DailySeed.to_index(20260616, ARENA_SALT, 3), 0, "arena index")
	assert_eq(DailySeed.to_index(20260616, CHAR_SALT, 3), 0, "character index")
	assert_eq(DailySeed.dir_index(20260616, 0), 2, "enemy 0 dir")
	assert_eq(DailySeed.dir_index(20260616, 1), 0, "enemy 1 dir")


const ARENA_SALT: int = 1
const CHAR_SALT: int = 2


func test_date_string_golden() -> void:
	assert_eq(DailySeed.date_string(20260616), "2026-06-16")
	assert_eq(DailySeed.date_string(20260101), "2026-01-01")
