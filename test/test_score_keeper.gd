extends GutTest

const ScoreKeeper = preload("res://scripts/meta/score_keeper.gd")


func test_single_capture_score() -> void:
	var sk: ScoreKeeper = ScoreKeeper.new()
	sk.base_points = 10
	var earned: int = sk.register_capture(5, 0.0)
	assert_eq(earned, 50, "5 cells * 10 pts * x1 = 50")
	assert_eq(sk.score, 50)


func test_combo_multiplier_increases() -> void:
	var sk: ScoreKeeper = ScoreKeeper.new()
	sk.base_points = 10
	sk.combo_window = 2.0
	sk.register_capture(1, 0.0)  # combo=0, x1 -> 10
	sk.register_capture(1, 1.0)  # combo=1, x2 -> 20
	var earned: int = sk.register_capture(1, 2.0)  # combo=2, x3 -> 30
	assert_eq(earned, 30)
	assert_eq(sk.combo, 2)


func test_combo_resets_after_window_expires() -> void:
	var sk: ScoreKeeper = ScoreKeeper.new()
	sk.base_points = 10
	sk.combo_window = 1.0
	sk.register_capture(1, 0.0)  # combo=0
	var earned: int = sk.register_capture(1, 5.0)  # 4s gap > window -> combo resets to 0
	assert_eq(earned, 10, "no combo after window expires")
	assert_eq(sk.combo, 0)


func test_reset_clears_all_state() -> void:
	var sk: ScoreKeeper = ScoreKeeper.new()
	sk.base_points = 10
	sk.combo_window = 2.0
	sk.register_capture(3, 0.0)
	sk.register_capture(3, 1.0)  # combo=1 now
	sk.reset()
	assert_eq(sk.score, 0)
	assert_eq(sk.combo, 0)
	# After reset, next capture must treat combo as fresh (window expired)
	var earned: int = sk.register_capture(1, 1.5)
	assert_eq(earned, 10, "x1 multiplier after reset")
	assert_eq(sk.combo, 0)


func test_deterministic_same_inputs_same_result() -> void:
	var sk1: ScoreKeeper = ScoreKeeper.new()
	var sk2: ScoreKeeper = ScoreKeeper.new()
	sk1.base_points = 15
	sk2.base_points = 15
	sk1.combo_window = 3.0
	sk2.combo_window = 3.0
	sk1.register_capture(4, 0.0)
	sk1.register_capture(4, 1.0)
	sk2.register_capture(4, 0.0)
	sk2.register_capture(4, 1.0)
	assert_eq(sk1.score, sk2.score)
	assert_eq(sk1.combo, sk2.combo)
