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
	var l := _level(60.0, 500, 0.0)
	assert_eq(CampaignStars.star_for(false, 9999, 0, l), 0, "not reached -> 0 stars")


func test_star_one_cleared_only() -> void:
	var l := _level(60.0, 500, 0.0)
	assert_eq(CampaignStars.star_for(true, 100, 1, l), 1, "cleared, low score, died -> 1")


func test_star_two_on_score() -> void:
	var l := _level(60.0, 500, 0.0)
	assert_eq(CampaignStars.star_for(true, 500, 1, l), 2, "score met but died -> 2")


func test_star_two_on_flawless() -> void:
	var l := _level(60.0, 500, 0.0)
	assert_eq(CampaignStars.star_for(true, 100, 0, l), 2, "flawless but low score -> 2")


func test_star_three_score_and_flawless() -> void:
	var l := _level(60.0, 500, 0.0)
	assert_eq(CampaignStars.star_for(true, 500, 0, l), 3, "score met AND flawless -> 3")


func test_star_disabled_score_threshold() -> void:
	var l := _level(60.0, 0, 0.0)  # score star disabled (star2_score = 0)
	assert_eq(CampaignStars.star_for(true, 99999, 1, l), 1, "no score star + died -> 1")
	assert_eq(CampaignStars.star_for(true, 99999, 0, l), 2, "flawless still counts -> 2")


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

func test_boost_resolve_respects_level_flag() -> void:
	# Campaign with boosts_allowed=false -> nothing applied, even if armed + owned.
	var armed := {"extra_life": true}
	var counts := {"extra_life": 3}
	var off := BoostEffects.resolve(SeedManager.Mode.CAMPAIGN, ContentCatalog.BOOSTS, armed, counts, false)
	assert_eq(off["extra_lives"], 0, "boost-locked level -> no boost")
	assert_eq(off["consume"].size(), 0, "no charge consumed")
	var on := BoostEffects.resolve(SeedManager.Mode.CAMPAIGN, ContentCatalog.BOOSTS, armed, counts, true)
	assert_eq(on["extra_lives"], 1, "boost-allowed level -> applied")


func test_level_select_scene_instantiates() -> void:
	var s: Control = load("res://scenes/ui/LevelSelect.tscn").instantiate()
	add_child_autofree(s)
	assert_not_null(s, "LevelSelect builds its level grid")


func test_campaign_configures_selected_level() -> void:
	# Game in CAMPAIGN mode configures arena/composition/target/lives from the LevelData.
	SeedManager.enter_campaign(0)  # c01: void, 1 bouncer, target 50, lives 3
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	add_child_autofree(game)
	assert_almost_eq(float(game.get("_stage_target")), 50.0, 0.01, "target from level")
	assert_eq((game.get("_enemies") as Array).size(), 1, "composition from level (1 enemy)")
	assert_eq(GameState.lives, 3, "lives from level")
	SeedManager.enter_free()
	GameState.reset()


func test_levels_catalog_valid() -> void:
	assert_eq(ContentCatalog.LEVELS.size(), 12, "12 authored levels")
	for lvl in ContentCatalog.LEVELS:
		assert_not_null(lvl.arena, "%s has an arena" % lvl.id)
		assert_gt(lvl.enemies.size(), 0, "%s has enemies" % lvl.id)
		assert_gt(lvl.target_percent, 0.0, "%s has a target" % lvl.id)
		assert_ne(lvl.description_key, "", "%s has a description key" % lvl.id)
	assert_eq(ContentCatalog.level_at(0).id, &"c01")
	assert_null(ContentCatalog.level_at(99), "out of range -> null")
