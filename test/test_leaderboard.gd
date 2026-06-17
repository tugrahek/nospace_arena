extends GutTest

const Leaderboard = preload("res://scripts/meta/leaderboard.gd")
const GhostTrack = preload("res://scripts/meta/ghost_track.gd")


func _track(x: float) -> GhostTrack:
	var t := GhostTrack.new()
	t.add_sample(Vector2(x, x))
	return t


func test_submit_first_is_best() -> void:
	var lb := Leaderboard.new()
	assert_true(lb.submit(20260616, 100, _track(1)))
	assert_eq(lb.best_score(20260616), 100)


func test_lower_score_rejected() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100, _track(1))
	assert_false(lb.submit(20260616, 50, _track(2)))
	assert_eq(lb.best_score(20260616), 100)


func test_higher_score_replaces() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100, _track(1))
	assert_true(lb.submit(20260616, 150, _track(2)))
	assert_eq(lb.best_score(20260616), 150)


func test_tie_is_not_new_best() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100, _track(1))
	assert_false(lb.submit(20260616, 100, _track(2)), "eşit yeni best değil")


func test_unknown_date_score_is_minus_one() -> void:
	var lb := Leaderboard.new()
	assert_eq(lb.best_score(19990101), -1)
	assert_null(lb.best_track(19990101))


func test_best_track_returned() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100, _track(7))
	var bt := lb.best_track(20260616)
	assert_not_null(bt)
	assert_eq(bt.position_at_frame(0), Vector2(7, 7))


func test_dates_are_independent() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 100, _track(1))
	lb.submit(20260617, 50, _track(2))
	assert_eq(lb.best_score(20260616), 100)
	assert_eq(lb.best_score(20260617), 50)


func test_prune_keeps_recent_tracks_only() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260615, 10, _track(1))
	lb.submit(20260616, 20, _track(2))
	lb.submit(20260617, 30, _track(3))
	lb.prune_tracks(2)  # keep tracks for the 2 newest dates
	assert_true(lb.best_track(20260615).is_empty(), "eski track budandı")
	assert_false(lb.best_track(20260616).is_empty())
	assert_false(lb.best_track(20260617).is_empty())
	# Scores are always retained.
	assert_eq(lb.best_score(20260615), 10)


func test_dict_round_trip() -> void:
	var lb := Leaderboard.new()
	lb.submit(20260616, 120, _track(3))
	lb.submit(20260617, 80, _track(4))
	var restored := Leaderboard.from_dict(lb.to_dict())
	assert_eq(restored.best_score(20260616), 120)
	assert_eq(restored.best_score(20260617), 80)
	assert_eq(restored.best_track(20260616).position_at_frame(0), Vector2(3, 3))
