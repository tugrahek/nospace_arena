extends GutTest

const EconomyScript = preload("res://scripts/autoload/Economy.gd")
const SaveDataScript = preload("res://scripts/meta/save_data.gd")
const SaveStoreScript = preload("res://scripts/meta/save_store.gd")
const PATH: String = "user://23c1_rewarded_bonus_fixture.json"

var _economy: EconomyScript
var _old_day_offset: int


func before_each() -> void:
	_old_day_offset = SeedManager.day_offset
	GameState.reset()
	for suffix: String in ["", SaveStoreScript.TEMP_SUFFIX, SaveStoreScript.BACKUP_SUFFIX]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)
	_economy = EconomyScript.new()
	_economy._save_path = PATH
	add_child_autofree(_economy)


func after_each() -> void:
	SeedManager.day_offset = _old_day_offset
	GameState.reset()
	for suffix: String in ["", SaveStoreScript.TEMP_SUFFIX, SaveStoreScript.BACKUP_SUFFIX]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func _finish(base: int, multiplier: float = 1.0, won: bool = true) -> int:
	GameState.start_run(1)
	if won:
		GameState.win_run()
	else:
		GameState.lose_life()
	_economy.earn(roundi(base * multiplier))
	_economy.prepare_rewarded_mission_bonus(base)
	return int(_economy.rewarded_mission_bonus_status()["context_id"])


func test_new_mission_payout_eligible_on_win_and_loss() -> void:
	for won in [true, false]:
		_finish(100, 1.0, won)
		assert_true(_economy.rewarded_mission_bonus_status()["eligible"])
		assert_eq(_economy.rewarded_mission_bonus_status()["amount"], 50)


func test_zero_and_negative_payout_ineligible() -> void:
	for base in [0, -10]:
		var context: int = _finish(base)
		assert_false(_economy.rewarded_mission_bonus_status()["eligible"])
		assert_false(_economy.claim_rewarded_mission_bonus(context, true))


func test_floor_half_including_odd_and_single_coin() -> void:
	assert_eq(EconomyScript.rewarded_mission_bonus_amount(100), 50)
	assert_eq(EconomyScript.rewarded_mission_bonus_amount(101), 50)
	assert_eq(EconomyScript.rewarded_mission_bonus_amount(3), 1)
	assert_eq(EconomyScript.rewarded_mission_bonus_amount(1), 0)
	assert_eq(EconomyScript.rewarded_mission_bonus_amount(-10), 0)


func test_coin_bonus_does_not_multiply_rewarded_bonus() -> void:
	var context: int = _finish(100, 1.5)
	assert_eq(_economy.balance(), 150)
	assert_eq(_economy.rewarded_mission_bonus_status()["amount"], 50)
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(_economy.balance(), 200)
	assert_eq(SaveStoreScript.load_from(PATH).currency, 200)


