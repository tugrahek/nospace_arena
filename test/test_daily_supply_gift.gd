extends "res://test/helpers/supply_acquisition_fixture.gd"


func _prepare_day_ten() -> void:
	_economy._data.last_claim_epoch_day = SeedManager.today_epoch() - 1
	_economy._data.streak_day = 9
	assert_true(SaveStore.save_to(PATH, _economy._data))


func test_day_ten_acceptance_is_supply_box_only_and_freezes_one_gift() -> void:
	_prepare_day_ten()
	var result: Dictionary = _economy.claim_login_reward_bundle()
	assert_true(result["gift_delivered"])
	assert_eq(result["coins"], 0)
	assert_eq(result["boost_ids"], [])
	assert_true(result["supply_box"])
	assert_eq(_economy._data.supply_boxes.size(), 1)
	var accepted: Dictionary = _economy.attempted[0]
	assert_eq(accepted["last_claim_epoch_day"], SeedManager.today_epoch())
	assert_eq(accepted["streak_day"], 10)
	assert_false(accepted["boost_charges"].has("extra_life"))
	var record: Dictionary = accepted["supply_boxes"][result["gift_box_id"]]
	assert_eq(record["state"], "authorized")
	assert_eq(record["source"], DailyRewardClaim.GIFT_SOURCE)
	assert_eq(record["daily_cycle_start"], SeedManager.today_epoch() - 9)
	assert_eq(SaveStore.load_from(PATH).supply_boxes[result["gift_box_id"]]["state"], "delivered")
	assert_true(_economy._data.supply_acquisition_days.is_empty())
	assert_eq(_acquisition.status()["rewarded_count"], 0)
	assert_eq(_acquisition.status()["coin_count"], 0)
	assert_eq(_economy._data.rewarded_mission_bonus_epoch_day, -1)


func test_day_seven_is_extra_life_only_and_day_eight_follows() -> void:
	var old_offset: int = SeedManager.day_offset
	_economy._data.last_claim_epoch_day = SeedManager.today_epoch() - 1
	_economy._data.streak_day = 6
	var day_seven: Dictionary = _economy.claim_login_reward_bundle()
	assert_eq(day_seven["boost_ids"], [&"extra_life"])
	assert_false(day_seven.has("supply_box"))
	assert_true(_economy._data.supply_boxes.is_empty())
	SeedManager.day_offset += 1
	assert_eq(_economy.login_reward_status()["new_streak"], 8)
	var day_eight: Dictionary = _economy.claim_login_reward_bundle()
	assert_eq(day_eight["coins"], 250)
	assert_eq(day_eight["boost_ids"], [])
	assert_false(day_eight.has("supply_box"))
	assert_true(_economy._data.supply_boxes.is_empty())
	SeedManager.day_offset = old_offset


func test_legacy_day_seven_box_is_preserved_without_retroactive_gift() -> void:
	var today: int = SeedManager.today_epoch()
	var legacy_id: String = "supply/daily_gift/%d" % (today - 1)
	_economy._data.last_claim_epoch_day = today - 1
	_economy._data.streak_day = 7
	_economy._data.add_boost(&"extra_life", 1)
	_economy._data.supply_boxes[legacy_id] = {
		"box_id": legacy_id, "source": DailyRewardClaim.GIFT_SOURCE,
		"context": "daily/%d/%d" % [today - 7, today - 1],
		"table_key": String(DailyRewardClaim.CONFIG.reward_table.table_key),
		"table_version": DailyRewardClaim.CONFIG.reward_table.version,
		"reward_type": "coins", "amount": 100, "state": "delivered", "presented": true,
		"acquisition_day": today - 1, "daily_cycle_start": today - 7,
	}
	assert_true(SaveStore.save_to(PATH, _economy._data))
	var result: Dictionary = _economy.claim_login_reward_bundle()
	assert_eq(result["coins"], 250)
	assert_eq(_economy._data.streak_day, 8)
	assert_false(result.has("gift_box_id"))
	assert_eq(_economy._data.supply_boxes.size(), 1)
	assert_eq(_economy.supply_boxes().box_status(legacy_id)["amount"], 100)
	assert_eq(_economy.boost_count(&"extra_life"), 1, "previously earned Day 7 Extra Life remains owned")


func test_gift_duplicate_claim_and_reload_never_grant_another_box() -> void:
	_prepare_day_ten()
	var result: Dictionary = _economy.claim_login_reward_bundle()
	var before: Dictionary = _economy._data.to_dict()
	assert_true(_economy.claim_login_reward_bundle().is_empty())
	assert_false(_economy.supply_boxes().deliver(result["gift_box_id"]))
	assert_eq(_economy._data.to_dict(), before)
	var loaded: EconomyScript = EconomyScript.new()
	loaded._save_path = PATH
	add_child_autofree(loaded)
	assert_true(loaded.claim_login_reward_bundle().is_empty())
	assert_true(loaded.supply_boxes().recover_authorized().is_empty())
	assert_eq(JSON.parse_string(JSON.stringify(loaded._data.to_dict())), JSON.parse_string(JSON.stringify(before)))


