extends GutTest

const LoginStreak = preload("res://scripts/meta/login_streak.gd")

const TABLE: Array = [50, 75, 100, 125, 150, 200, 300]


func test_first_ever_login() -> void:
	var r := LoginStreak.evaluate(100, -1, 0, TABLE)
	assert_true(r["claimable"])
	assert_eq(r["new_streak"], 1)
	assert_eq(r["reward"], 50)


func test_same_day_not_claimable() -> void:
	var r := LoginStreak.evaluate(100, 100, 3, TABLE)
	assert_false(r["claimable"], "aynı gün ikinci kez yok")
	assert_eq(r["reward"], 0)
	assert_eq(r["new_streak"], 3, "streak korunur")


func test_consecutive_day_increments() -> void:
	var r := LoginStreak.evaluate(101, 100, 3, TABLE)
	assert_true(r["claimable"])
	assert_eq(r["new_streak"], 4)
	assert_eq(r["reward"], 125)


func test_missed_day_resets() -> void:
	var r := LoginStreak.evaluate(105, 100, 5, TABLE)  # 4-gün boşluk
	assert_true(r["claimable"])
	assert_eq(r["new_streak"], 1, "kaçırma sıfırlar")
	assert_eq(r["reward"], 50)


func test_seven_loops_to_one() -> void:
	# Gün 7'deyken ardışık giriş -> gün 1'e döner (loop)
	var r := LoginStreak.evaluate(101, 100, 7, TABLE)
	assert_eq(r["new_streak"], 1)
	assert_eq(r["reward"], 50)


func test_reward_matches_streak() -> void:
	# streak 5'ten 6'ya
	var r := LoginStreak.evaluate(101, 100, 5, TABLE)
	assert_eq(r["new_streak"], 6)
	assert_eq(r["reward"], 200)


func test_clock_back_treated_as_miss() -> void:
	var r := LoginStreak.evaluate(98, 100, 4, TABLE)  # today < last
	assert_eq(r["new_streak"], 1)
