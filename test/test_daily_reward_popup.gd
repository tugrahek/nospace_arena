extends GutTest

const MENU: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const TABLE: Array[int] = Economy.LOGIN_REWARDS
const FIXTURE_PATH: String = "user://e4_reward_fixture.json"
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")

class FixtureEconomy:
	extends "res://scripts/autoload/Economy.gd"
	func _ready() -> void:
		pass
	func _flush() -> void:
		SaveStore.save_to("user://e4_reward_fixture.json", _data)


func after_each() -> void:
	TranslationServer.set_locale("en")
	for suffix: String in ["", SaveStore.TEMP_SUFFIX, SaveStore.BACKUP_SUFFIX]:
		if FileAccess.file_exists(FIXTURE_PATH + suffix):
			DirAccess.remove_absolute(FIXTURE_PATH + suffix)


func _popup(action: Callable = Callable()) -> DailyRewardPopup:
	var menu: Control = MENU.instantiate()
	var popup: DailyRewardPopup = menu.get_node("RewardPopup")
	menu.remove_child(popup)
	menu.free()
	popup.claim_action = action
	add_child_autofree(popup)
	return popup


func test_eligibility_amount_and_locale_bind_without_auto_claim() -> void:
	var calls := [0]
	var popup := _popup(func() -> int: calls[0] += 1; return 180)
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		assert_true(popup.present(LoginStreak.evaluate(101, 100, 3, TABLE)))
		assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardAmount").text, "+180")
		assert_eq(popup.get_node("SafeArea/Bounds/Box/RewardTitle").text, "Günlük Ödül" if locale == "tr" else "Daily Reward")
		assert_eq(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").text, "Bugün Al" if locale == "tr" else "Claim Today")
		assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardBody").text, "Gün 4/10" if locale == "tr" else "Day 4/10")
	assert_eq(calls[0], 0, "showing the manual popup never claims")
	assert_false(popup.present(LoginStreak.evaluate(101, 101, 4, TABLE)))
	assert_false(popup.visible)
	assert_true(popup.present(LoginStreak.evaluate(102, 101, 4, TABLE)))
	assert_eq(popup.reward_amount, 0)
	assert_eq(popup.preview_spec["boost_ids"], [&"coin_bonus"])


func test_repeated_pressed_claims_once_and_keeps_actual_result_visible() -> void:
	var data := SaveData.new_default()
	var calls := [0]
	var popup := _popup(func() -> int:
		calls[0] += 1
		var result: Dictionary = LoginStreak.evaluate(100, data.last_claim_epoch_day, data.streak_day, TABLE)
		if not result["claimable"]: return 0
		data.earn(result["reward"])
		data.last_claim_epoch_day = 100
		data.streak_day = result["new_streak"]
		SaveStore.save_to(FIXTURE_PATH, data)
		return result["reward"]
	)
	var initial: int = data.currency
	var signals := [0]
	popup.reward_claimed.connect(func(_amount: int) -> void: signals[0] += 1)
	popup.present(LoginStreak.evaluate(100, -1, 0, TABLE))
	var button: Button = popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton")
	button.pressed.emit()
	button.pressed.emit()
	assert_eq(calls[0], 1)
	assert_eq(signals[0], 1)
	assert_eq(data.currency, initial + 50)
	assert_eq(SaveStore.load_from(FIXTURE_PATH).currency, initial + 50)
	assert_eq(SaveStore.load_from(FIXTURE_PATH).last_claim_epoch_day, 100)
	assert_eq(SaveStore.load_from(FIXTURE_PATH).streak_day, 1)
	assert_eq(popup.state, DailyRewardPopup.State.CLAIMED)
	assert_true(popup.visible)
	assert_true(button.disabled)
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardAmount").text, "+50")
	assert_eq(button.text, "✓ Received")
	assert_almost_eq(popup.claimed_hold_duration, 0.7, 0.001)
	assert_false(LoginStreak.evaluate(100, data.last_claim_epoch_day, data.streak_day, TABLE)["claimable"])


func test_hold_dismissal_and_repeated_present_lifecycle() -> void:
	var popup := _popup(func() -> int: return 75)
	popup.claim_pulse_duration = 0.01
	popup.claimed_hold_duration = 0.01
	popup.dismissal_duration = 0.01
	var dismissed_count := [0]
	popup.dismissed.connect(func() -> void: dismissed_count[0] += 1)
	for i in 3:
		popup.present({"claimable": true, "reward": 75, "new_streak": 2})
		popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
		assert_true(popup.visible, "no immediate dismissal during pressed emission")
		await wait_for_signal(popup.dismissed, 1.0)
		assert_false(popup.visible)
		assert_eq(popup.state, DailyRewardPopup.State.HIDDEN)
	assert_eq(dismissed_count[0], 3)
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.get_connections().size(), 1)