func test_interrupted_gift_delivery_recovers_same_outcome_without_reclaim() -> void:
	_prepare_day_ten()
	_economy.fail_at = 2
	var result: Dictionary = _economy.claim_login_reward_bundle()
	assert_false(result["gift_delivered"])
	assert_eq(_economy.balance(), 500, "undelivered Day 10 gift has not changed the reward balance")
	assert_eq(_economy.boost_count(&"extra_life"), 0)
	var frozen: Dictionary = SaveStore.load_from(PATH).supply_boxes[result["gift_box_id"]]
	assert_eq(frozen["state"], "authorized")
	var loaded: EconomyScript = EconomyScript.new()
	loaded._save_path = PATH
	add_child_autofree(loaded)
	assert_true(loaded.claim_login_reward_bundle().is_empty())
	assert_eq(loaded.supply_boxes().recover_authorized(), [result["gift_box_id"]])
	var delivered: Dictionary = loaded.supply_boxes().box_status(result["gift_box_id"])
	assert_eq(delivered["reward_type"], frozen["reward_type"])
	assert_eq(delivered["amount"], frozen["amount"])
	assert_eq(loaded._data.supply_boxes.size(), 1)
	assert_true(loaded.supply_boxes().recover_authorized().is_empty())
	assert_true(loaded._data.supply_acquisition_days.is_empty())


func test_failed_checked_acceptance_grants_nothing_and_retry_is_once() -> void:
	_prepare_day_ten()
	_economy.fail_at = 1
	var before: Dictionary = _economy._data.to_dict()
	assert_true(_economy.claim_login_reward_bundle().is_empty())
	assert_eq(_economy._data.to_dict(), before)
	assert_eq(SaveStore.load_from(PATH).streak_day, 9)
	assert_false(_economy.claim_login_reward_bundle().is_empty())
	assert_true(_economy.claim_login_reward_bundle().is_empty())
	assert_eq(_economy._data.supply_boxes.size(), 1)


func test_two_distinct_daily_cycles_get_distinct_gifts() -> void:
	var old_offset: int = SeedManager.day_offset
	_prepare_day_ten()
	var first: Dictionary = _economy.claim_login_reward_bundle()
	var frozen: Dictionary = _economy.supply_boxes().box_status(first["gift_box_id"])
	SeedManager.day_offset += 10
	_prepare_day_ten()
	var second: Dictionary = _economy.claim_login_reward_bundle()
	assert_ne(first["gift_box_id"], second["gift_box_id"])
	assert_eq(_economy._data.supply_boxes.size(), 2)
	assert_eq(_economy.supply_boxes().box_status(first["gift_box_id"]), frozen)
	SeedManager.day_offset = old_offset


func test_gift_does_not_reopen_exhausted_coin_or_rewarded_allowances() -> void:
	_prepare_day_ten()
	_economy._data.supply_acquisition_days[str(_day[0])] = {"coin_count": 2, "rewarded_count": 1}
	assert_false(_economy.claim_login_reward_bundle().is_empty())
	assert_eq(_acquisition.status()["coin_count"], 2)
	assert_eq(_acquisition.status()["rewarded_count"], 1)
	assert_false(_acquisition.coin_available())


func test_main_menu_reveals_persisted_gift_without_granting_again() -> void:
	var original: Variant = Economy._data
	var old_path: String = Economy._save_path
	Economy._data = SaveData.new_default()
	Economy._save_path = PATH
	Economy._data.tutorial_seen = true
	Economy._data.last_claim_epoch_day = SeedManager.today_epoch() - 1
	Economy._data.streak_day = 9
	var result: Dictionary = Economy.claim_login_reward_bundle()
	var balance: int = Economy.balance()
	var boosts: Dictionary = Economy._data.boost_charges.duplicate(true)
	var menu: Control = preload("res://scenes/main/MainMenu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(2)
	var reveal: SupplyPopup = menu.get_node("GiftOverlay/Reveal")
	assert_true(menu.get_node("GiftOverlay").visible)
	assert_eq(reveal.revealed_box_id, result["gift_box_id"])
	assert_eq(Economy.balance(), balance)
	assert_eq(Economy._data.boost_charges, boosts)
	var viewport: Viewport = get_viewport()
	var original_viewport_size: Vector2i = viewport.size
	var continue_button: Control = reveal.get_node("SafeArea/Bounds/Frame/RevealView/Footer/Continue")
	for screen_size: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600)]:
		viewport.size = screen_size
		await wait_process_frames(2)
		var usable_rect: Rect2 = reveal.get_node("SafeArea/Bounds").get_global_rect()
		assert_true(usable_rect.encloses(reveal.get_node("SafeArea/Bounds/Frame").get_global_rect()))
		assert_true(usable_rect.encloses(continue_button.get_global_rect()))
	viewport.size = original_viewport_size
	await wait_process_frames(2)
	reveal._continue.pressed.emit()
	assert_false(menu.get_node("GiftOverlay").visible)
	assert_true(Economy.supply_boxes().box_status(result["gift_box_id"])["presented"])
	menu.free()
	Economy._data = original
	Economy._save_path = old_path
