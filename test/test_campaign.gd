extends GutTest

## Step 21a: Campaign logic layer — star computation, unlock derivation, boost policy branch,
## SaveData persistence, and the authored level catalog. No UI, no game wiring (that is 21b).

const SaveData = preload("res://scripts/meta/save_data.gd")


func _level(target: float, s2: int, s3: float) -> LevelData:
	var l := LevelData.new()
	l.id = &"t"
	l.target_percent = target
	l.star2_score = s2
	l.star3_percent = s3
	return l


# --- Star computation ---

func test_star_zero_when_failed() -> void:
	var l := _level(60.0, 500, 75.0)
	assert_eq(CampaignStars.star_for(false, 9999, 99.0, l), 0, "not reached -> 0 stars")


func test_star_one_on_clear() -> void:
	var l := _level(60.0, 500, 75.0)
	assert_eq(CampaignStars.star_for(true, 100, 60.0, l), 1, "cleared, thresholds unmet -> 1")


func test_star_two_on_score() -> void:
	var l := _level(60.0, 500, 75.0)
	assert_eq(CampaignStars.star_for(true, 500, 60.0, l), 2, "score threshold -> 2")


func test_star_three_on_score_and_percent() -> void:
	var l := _level(60.0, 500, 75.0)
	assert_eq(CampaignStars.star_for(true, 500, 75.0, l), 3, "score + percent -> 3")


func test_star_capped_and_disabled_thresholds() -> void:
	var l := _level(60.0, 0, 0.0)  # thresholds disabled
	assert_eq(CampaignStars.star_for(true, 99999, 99.0, l), 1, "disabled thresholds -> only 1")


# --- Unlock derivation ---

func test_first_level_always_unlocked() -> void:
	assert_true(CampaignStars.is_unlocked(0, ContentCatalog.LEVELS, {}))


func test_next_locked_until_prev_starred() -> void:
	var levels := ContentCatalog.LEVELS
	assert_false(CampaignStars.is_unlocked(1, levels, {}), "L2 locked with no progress")
	var stars := {String(levels[0].id): 1}
	assert_true(CampaignStars.is_unlocked(1, levels, stars), "L2 opens once L1 has a star")


# --- Boost policy branch ---

func test_policy_campaign_defers_to_level_flag() -> void:
	assert_false(BoostPolicy.boosts_allowed(SeedManager.Mode.CAMPAIGN, false), "level boosts off")
	assert_true(BoostPolicy.boosts_allowed(SeedManager.Mode.CAMPAIGN, true), "level boosts on")


func test_policy_daily_still_off_free_on() -> void:
	assert_false(BoostPolicy.boosts_allowed(SeedManager.Mode.DAILY))
	assert_true(BoostPolicy.boosts_allowed(SeedManager.Mode.FREE))
	assert_true(BoostPolicy.boosts_allowed(SeedManager.Mode.LEVEL_ENDLESS))
	assert_true(BoostPolicy.boosts_allowed(99), "unknown mode -> default on")


# --- SaveData persistence ---

func test_savedata_star_keeps_best_and_round_trip() -> void:
	var d := SaveData.new()
	assert_true(d.set_campaign_star(&"c01", 2))
	assert_false(d.set_campaign_star(&"c01", 1), "lower score does not overwrite best")
	assert_eq(d.campaign_star(&"c01"), 2)
	assert_true(d.set_campaign_star(&"c01", 3), "higher improves")
	var r := SaveData.from_dict(d.to_dict())
	assert_eq(r.campaign_star(&"c01"), 3, "round-trip preserves stars")


# --- Catalog integrity ---

func test_levels_catalog_valid() -> void:
	assert_eq(ContentCatalog.LEVELS.size(), 12, "12 authored levels")
	for lvl in ContentCatalog.LEVELS:
		assert_not_null(lvl.arena, "%s has an arena" % lvl.id)
		assert_gt(lvl.enemies.size(), 0, "%s has enemies" % lvl.id)
		assert_gt(lvl.target_percent, 0.0, "%s has a target" % lvl.id)
	assert_eq(ContentCatalog.level_at(0).id, &"c01")
	assert_null(ContentCatalog.level_at(99), "out of range -> null")
