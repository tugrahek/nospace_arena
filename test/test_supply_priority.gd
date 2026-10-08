extends "res://test/helpers/supply_acquisition_fixture.gd"


func test_ready_unclaimed_rewarded_blocks_coin_without_mutation() -> void:
	var before: Dictionary = _economy._data.to_dict()
	assert_false(_acquisition.coin_available())
	assert_false(_acquisition.purchase_coin_box("blocked", _day[0])["accepted"])
	assert_eq(_economy._data.to_dict(), before)
	assert_eq(_economy.writes, 0)


func test_unavailable_ad_allows_coin_then_ready_again_blocks_it() -> void:
	_ads.set_requests_allowed(false)
	assert_true(_acquisition.coin_available())
	assert_true(_acquisition.purchase_coin_box("allowed", _day[0])["accepted"])
	_ads.set_requests_allowed(true)
	_load()
	assert_false(_acquisition.coin_available())
	assert_false(_acquisition.purchase_coin_box("blocked-again", _day[0])["accepted"])
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_claimed_rewarded_allows_coin_even_when_next_ad_ready() -> void:
	var token: int = _acquisition.show_daily_rewarded(_day[0])
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	_load()
	assert_true(_ads.is_rewarded_available())
	assert_true(_acquisition.coin_available())
	assert_true(_acquisition.purchase_coin_box("after-reward", _day[0])["accepted"])
	assert_eq(_economy.boost_count(&"slow_start"), 2)
	assert_eq(_acquisition.status()["rewarded_count"], 1)
	assert_eq(_economy._data.rewarded_mission_bonus_epoch_day, -1)


func test_no_fill_cannot_permanently_block_coin_acquisition() -> void:
	var token: int = _ads.show_rewarded("unrelated-context")
	_fake.close(token)
	assert_true(_ads.preload_rewarded())
	_fake.fail(_fake.load_tokens.back(), &"no_fill")
	assert_true(_acquisition.coin_available())
	assert_true(_acquisition.purchase_coin_box("fallback", _day[0])["accepted"])


func test_preexisting_today_count_respects_new_limit_without_reset() -> void:
	_ads.set_requests_allowed(false)
	for count: int in [2, 3]:
		_economy._data.supply_acquisition_days[str(_day[0])] = {"coin_count": count, "rewarded_count": 0}
		var before: Dictionary = _economy._data.to_dict()
		assert_false(_acquisition.purchase_coin_box("older-purchases", _day[0])["accepted"])
		assert_eq(_economy._data.to_dict(), before)
