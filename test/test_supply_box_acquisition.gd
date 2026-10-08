extends "res://test/helpers/supply_acquisition_fixture.gd"

func test_production_balance_resources() -> void:
	var config: SupplyAcquisitionConfig = SupplyBoxAcquisition.CONFIG
	assert_true(config.is_valid())
	assert_eq(config.coin_cost, 150)
	assert_eq(config.coin_daily_limit, 2)
	assert_eq(config.rewarded_daily_limit, 1)
	var entries: Array[SupplyRewardEntry] = config.reward_table.entries
	assert_eq(entries.size(), 6)
	assert_eq(entries.map(func(e: SupplyRewardEntry) -> StringName: return e.reward_type),
		[&"coins", &"coins", &"coins", &"slow_start", &"coin_bonus", &"extra_life"])
	assert_eq(entries.map(func(e: SupplyRewardEntry) -> int: return e.amount), [100, 200, 500, 1, 1, 1])
	assert_eq(entries.map(func(e: SupplyRewardEntry) -> float: return e.weight), [35.0, 35.0, 35.0, 90.0, 60.0, 45.0])


func test_first_daily_reservation_precedes_ad_show() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	assert_gt(token, 0)
	var record: Dictionary = SaveStore.load_from(PATH).supply_boxes[_box_id()]
	assert_eq(record["state"], "reserved")
	assert_eq(record["reward_type"], "slow_start")
	assert_eq(int(record["amount"]), 1)
	assert_eq(int(record["acquisition_day"]), _day[0])
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.status()["rewarded_count"], 0)


func test_cancel_retry_reuses_exact_reward_and_daily_slot() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	var first: Dictionary = _economy.supply_boxes().box_status(_box_id())
	_fake.close(token)
	await wait_process_frames(2)
	_config.reward_table.entries[0].amount = 9
	_load()
	assert_gt(_acquisition.show_daily_rewarded(_day[0]), token)
	assert_eq(_economy.supply_boxes().box_status(_box_id()), first)
	assert_eq(_acquisition.status()["rewarded_count"], 0)


func test_show_failure_retries_without_claim_or_reroll() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_fake.fail(token, &"show_failed")
	await wait_process_frames(2)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.status()["rewarded_count"], 0)
	_load()
	assert_gt(_acquisition.show_daily_rewarded(_day[0]), 0)
	assert_eq(_economy._data.supply_boxes.size(), 1)


func test_no_fill_unavailable_leaves_reserved_box_and_allowance() -> void:
	_fake.close(0)
	# Consume the ready ad outside Supply Box, then fail the next load.
	var other: int = _ads.show_rewarded("results_context")
	_fake.close(other)
	assert_true(_ads.preload_rewarded())
	_fake.fail(_fake.load_tokens.back(), &"no_fill")
	assert_eq(_acquisition.show_daily_rewarded(_day[0]), 0)
	assert_eq(_economy.supply_boxes().box_status(_box_id())["state"], "reserved")
	assert_eq(_acquisition.status()["rewarded_count"], 0)
	assert_eq(_economy.boost_count(&"slow_start"), 0)


func test_verified_reward_delivers_once_and_claim_marker_is_atomic() -> void:
	_economy.boosts_changed.connect(func() -> void:
		assert_eq(int(SaveStore.load_from(PATH).supply_acquisition_days[str(_day[0])]["rewarded_count"]), 1))
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_fake.earn_reward(token)
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	assert_eq(_acquisition.status()["rewarded_count"], 1)
	_load()
	assert_eq(_acquisition.show_daily_rewarded(_day[0]), 0)
	assert_eq(_economy._data.supply_boxes.size(), 1)


