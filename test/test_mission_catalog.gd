extends GutTest

const MissionCatalog = preload("res://scripts/meta/mission_catalog.gd")


func test_picks_requested_count() -> void:
	var picks := MissionCatalog.pick_daily(6, 20260616, 3)
	assert_eq(picks.size(), 3)


func test_picks_are_distinct() -> void:
	var picks := MissionCatalog.pick_daily(6, 20260616, 3)
	var seen := {}
	for i in picks:
		assert_false(seen.has(i), "tekrar yok")
		seen[i] = true


func test_picks_in_range() -> void:
	var picks := MissionCatalog.pick_daily(6, 20260616, 3)
	for i in picks:
		assert_true(i >= 0 and i < 6)


func test_deterministic() -> void:
	assert_eq(
		MissionCatalog.pick_daily(6, 20260616, 3),
		MissionCatalog.pick_daily(6, 20260616, 3)
	)


func test_count_clamped_to_pool() -> void:
	var picks := MissionCatalog.pick_daily(2, 20260616, 3)
	assert_eq(picks.size(), 2)


func test_empty_pool() -> void:
	assert_eq(MissionCatalog.pick_daily(0, 20260616, 3).size(), 0)