func test_claim_persists_coins_and_marker_exactly_once() -> void:
	var context: int = _finish(101)
	var signals := [0]
	_economy.currency_changed.connect(func(_balance: int) -> void: signals[0] += 1)
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	assert_false(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(_economy.balance(), 151)
	var saved = SaveStoreScript.load_from(PATH)
	assert_eq(saved.currency, _economy.balance())
	assert_eq(saved.rewarded_mission_bonus_epoch_day, SeedManager.today_epoch())
	assert_eq(signals[0], 1)


func test_reload_remains_claimed_even_with_another_paid_run() -> void:
	assert_true(_economy.claim_rewarded_mission_bonus(_finish(100), true))
	_economy._data = SaveStoreScript.load_from(PATH)
	var context: int = _finish(100)
	assert_false(_economy.rewarded_mission_bonus_status()["eligible"])
	assert_false(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(_economy.balance(), 250)


func test_unverified_cancel_close_failure_grant_nothing() -> void:
	var context: int = _finish(100)
	for _outcome in ["cancel", "close", "failure"]:
		assert_false(_economy.claim_rewarded_mission_bonus(context, false))
		assert_eq(_economy.balance(), 100)
		assert_eq(SaveStoreScript.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))


func test_stale_context_rejected_after_new_run_and_after_new_payout() -> void:
	var old_context: int = _finish(100)
	GameState.start_run(1)
	assert_false(_economy.claim_rewarded_mission_bonus(old_context, true))
	var context: int = _finish(60)
	assert_ne(context, old_context)
	assert_false(_economy.claim_rewarded_mission_bonus(old_context, true))
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(_economy.balance(), 190)


func test_invalid_context_and_unfinished_run_rejected() -> void:
	GameState.start_run(1)
	_economy.prepare_rewarded_mission_bonus(100)
	assert_false(_economy.rewarded_mission_bonus_status()["eligible"])
	var context: int = _finish(100)
	assert_false(_economy.claim_rewarded_mission_bonus(context + 1, true))
	GameState.reset()
	assert_false(_economy.claim_rewarded_mission_bonus(context, true))


func test_day_rollover_requires_fresh_paid_run() -> void:
	var old_context: int = _finish(100)
	SeedManager.day_offset += 1
	assert_false(_economy.claim_rewarded_mission_bonus(old_context, true))
	assert_true(_economy.claim_rewarded_mission_bonus(_finish(100), true))


func test_next_local_day_can_claim_again() -> void:
	assert_true(_economy.claim_rewarded_mission_bonus(_finish(100), true))
	SeedManager.day_offset += 1
	var context: int = _finish(100)
	assert_true(_economy.rewarded_mission_bonus_status()["eligible"])
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(_economy.balance(), 300)
	assert_eq(SaveStoreScript.load_from(PATH).rewarded_mission_bonus_epoch_day, SeedManager.today_epoch())


func test_old_profile_defaults_unclaimed_and_round_trips() -> void:
	var old = SaveDataScript.from_dict({"currency": 42})
	assert_eq(old.rewarded_mission_bonus_epoch_day, -1)
	assert_true(SaveStoreScript.save_to(PATH, old))
	_economy._data = SaveStoreScript.load_from(PATH)
	assert_eq(_economy.balance(), 42)
	assert_true(_economy.claim_rewarded_mission_bonus(_finish(100), true))
	assert_eq(SaveStoreScript.load_from(PATH).currency, 192)


func test_failed_save_keeps_profile_and_marker_unchanged_then_can_retry() -> void:
	var context: int = _finish(100)
	_economy._save_path = "user://23c1_missing_directory/save.json"
	assert_false(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(_economy.balance(), 100)
	assert_eq(_economy._data.rewarded_mission_bonus_epoch_day, -1)
	assert_eq(SaveStoreScript.load_from(PATH).currency, 100)
	_economy._save_path = PATH
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))


func test_reentrant_completion_cannot_claim_twice() -> void:
	var context: int = _finish(100)
	var duplicate := [true]
	_economy.currency_changed.connect(func(_balance: int) -> void:
		duplicate[0] = _economy.claim_rewarded_mission_bonus(context, true))
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	assert_false(duplicate[0])
	assert_eq(SaveStoreScript.load_from(PATH).currency, 150)


func test_preparing_same_finished_run_cannot_replace_base_or_rearm_claim() -> void:
	var context: int = _finish(100)
	_economy.prepare_rewarded_mission_bonus(1000)
	assert_eq(_economy.rewarded_mission_bonus_status()["amount"], 50)
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	_economy.prepare_rewarded_mission_bonus(1000)
	assert_false(_economy.claim_rewarded_mission_bonus(context, true))


func test_single_coin_payout_uses_zero_floor_and_still_persists_daily_claim() -> void:
	var context: int = _finish(1)
	assert_true(_economy.rewarded_mission_bonus_status()["eligible"])
	assert_true(_economy.claim_rewarded_mission_bonus(context, true))
	assert_eq(SaveStoreScript.load_from(PATH).currency, 1)
	assert_false(_economy.claim_rewarded_mission_bonus(context, true))