func test_wrong_context_stale_token_and_post_close_reward_rejected() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_ads.reward_earned.emit("wrong", token)
	_ads.reward_earned.emit(_box_id(), token + 1)
	await wait_process_frames(2)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	_fake.close(token)
	await wait_process_frames(2)
	_load()
	var new_token: int = _acquisition.show_daily_rewarded(_day[0])
	_ads.reward_earned.emit(_box_id(), token)
	_fake.earn_reward(token)
	await wait_process_frames(2)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	_fake.earn_reward(new_token)
	await wait_process_frames(2)
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_next_day_rewarded_eligible_and_backwards_day_cannot_bypass_claim() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	_day[0] += 1
	_load()
	assert_gt(_acquisition.show_daily_rewarded(_day[0]), 0)
	_fake.close(_fake.show_tokens.back())
	await wait_process_frames(2)
	_day[0] -= 1
	assert_eq(_acquisition.show_daily_rewarded(_day[0]), 0)


func test_midnight_reward_belongs_to_reserved_day() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_day[0] += 1
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_eq(int(_economy._data.supply_acquisition_days["12000"]["rewarded_count"]), 1)
	assert_eq(_acquisition.status()["rewarded_count"], 0)


func test_results_bonus_allowance_is_independent_in_both_directions() -> void:
	var today: int = SeedManager.today_epoch()
	_day[0] = today
	GameState.status = GameState.Status.WON
	_economy.prepare_rewarded_mission_bonus(100)
	assert_true(_economy.rewarded_mission_bonus_status()["eligible"])
	var token: int = _acquisition.show_daily_rewarded(today)
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_true(_economy.rewarded_mission_bonus_status()["eligible"])
	assert_true(_economy.claim_rewarded_mission_bonus(_economy.rewarded_mission_bonus_status()["context_id"], true))
	assert_eq(_acquisition.status()["rewarded_count"], 1)
	_day[0] += 1
	_economy._data.rewarded_mission_bonus_epoch_day = _day[0]
	_load()
	assert_gt(_acquisition.show_daily_rewarded(_day[0]), 0)


func test_coin_acceptance_single_save_contains_charge_counter_frozen_authorized_reward() -> void:
	_ads.set_requests_allowed(false)
	var result: Dictionary = _acquisition.purchase_coin_box("request", _day[0])
	assert_true(result["accepted"])
	assert_true(result["delivered"])
	assert_eq(_economy.attempted[0]["currency"], 350)
	assert_eq(_economy.attempted[0]["supply_acquisition_days"]["12000"]["coin_count"], 1)
	var box: Dictionary = _economy.attempted[0]["supply_boxes"][result["box_id"]]
	assert_eq(box["state"], "authorized")
	assert_eq(box["reward_type"], "slow_start")
	assert_eq(box["amount"], 1)
	assert_eq(_economy.writes, 2)
	assert_eq(_economy.balance(), 350)
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	assert_false(_economy.supply_boxes().deliver(result["box_id"]))


func test_insufficient_coins_changes_nothing() -> void:
	_ads.set_requests_allowed(false)
	_economy._data.currency = 149
	var before: Dictionary = _economy._data.to_dict()
	assert_false(_acquisition.purchase_coin_box("poor", _day[0])["accepted"])
	assert_eq(_economy._data.to_dict(), before)
	assert_eq(_economy.writes, 0)


func test_two_coin_purchases_third_rejected_next_day_and_backwards_limit() -> void:
	_ads.set_requests_allowed(false)
	for index: int in range(2):
		assert_true(_acquisition.purchase_coin_box(str(index), _day[0])["accepted"])
	assert_eq(_economy.balance(), 200)
	_economy._data.currency = 500
	var before: Dictionary = _economy._data.to_dict()
	assert_false(_acquisition.purchase_coin_box("fourth", _day[0])["accepted"])
	assert_eq(_economy._data.to_dict(), before)
	_day[0] += 1
	assert_eq(_acquisition.status()["coin_count"], 0)
	assert_true(_acquisition.purchase_coin_box("tomorrow", _day[0])["accepted"])
	_day[0] -= 1
	assert_false(_acquisition.purchase_coin_box("backwards", _day[0])["accepted"])


