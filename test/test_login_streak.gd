extends GutTest

const LoginStreak = preload("res://scripts/meta/login_streak.gd")

const TABLE: Array = [50, 75, 0, 180, 0, 225, 0, 250, 275, 0]


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
	assert_eq(r["reward"], 180)


func test_missed_day_resets() -> void:
	var r := LoginStreak.evaluate(105, 100, 5, TABLE)  # 4-gün boşluk
	assert_true(r["claimable"])
	assert_eq(r["new_streak"], 1, "kaçırma sıfırlar")
	assert_eq(r["reward"], 50)


func test_legacy_day_seven_advances_to_day_eight() -> void:
	# Legacy seven-day saves advance into the new Day 8 reward.
	var r := LoginStreak.evaluate(101, 100, 7, TABLE)
	assert_eq(r["new_streak"], 8)
	assert_eq(r["reward"], 250)


func test_ten_loops_to_one() -> void:
	var wrapped := LoginStreak.evaluate(101, 100, 10, TABLE)
	assert_eq(wrapped["new_streak"], 1)
	assert_eq(wrapped["reward"], 50)


func test_reward_matches_streak() -> void:
	# streak 5'ten 6'ya
	var r := LoginStreak.evaluate(101, 100, 5, TABLE)
	assert_eq(r["new_streak"], 6)
	assert_eq(r["reward"], 225)


func test_clock_back_treated_as_miss() -> void:
	var r := LoginStreak.evaluate(98, 100, 4, TABLE)  # today < last
	assert_eq(r["new_streak"], 1)