func test_main_menu_refreshes_real_currency_on_claim_signal() -> void:
	# In-memory profile fixture avoids claiming or changing the player's save.
	var original: Variant = Economy.get("_data")
	var fixture := SaveData.new_default()
	fixture.tutorial_seen = true
	Economy.set("_data", fixture)
	var menu: Control = MENU.instantiate()
	add_child_autofree(menu)
	var popup: DailyRewardPopup = menu.get_node("RewardPopup")
	popup.claim_action = func() -> int:
		fixture.earn(50)
		fixture.last_claim_epoch_day = SeedManager.today_epoch()
		fixture.streak_day = 1
		return 50
	popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
	assert_eq(menu.get_node("SafeArea/Bounds/Frame/Header/CoinsPanel/Content/Coins").text, tr("HUD_CURRENCY") + ": " + str(fixture.currency))
	assert_eq(popup.state, DailyRewardPopup.State.CLAIMED)
	assert_lt(menu.get_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons").modulate.a, 1.0)
	popup.dismissed.emit()
	assert_eq(menu.get_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons").modulate.a, 1.0)
	Economy.set("_data", original)


func test_ten_real_rewards_route_mapping_and_future_preview_no_claim() -> void:
	var calls := [0]
	var popup := _popup(func() -> Dictionary: calls[0] += 1; return Economy.login_reward_spec(10))
	for day in range(1, 11):
		popup.present({"claimable": true, "reward": TABLE[day - 1], "new_streak": day})
		await wait_process_frames(2)
		var route: DailyRewardRoute = popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route")
		assert_eq(route.checkpoints.size(), 10)
		assert_eq(route.current_day, day)
		assert_eq(route.completed_days, day - 1)
		assert_eq(popup.reward_amount, TABLE[day - 1])
		assert_lt(route.checkpoint_center(0).x, route.checkpoint_center(9).x)
		assert_gt(route.endpoint_scale, 1.0)
		for preview in range(1, 11):
			route.checkpoints[preview - 1].pressed.emit()
			assert_eq(popup.selected_day, preview)
			assert_eq(popup.reward_amount, TABLE[preview - 1])
			assert_eq(popup.current_day, day, "preview never changes today's claim target")
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route").current_day, day, "today highlight remains sticky")
			assert_true(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").visible, "today stays claimable during preview")
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").text, tr("DAILY_REWARD_CLAIM_TODAY"))
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardBody").text, (tr("DAILY_REWARD_DAY") % day) if preview == day else (tr("DAILY_REWARD_PREVIEW") % preview))
	assert_eq(calls[0], 0, "previews never mutate Economy")
	popup.preview_day(10)
	popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
	assert_eq(calls[0], 1, "Claim always acts on today's eligibility")
	assert_eq(popup.reward_amount, TABLE[10 - 1], "claimed reward is today's actual amount")


func test_claimed_inspection_has_no_claim_and_canonical_next_cycle() -> void:
	var popup := _popup(func() -> int: fail_test("inspection must not claim"); return 0)
	for day in range(1, 11):
		var status: Dictionary = LoginStreak.evaluate(100, 100, day, TABLE)
		assert_true(popup.present(status, true))
		assert_eq(popup.state, DailyRewardPopup.State.INSPECTING)
		assert_eq(popup.completed_days, day)
		assert_eq(popup.reward_amount, TABLE[day - 1])
		assert_true(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Received").visible)
		assert_false(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").visible)
		popup.preview_day(2)
		assert_false(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").visible)
		assert_eq(popup.current_day, day, "past-day inspection cannot replace the canonical current day")
		popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
		popup.preview_day(7)
		assert_false(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").visible)
	assert_true(popup.present(LoginStreak.evaluate(101, 100, 10, TABLE)))
	assert_eq(popup.current_day, 1)
	assert_eq(popup.completed_days, 0)
	assert_eq(popup.reward_amount, 50)
	popup.present(LoginStreak.evaluate(103, 100, 5, TABLE))
	assert_eq(popup.current_day, 1, "missed day remains a reset")


func test_day_two_claim_stays_day_two_while_day_seven_is_previewed() -> void:
	TranslationServer.set_locale("tr")
	var calls := [0]
	var popup := _popup(func() -> int: calls[0] += 1; return 75)
	popup.present({"claimable": true, "reward": 75, "new_streak": 2})
	popup.preview_day(7)
	assert_eq(popup.reward_amount, 0, "future Day 7 is boost-only")
	assert_eq(popup.preview_spec["boost_ids"], [&"extra_life"])
	assert_eq(popup.current_day, 2)
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardBody").text, "Önizleme · Gün 7/10")
	popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
	assert_eq(calls[0], 1)
	assert_eq(popup.reward_amount, 75, "claim returns the current Day 2 award")
	assert_eq(popup.completed_days, 2)


func test_approved_reward_table_claims_persists_and_rejects_double_claim() -> void:
	var owner := FixtureEconomy.new()
	owner._save_path = FIXTURE_PATH
	add_child_autofree(owner)
	for day: int in range(1, 11):
		owner._data = SaveData.new_default()
		owner._data.last_claim_epoch_day = SeedManager.today_epoch() - 1
		owner._data.streak_day = day - 1
		var expected: Dictionary = owner.login_reward_spec(day)
		var result: Dictionary = owner.claim_login_reward_bundle()
		assert_eq(result["coins"], expected["coins"])
		assert_eq(result["boost_ids"], expected["boost_ids"])
		var gift: Dictionary = owner.supply_boxes().box_status(result.get("gift_box_id", ""))
		var extra_coins: int = int(gift.get("amount", 0)) if gift.get("reward_type") == "coins" else 0
		assert_eq(owner.balance(), int(expected["coins"]) + extra_coins)
		for id: StringName in [&"slow_start", &"coin_bonus", &"extra_life"]:
			var base: int = 1 if expected["boost_ids"].has(id) else 0
			var extra: int = int(gift.get("amount", 0)) if gift.get("reward_type") == String(id) else 0
			assert_eq(owner.boost_count(id), base + extra)
		assert_eq(owner.claim_login_reward_bundle(), {})
		assert_false(owner.login_reward_status()["claimable"])
		assert_eq(JSON.parse_string(JSON.stringify(SaveStore.load_from(FIXTURE_PATH).to_dict())), JSON.parse_string(JSON.stringify(owner._data.to_dict())))
		assert_eq(owner._data.streak_day, day)
		owner._data.last_claim_epoch_day -= 1
		assert_eq(owner.login_reward_status()["new_streak"], day + 1 if day < 10 else 1)
		owner._data.last_claim_epoch_day -= 2
		assert_eq(owner.login_reward_status()["new_streak"], 1)

func test_boost_only_reward_is_visible_and_holds_claim_feedback() -> void:
	var popup := _popup(func() -> Dictionary: return {"coins": 0, "boost_ids": [&"extra_life"]})
	popup.present({"claimable": true, "reward": 0, "new_streak": 7})
	assert_false(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/Coin").visible)
	assert_true(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardAmount").visible)
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardAmount").text, "1×")
	assert_true(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/BoostIcon").is_visible_in_tree())
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Currency").text, "Extra Life")
	assert_false(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/SupplyGift").visible)
	assert_null(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route").checkpoints[6].get_node_or_null("SupplyGift"))
	popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
	assert_eq(popup.reward_amount, 0)
	assert_eq(popup.state, DailyRewardPopup.State.CLAIMED)


func test_approved_boost_previews_localize_and_never_mutate_profile() -> void:
	var popup := _popup(func() -> Dictionary: fail_test("preview must never claim"); return {})
	var before: Dictionary = Economy.get("_data").to_dict()
	for locale in ["tr", "en"]:
		TranslationServer.set_locale(locale)
		popup.present({"claimable": true, "reward": 50, "new_streak": 1})
		for day in [3, 5, 7]:
			popup.preview_day(day)
			var id: StringName = Economy.LOGIN_REWARD_BOOSTS[day - 1][0]
			var boost: BoostData = ContentCatalog.boost_by_id(id)
			assert_true(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/BoostIcon").is_visible_in_tree())
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Currency").text, tr(boost.display_name_key))
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/BoostIcon").get("effect"), BoostIcon.COIN_BONUS_ICON if id == &"coin_bonus" else boost.effect)
			assert_true(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Currency").visible)
			assert_eq(popup.current_day, 1)
			assert_eq(Economy.get("_data").to_dict(), before)


func test_day_ten_is_supply_only_and_prominently_shows_cube() -> void:
	var popup := _popup(func() -> Dictionary:
		return {"coins": 0, "boost_ids": [], "supply_box": true, "gift_box_id": "gift-10"})
	popup.present({"claimable": true, "reward": 0, "new_streak": 10})
	assert_false(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/Coin").visible)
	assert_false(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/BoostIcon").visible)
	assert_true(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/SupplyGift").visible)
	assert_gte(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero/SupplyGift").custom_minimum_size.x, 160.0)
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Currency").text, "Supply Box")
	assert_null(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route").checkpoints[9].get_node_or_null("SupplyGift"))
	assert_null(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route").checkpoints[6].get_node_or_null("SupplyGift"))
	popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
	assert_eq(popup.state, DailyRewardPopup.State.CLAIMED)


func test_main_menu_entry_reopens_claimed_today_without_startup_popup() -> void:
	var original: Variant = Economy.get("_data")
	var fixture := SaveData.new_default()
	fixture.tutorial_seen = true
	fixture.last_claim_epoch_day = SeedManager.today_epoch()
	fixture.streak_day = 4
	Economy.set("_data", fixture)
	for locale in ["tr", "en"]:
		TranslationServer.set_locale(locale)
		var menu: Control = MENU.instantiate()
		add_child_autofree(menu)
		await wait_process_frames(4)
		var popup: DailyRewardPopup = menu.get_node("RewardPopup")
		var initial: int = fixture.currency
		assert_false(popup.visible, "claimed startup does not force a popup")
		assert_eq(menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry/Content/Labels/Progress").text, "4/10")
		assert_gte(menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry").size.y, 48.0)
		assert_lt(menu.get_node("SafeArea/Bounds/Frame/Header/SettingsButton").position.x + menu.get_node("SafeArea/Bounds/Frame/Header/SettingsButton").size.x, menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry").position.x)
		assert_lt(menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry").position.x + menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry").size.x, menu.get_node("SafeArea/Bounds/Frame/Header/CoinsPanel").position.x)
		menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry").pressed.emit()
		assert_true(popup.visible)
		assert_eq(popup.reward_amount, 180)
		assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Received").text, "Alındı" if locale == "tr" else "Received")
		assert_eq(popup.get_node("SafeArea/Bounds/Box/Footer/CloseButton").text, "Geri" if locale == "tr" else "Back")
		assert_false(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").visible)
		popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
		assert_eq(fixture.currency, initial)
		popup.close()
		await wait_for_signal(popup.dismissed, 1.0)
		assert_eq(menu.get_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/PlayButton").modulate.a, 1.0)
		menu.get_node("SafeArea/Bounds/Frame/Header/RewardEntry").pressed.emit()
		assert_eq(popup.state, DailyRewardPopup.State.INSPECTING)
		assert_eq(fixture.currency, initial)
	Economy.set("_data", original)


func test_available_entry_close_reopen_and_claim_route_capture() -> void:
	var popup := _popup(func() -> Dictionary: return Economy.login_reward_spec(10))
	popup.present({"claimable": true, "reward": 0, "new_streak": 10})
	popup.close()
	await wait_for_signal(popup.dismissed, 1.0)
	assert_eq(popup.state, DailyRewardPopup.State.HIDDEN)
	popup.present({"claimable": true, "reward": 0, "new_streak": 10}, true)
	popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").pressed.emit()
	assert_eq(popup.completed_days, 10)
	assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route").completed_days, 10)
	assert_true(popup.get_node("SafeArea/Bounds/Box/Footer/CloseButton").disabled)
	popup.preview_day(1)
	assert_eq(popup.preview_spec["coins"], 0, "claim feedback cannot be replaced by preview input")
	await get_tree().create_timer(popup.claimed_hold_duration * 0.5).timeout
	assert_eq(popup.state, DailyRewardPopup.State.CLAIMED, "feedback owns a substantial hold, not an immediate fade")
	assert_eq(popup.modulate.a, 1.0)
	await wait_for_signal(popup.dismissed, 2.0)
	popup.present({"claimable": false, "reward": 0, "new_streak": 10}, true)
	assert_eq(popup.state, DailyRewardPopup.State.INSPECTING)
	assert_false(popup.get_node("SafeArea/Bounds/Box/Footer/ClaimButton").visible)


func test_shared_hero_keeps_route_stable_and_preview_returns_to_today() -> void:
	var popup := _popup(func() -> Dictionary: fail_test("preview must not claim"); return {})
	var hero: Control = popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/Hero")
	var coin: Control = hero.get_node("Coin")
	var boost: Control = hero.get_node("BoostIcon")
	var route: DailyRewardRoute = popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RouteScroll/Route")
	for locale in ["tr", "en"]:
		TranslationServer.set_locale(locale)
		popup.present({"claimable": true, "reward": 180, "new_streak": 4})
		await wait_process_frames(2)
		var route_position: Vector2 = route.get_parent().position
		var hero_position: Vector2 = hero.position
		for day in [3, 5, 7, 10, 4]:
			popup.preview_day(day)
			await wait_process_frames(2)
			var icon: Control = coin if day == 4 else hero.get_node("SupplyGift") if day == 10 else boost
			assert_true(icon.is_visible_in_tree())
			assert_eq(icon.size, coin.size, "each reward uses the same central hero footprint")
			assert_eq(hero.position, hero_position)
			assert_eq(route.get_parent().position, route_position, "preview does not collapse the composition")
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardAmount").text, "+180" if day == 4 else "1×")
			assert_eq(route.current_day, 4)
			assert_eq(route.selected_day, day)
			assert_eq(popup.get_node("SafeArea/Bounds/Box/Scroll/Body/Content/RewardBody").text, tr("DAILY_REWARD_DAY") % 4 if day == 4 else tr("DAILY_REWARD_PREVIEW") % day)
			for checkpoint in route.checkpoints:
				assert_eq(checkpoint.tooltip_text, "", "hero and status replace checkpoint tooltips")