func test_coin_duplicate_request_rejected_across_reload_and_days() -> void:
	_ads.set_requests_allowed(false)
	assert_true(_acquisition.purchase_coin_box("same", _day[0])["accepted"])
	assert_false(_acquisition.purchase_coin_box("same", _day[0])["accepted"])
	_day[0] += 1
	assert_false(_acquisition.purchase_coin_box("same", _day[0])["accepted"])
	assert_eq(_economy.balance(), 350)
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_stale_day_and_empty_request_do_not_mutate() -> void:
	var before: Dictionary = _economy._data.to_dict()
	assert_false(_acquisition.purchase_coin_box("stale", _day[0] - 1)["accepted"])
	assert_false(_acquisition.purchase_coin_box(" ", _day[0])["accepted"])
	assert_eq(_acquisition.show_daily_rewarded(_day[0] - 1), 0)
	assert_eq(_economy._data.to_dict(), before)
	assert_eq(_economy.writes, 0)


func test_coin_delivery_failure_recovery_never_recharges() -> void:
	_ads.set_requests_allowed(false)
	_economy.fail_at = 2
	var result: Dictionary = _acquisition.purchase_coin_box("pending", _day[0])
	assert_true(result["accepted"])
	assert_false(result["delivered"])
	assert_eq(_economy.balance(), 350)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.status()["coin_count"], 1)
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	var recovery: SupplyBoxAcquisition = _make_acquisition(reloaded)
	assert_eq(reloaded.balance(), 350)
	assert_eq(reloaded.boost_count(&"slow_start"), 1)
	assert_false(recovery.purchase_coin_box("pending", _day[0])["accepted"])
	assert_true(recovery.recover().is_empty())


func test_coin_acceptance_save_failure_changes_nothing() -> void:
	_ads.set_requests_allowed(false)
	_economy.fail_at = 1
	var before: Dictionary = _economy._data.to_dict()
	assert_false(_acquisition.purchase_coin_box("failed", _day[0])["accepted"])
	assert_eq(_economy._data.to_dict(), before)
	assert_eq(SaveStore.load_from(PATH).currency, 500)
	assert_true(_acquisition.purchase_coin_box("failed", _day[0])["accepted"])


func test_rewarded_delivery_failure_recovers_marker_and_reward_together() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_economy.fail_at = 3
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_eq(_economy.supply_boxes().box_status(_box_id())["state"], "authorized")
	assert_eq(_acquisition.status()["rewarded_count"], 0)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.recover(), [_box_id()])
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	assert_eq(_acquisition.status()["rewarded_count"], 1)
	assert_true(_acquisition.recover().is_empty())


func test_rewarded_authorization_failure_retains_only_runtime_proof() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_economy.fail_at = 2
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_eq(_economy.supply_boxes().box_status(_box_id())["state"], "reserved")
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.recover(), [_box_id()])
	assert_eq(_acquisition.status()["rewarded_count"], 1)


func test_reserved_restart_reuses_reward_without_auto_grant() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_fake.close(token)
	await wait_process_frames(2)
	var record: Dictionary = SaveStore.load_from(PATH).supply_boxes[_box_id()]
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	var acquisition: SupplyBoxAcquisition = _make_acquisition(reloaded)
	assert_true(acquisition.recover().is_empty())
	_load()
	assert_gt(acquisition.show_daily_rewarded(_day[0]), 0)
	assert_eq(reloaded.supply_boxes().box_status(_box_id()), record)
	assert_eq(reloaded.boost_count(&"slow_start"), 0)


func test_synchronous_native_reward_and_close_correlate_after_show_returns() -> void:
	_acquisition.free()
	_ads.free()
	_make_ads(ImmediateAds.new())
	_acquisition = _make_acquisition(_economy)
	assert_gt(_acquisition.show_daily_rewarded(_day[0]), 0)
	await wait_process_frames(2)
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	assert_eq(_acquisition.status()["rewarded_count"], 1)


