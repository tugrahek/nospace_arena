extends GutTest

const Leaderboard = preload("res://scripts/meta/leaderboard.gd")
const LeaderboardStore = preload("res://scripts/meta/leaderboard_store.gd")

var _temporary_paths: Array[String] = []


func after_each() -> void:
	for path: String in _temporary_paths:
		DirAccess.remove_absolute(path)
	_temporary_paths.clear()


func test_submit_first_is_best() -> void:
	var lb := Leaderboard.new()
	assert_true(lb.submit(20260616, 100))
	assert_eq(lb.best_score(20260616), 100)


func test_lower_score_rejected() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100)
	assert_false(lb.submit(20260616, 50))
	assert_eq(lb.best_score(20260616), 100)


func test_higher_score_replaces() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100)
	assert_true(lb.submit(20260616, 150))
	assert_eq(lb.best_score(20260616), 150)


func test_tie_is_not_new_best() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100)
	assert_false(lb.submit(20260616, 100), "eşit yeni best değil")


func test_unknown_date_score_is_minus_one() -> void:
	var lb := Leaderboard.new()
	assert_eq(lb.best_score(19990101), -1)


func test_dates_are_independent() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100)
	lb.submit(20260617, 50)
	assert_eq(lb.best_score(20260616), 100)
	assert_eq(lb.best_score(20260617), 50)


func test_scores_returns_date_to_score() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100)
	lb.submit(20260617, 50)
	var s := lb.scores()
	assert_eq(s.size(), 2)
	assert_eq(int(s[20260616]), 100)
	assert_eq(int(s[20260617]), 50)


func test_best_ever_is_max_or_minus_one() -> void:
	var lb := Leaderboard.new()
	assert_eq(lb.best_ever(), -1, "no entries -> -1")
	lb.submit(20260616, 100)
	lb.submit(20260617, 175)
	lb.submit(20260618, 60)
	assert_eq(lb.best_ever(), 175)


func test_dict_round_trip() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 120)
	lb.submit(20260617, 80)
	var restored := Leaderboard.from_dict(lb.to_dict())
	assert_eq(restored.best_score(20260616), 120)
	assert_eq(restored.best_score(20260617), 80)


func test_legacy_tracks_are_ignored_without_losing_any_historical_scores() -> void:
	var legacy: Dictionary = {}
	for day: int in range(1, 9):
		legacy[str(20260600 + day)] = {"score": day * 100, "track": [[1, 2], [3, 4]]}
	legacy["20260609"] = {"score": 900, "track": "obsolete malformed track"}
	var original: Dictionary = legacy.duplicate(true)
	var board: Leaderboard = Leaderboard.from_dict(legacy)
	assert_eq(board.scores().size(), 9)
	assert_eq(board.best_ever(), 900)
	for day: int in range(1, 10):
		assert_eq(board.best_score(20260600 + day), day * 100)
		assert_eq(board.to_dict()[str(20260600 + day)], {"score": day * 100})
	assert_eq(legacy, original, "loading never mutates caller-owned legacy data")
	assert_false(board.submit(20260609, 900), "ties still preserve the historical best")
	assert_false(board.submit(20260609, 899), "lower score is still rejected")


func test_legacy_save_round_trip_writes_only_scores_and_keeps_all_dates() -> void:
	var path: String = "user://test_step31_leaderboard_%d.json" % Time.get_ticks_usec()
	_temporary_paths.append(path)
	var legacy: Dictionary = {"20260601": {"score": 700, "track": [[1, 2]]},
		"20260602": {"score": 100, "track": null}, "20260603": {"score": 300}}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var board: Leaderboard = LeaderboardStore.load_from(path)
	assert_eq(board.best_score(20260601), 700)
	assert_true(board.submit(20260602, 200))
	LeaderboardStore.save_to(path, board)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(saved, {"20260601": {"score": 700.0}, "20260602": {"score": 200.0}, "20260603": {"score": 300.0}})
	assert_eq(LeaderboardStore.load_from(path).scores(), board.scores())