func test_old_save_and_corrupt_counters_fail_safely() -> void:
	assert_true(SaveData.from_dict({"currency": 5}).supply_acquisition_days.is_empty())
	_economy._data.supply_acquisition_days["12000"] = {"coin_count": -1, "rewarded_count": 0}
	assert_false(_acquisition.purchase_coin_box("corrupt", _day[0])["accepted"])
	assert_eq(_acquisition.show_daily_rewarded(_day[0]), 0)
	assert_eq(_economy.balance(), 500)


func test_production_accessor_uses_canonical_day_and_same_coordinator() -> void:
	var acquisition: SupplyBoxAcquisition = _economy.supply_acquisition()
	assert_same(acquisition, _economy.supply_acquisition())
	assert_eq(acquisition.status()["day"], SeedManager.today_epoch())


func test_rewarded_authorized_restart_completes_delivery_and_daily_claim() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_economy.fail_at = 3
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	var recovery: SupplyBoxAcquisition = _make_acquisition(reloaded)
	assert_eq(reloaded.boost_count(&"slow_start"), 1)
	assert_eq(recovery.status()["rewarded_count"], 1)
	assert_eq(recovery.show_daily_rewarded(_day[0]), 0)
	assert_true(recovery.recover().is_empty())


func test_lost_unpersisted_proof_after_restart_cannot_authorize_reserved_box() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_economy.fail_at = 2
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	var recovery: SupplyBoxAcquisition = _make_acquisition(reloaded)
	assert_true(recovery.recover().is_empty())
	assert_eq(reloaded.boost_count(&"slow_start"), 0)
	assert_eq(recovery.status()["rewarded_count"], 0)
	_load()
	assert_gt(recovery.show_daily_rewarded(_day[0]), 0)


func test_coin_limits_and_duplicate_identity_survive_reload() -> void:
	_ads.set_requests_allowed(false)
	assert_true(_acquisition.purchase_coin_box("persisted", _day[0])["accepted"])
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	var acquisition: SupplyBoxAcquisition = _make_acquisition(reloaded)
	assert_eq(acquisition.status()["coin_count"], 1)
	assert_false(acquisition.purchase_coin_box("persisted", _day[0])["accepted"])
	assert_eq(reloaded.balance(), 350)
	assert_eq(reloaded.boost_count(&"slow_start"), 1)


func test_failed_reservation_never_launches_ad() -> void:
	_economy.fail_at = 1
	assert_eq(_acquisition.show_daily_rewarded(_day[0]), 0)
	assert_true(_fake.show_tokens.is_empty())
	assert_true(_economy._data.supply_boxes.is_empty())
	assert_eq(_acquisition.status()["rewarded_count"], 0)


func test_coin_reward_nets_cost_without_refunding_acquisition_count() -> void:
	_ads.set_requests_allowed(false)
	_config.reward_table.entries[0].reward_type = &"coins"
	_config.reward_table.entries[0].amount = 100
	assert_true(_acquisition.purchase_coin_box("coin-reward", _day[0])["delivered"])
	assert_eq(_economy.balance(), 450)
	assert_eq(_acquisition.status()["coin_count"], 1)


func test_pending_coin_acquisition_consumes_limit_before_final_delivery() -> void:
	_ads.set_requests_allowed(false)
	_economy.fail_at = 2
	assert_true(_acquisition.purchase_coin_box("pending", _day[0])["accepted"])
	assert_true(_acquisition.purchase_coin_box("second", _day[0])["accepted"])
	assert_false(_acquisition.purchase_coin_box("third", _day[0])["accepted"])
	_economy._data.currency = 500
	assert_false(_acquisition.purchase_coin_box("fourth", _day[0])["accepted"])
	assert_eq(_acquisition.recover(), ["supply/coin/pending"])
	assert_eq(_economy.boost_count(&"slow_start"), 2)
