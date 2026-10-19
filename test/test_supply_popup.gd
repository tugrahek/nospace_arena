extends "res://test/helpers/supply_acquisition_fixture.gd"

const POPUP: PackedScene = preload("res://scenes/ui/SupplyPopup.tscn")
const MENU: PackedScene = preload("res://scenes/main/MainMenu.tscn")
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")
var _popup: SupplyPopup


func before_each() -> void:
	super.before_each()
	_popup = _make_popup(_economy, _acquisition)


func after_each() -> void:
	TranslationServer.set_locale("en")
	super.after_each()


func _make_popup(economy_node: Node, acquisition_node: SupplyBoxAcquisition) -> SupplyPopup:
	var popup: SupplyPopup = POPUP.instantiate()
	popup.economy = economy_node
	popup.ads = _ads
	popup.acquisition = acquisition_node
	popup.core = economy_node.supply_boxes()
	popup.reveal_duration = 0.0
	add_child_autofree(popup)
	return popup


func test_scene_open_close_and_localization() -> void:
	assert_false(_popup.visible)
	for locale: String in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		_popup.present()
		assert_true(_popup.visible)
		assert_eq(_popup._title.text, "Ödül Kutusu" if locale == "tr" else "Supply Box")
		assert_eq(_popup._ad.text, "Reklam İzle" if locale == "tr" else "Watch Ad")
		assert_eq(_popup._coin.text, "150 Jeton" if locale == "tr" else "150 Coins")
		_popup.close()
		assert_false(_popup.visible)
	assert_eq(_economy.writes, 0)


func test_rewarded_available_and_unavailable_readiness() -> void:
	_popup.present()
	assert_true(_popup.daily_available())
	assert_false(_popup._ad.disabled)
	_ads.set_requests_allowed(false)
	_popup.refresh()
	assert_true(_popup._ad.disabled)
	assert_true(_popup.daily_available(), "daily allowance stays available while ads are unavailable")
	assert_false(_popup._ad.get_parent().visible)


func test_cancel_returns_ready_without_grant_and_duplicate_tap_is_ignored() -> void:
	_popup.present()
	_popup._ad.pressed.emit()
	_popup._ad.pressed.emit()
	assert_eq(_fake.show_tokens.size(), 1)
	_fake.close(_fake.show_tokens.back())
	await wait_process_frames(2)
	assert_eq(_popup.state, SupplyPopup.State.READY)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.status()["rewarded_count"], 0)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)


func test_ad_failure_and_no_fill_do_not_reveal_or_grant() -> void:
	_popup.present()
	_popup._ad.pressed.emit()
	_fake.fail(_fake.show_tokens.back(), &"show_failed")
	await wait_process_frames(2)
	assert_eq(_popup.state, SupplyPopup.State.READY)
	assert_false(_popup._feedback.text.is_empty())
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_eq(_acquisition.status()["rewarded_count"], 0)
	assert_true(_ads.preload_rewarded())
	_fake.fail(_fake.load_tokens.back(), &"no_fill")
	await wait_process_frames(2)
	assert_true(_popup._ad.disabled)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)


func test_verified_reward_reveals_exact_durable_outcome() -> void:
	_popup.present()
	_popup._ad.pressed.emit()
	var token: int = _fake.show_tokens.back()
	_fake.earn_reward(token)
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_eq(_popup.state, SupplyPopup.State.REVEAL)
	assert_eq(_popup._reward.text, "Slow Start ×1")
	assert_eq(_popup.revealed_box_id, _box_id())
	assert_eq(SaveStore.load_from(PATH).supply_boxes[_box_id()]["state"], "delivered")
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	assert_false(_popup.daily_available())
	assert_false(_popup._surface.visible)
	assert_true(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)
	_popup._continue.pressed.emit()
	_fake.complete_load(_fake.load_tokens.back())
	_popup.present()
	assert_false(_popup._ad.get_parent().visible)
	assert_true(_popup._coin.get_parent().visible)
	assert_false(_popup._coin.disabled)


func test_coin_button_calls_canonical_atomic_path_and_shows_only_reward() -> void:
	_ads.set_requests_allowed(false)
	_popup.present()
	_popup._coin.pressed.emit()
	_popup._coin.pressed.emit()
	assert_eq(_economy.writes, 2)
	assert_eq(_economy.balance(), 350)
	assert_eq(_acquisition.status()["coin_count"], 1)
	assert_eq(_popup.state, SupplyPopup.State.REVEAL)
	assert_eq(_popup._reward.text, "Slow Start ×1")
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/Surface/Inventory"))
	assert_true(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)
	assert_eq(_economy._data.supply_boxes.size(), 1)


func test_insufficient_balance_and_daily_limit_have_clear_disabled_states() -> void:
	_economy._data.currency = 149
	_popup.present()
	assert_true(_popup._coin.disabled)
	assert_true(_popup._coin.text.contains("150"))
	_popup._coin.pressed.emit()
	assert_eq(_economy.writes, 0)
	_economy._data.currency = 1000
	_economy._data.supply_acquisition_days[str(_day[0])] = {"coin_count": 2, "rewarded_count": 0}
	_popup.refresh()
	assert_true(_popup._coin.disabled)
	assert_true(_popup._coin.disabled)
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/CoinRow/Remaining"))
	_popup._coin.pressed.emit()
	assert_eq(_economy.writes, 0)


func test_external_economy_signals_refresh_affordability_without_inventory() -> void:
	_popup.present()
	_economy._data.currency = 12
	_economy.currency_changed.emit(12)
	assert_true(_popup._coin.disabled)
	assert_true(_popup._coin.disabled)
	_economy._data.add_boost(&"extra_life", 2)
	_economy.boosts_changed.emit()
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/Surface/Inventory"))


func test_all_persisted_rewards_localize_without_selecting_in_ui() -> void:
	for spec: Array in [[&"coins", 100, "100 Coins"], [&"slow_start", 1, "Slow Start ×1"],
			[&"coins", 200, "200 Coins"], [&"coins", 500, "500 Coins"],
			[&"coin_bonus", 1, "Coin Bonus ×1"], [&"extra_life", 1, "Extra Life ×1"]]:
		var id: String = "fixture/" + String(spec[0]) + str(spec[1])
		_config.reward_table.entries[0].reward_type = spec[0]
		_config.reward_table.entries[0].amount = spec[1]
		assert_true(_economy.supply_boxes().reserve(id, "fixture", "context", _config.reward_table))
		assert_true(_economy.supply_boxes()._authorize(id, "fixture", "context"))
		assert_true(_economy.supply_boxes().deliver(id))
		_config.reward_table.entries[0].amount = 999
		_popup.present()
		assert_eq(_popup._reward.text, spec[2])
		var before: Dictionary = _economy._data.to_dict()
		_popup.present()
		assert_eq(_economy._data.to_dict(), before)
		_popup._continue.pressed.emit()
		assert_true(_economy.supply_boxes().unpresented_deliveries().is_empty())


func test_reveal_survives_reload_without_another_grant_and_continue_persists() -> void:
	_ads.set_requests_allowed(false)
	var result: Dictionary = _acquisition.purchase_coin_box("reload", _day[0])
	assert_true(result["delivered"])
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	var recovery: SupplyBoxAcquisition = _make_acquisition(reloaded)
	var popup: SupplyPopup = _make_popup(reloaded, recovery)
	popup.present()
	assert_eq(popup._reward.text, "Slow Start ×1")
	assert_eq(reloaded.boost_count(&"slow_start"), 1)
	assert_eq(reloaded.balance(), 350)
	popup._continue.pressed.emit()
	assert_false(popup.visible)
	assert_true(SaveStore.load_from(PATH).supply_boxes[result["box_id"]]["presented"])
	popup.present()
	assert_eq(popup.state, SupplyPopup.State.READY)
	assert_false(popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)
	assert_eq(reloaded.boost_count(&"slow_start"), 1)


func test_closing_popup_during_ad_keeps_delivery_for_next_open() -> void:
	_popup.present()
	_popup._ad.pressed.emit()
	var token: int = _fake.show_tokens.back()
	_popup.close()
	_fake.earn_reward(token)
	_fake.close(token)
	await wait_process_frames(2)
	assert_false(_popup.visible)
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	_popup.present()
	assert_eq(_popup.state, SupplyPopup.State.REVEAL)
	assert_eq(_popup._reward.text, "Slow Start ×1")
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_failed_delivery_is_not_revealed_until_recovery_succeeds() -> void:
	_ads.set_requests_allowed(false)
	_popup.present()
	_economy.fail_at = 2
	_popup._coin.pressed.emit()
	assert_eq(_popup.state, SupplyPopup.State.READY)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)
	assert_eq(_economy.balance(), 350)
	assert_eq(_economy.boost_count(&"slow_start"), 0)
	assert_false(_popup._feedback.text.is_empty())
	_acquisition.recover()
	assert_eq(_popup.state, SupplyPopup.State.REVEAL)
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_failed_presentation_save_retains_reveal_and_never_regrants() -> void:
	_ads.set_requests_allowed(false)
	_popup.present()
	_popup._coin.pressed.emit()
	_economy.fail_at = _economy.writes + 1
	_popup._continue.pressed.emit()
	assert_true(_popup.visible)
	assert_eq(_popup.state, SupplyPopup.State.REVEAL)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/RevealView/Scroll/Body/Content/Feedback").text.is_empty())
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	assert_eq(_economy.supply_boxes().unpresented_deliveries().size(), 1)
	_popup._continue.pressed.emit()
	assert_false(_popup.visible)
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_synchronous_reward_close_reveals_and_clears_ui_busy_token() -> void:
	_popup.free()
	_acquisition.free()
	_ads.free()
	_make_ads(ImmediateAds.new())
	_acquisition = _make_acquisition(_economy)
	_popup = _make_popup(_economy, _acquisition)
	_popup.present()
	_popup._ad.pressed.emit()
	await wait_process_frames(2)
	assert_eq(_popup.state, SupplyPopup.State.REVEAL)
	assert_eq(_popup._ad_token, 0)
	assert_eq(_economy.boost_count(&"slow_start"), 1)
	_popup._continue.pressed.emit()
	_popup.present()
	assert_eq(_popup.state, SupplyPopup.State.READY)


func test_reserved_or_unknown_reward_cannot_be_marked_presented_or_revealed() -> void:
	assert_true(_economy.supply_boxes().reserve("reserved", "fixture", "context", _config.reward_table))
	assert_false(_economy.supply_boxes().mark_presented("reserved"))
	assert_false(_economy.supply_boxes().mark_presented("missing"))
	_popup.present()
	_popup._reveal("reserved")
	assert_eq(_popup.state, SupplyPopup.State.READY)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)
	assert_eq(_economy.boost_count(&"slow_start"), 0)


func test_main_menu_has_no_supply_indicator_or_utility_entry() -> void:
	var menu: Control = MENU.instantiate()
	assert_false(menu.has_node("SupplyEntry"))
	assert_false(menu.has_node("SupplyPopup"))
	assert_false(menu.has_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub/StoreButton/Content/Icon/SupplyBadge"))
	assert_eq(menu.get_node("SafeArea/Bounds/Frame/ContentGroup/Footer/Buttons/NavigationHub").get_child_count(), 4)
	assert_eq(menu.STORE_SCENE, "res://scenes/ui/Store.tscn")
	menu.free()

func test_store_supply_category_is_reachable_without_changing_other_offers() -> void:
	var store: Control = preload("res://scenes/ui/Store.tscn").instantiate()
	var badge: SupplyStoreBadge = store.get_node("SafeArea/Bounds/Frame/CategoryStrip/Tabs/Supply/SupplyBadge")
	badge.acquisition = _acquisition
	badge.ads = _ads
	add_child_autofree(store)
	assert_eq(store.active_category(), store.Category.CHARACTERS)
	assert_true(badge.visible)
	_economy._data.supply_acquisition_days[str(_day[0])] = {"coin_count": 0, "rewarded_count": 1}
	badge.refresh()
	assert_false(badge.visible)
	_day[0] += 1
	badge.refresh()
	assert_true(badge.visible)
	assert_true(_ads.is_rewarded_available())
	assert_true(_ads.show_rewarded("badge-test") > 0)
	assert_false(badge.visible, "badge hides as soon as the ready ad is shown")
	_fake.close(_fake.show_tokens.back())
	assert_false(badge.visible, "badge stays hidden while no fresh ad is ready")
	_load()
	assert_true(badge.visible, "badge returns when an ad becomes ready again")
	store.get_node("SafeArea/Bounds/Frame/CategoryStrip/Tabs/Supply").pressed.emit()
	await wait_process_frames(2)
	assert_eq(store.active_category(), store.Category.SUPPLY)
	assert_same(badge.get_parent(), store.get_node("SafeArea/Bounds/Frame/CategoryStrip/Tabs/Supply"))
	assert_true(store.get_node("SafeArea/Bounds/Frame/CategoryStrip/Tabs/Supply").get_global_rect().encloses(badge.get_global_rect()))
	var tab: Button = store.get_node("SafeArea/Bounds/Frame/CategoryStrip/Tabs/Supply")
	assert_gt(badge.position.x, tab.size.x * 0.75, "badge is anchored at the tab's top-right")
	assert_lt(badge.position.y, tab.size.y * 0.3, "badge stays in the tab's upper edge")
	var offering: SupplyPopup = store.get_node("SafeArea/Bounds/Frame/Scroll/List/SupplyPopup")
	assert_true(offering.visible)
	assert_true(offering.embedded)
	assert_false(offering.has_node("Dim"))
	assert_false(offering.has_node("SafeArea/Bounds/Frame/Surface/Inventory"))
	assert_false(offering.has_node("SafeArea/Bounds/Frame/Surface/Hint"))
	store.set_category(store.Category.BOOSTS)
	await wait_process_frames(2)
	assert_eq(store.offer_count(), ContentCatalog.BOOSTS.size())
	assert_eq(store.MENU_SCENE, "res://scenes/main/MainMenu.tscn")


func test_coin_bonus_icons_are_distinct_in_store_selector_and_showcase() -> void:
	var tile := StoreOfferTile.new()
	tile.configure_selector(StoreOfferTile.Kind.BOOST, &"coin_bonus", 0, "Coin Bonus", true,
		BoostData.Effect.COIN_BONUS)
	var tile_icon: Control = tile.get_node("Content/Visual").get_child(0)
	assert_eq(tile_icon.get("effect"), BoostIcon.COIN_BONUS_ICON)
	tile.free()
	var showcase := StoreShowcase.new()
	var bonus: BoostData = ContentCatalog.boost_by_id(&"coin_bonus")
	showcase.configure_boost(bonus.id, bonus, 1, true)
	var showcase_icon: Control = showcase.get_child(0).get_child(0)
	assert_eq(showcase_icon.get("effect"), BoostIcon.COIN_BONUS_ICON)
	showcase.free()


func test_action_order_compact_limits_and_separate_ad_message() -> void:
	_popup.present()
	assert_lt(_popup.get_node("SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/AdRow").get_index(), _popup.get_node("SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/CoinRow").get_index())
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/AdRow/Status/AdLimit"))
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/Surface/Scroll/Body/Content/CoinRow/Remaining"))
	_ads.set_requests_allowed(false)
	_popup.refresh()
	assert_true(_popup._ad.disabled)
	assert_eq(_popup._ad.text, "Watch Ad")
	assert_false(_popup._ad.get_parent().visible)


func test_odds_info_displays_resource_percentages_only_when_opened() -> void:
	_acquisition._config = SupplyBoxAcquisition.CONFIG
	_popup.present()
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/OddsView").visible)
	var before: Dictionary = _economy._data.to_dict()
	_popup._odds.pressed.emit()
	assert_true(_popup.get_node("SafeArea/Bounds/Frame/OddsView").visible)
	assert_false(_popup._surface.visible)
	assert_eq(_popup.get_node("SafeArea/Bounds/Frame/OddsView/Scroll/Body/Content/Rows").get_child_count(), 4)
	assert_eq(_popup.get_node("SafeArea/Bounds/Frame/OddsView/Scroll/Body/Content/Rows").get_child(0).get_node("Name").text, "Coins")
	assert_eq(_popup.get_node("SafeArea/Bounds/Frame/OddsView/Scroll/Body/Content/Rows").get_child(0).get_node("Probability").text, "35%")
	var coin_tiers: Array[int] = []
	var coin_weight: float = 0.0
	for entry: SupplyRewardEntry in _acquisition._config.reward_table.entries:
		if entry.reward_type == &"coins":
			coin_tiers.append(entry.amount)
			coin_weight += entry.weight
	assert_eq(coin_tiers, [100, 200, 500], "the 35% coin category contains three configured tiers")
	assert_eq(coin_weight, 105.0, "coin tiers contribute the full 35% category weight")
	var bonus_row: Control = _popup.get_node("SafeArea/Bounds/Frame/OddsView/Scroll/Body/Content/Rows").get_child(2)
	assert_eq(bonus_row.get_node("Icon").get("effect"), BoostIcon.COIN_BONUS_ICON)
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/OddsView/CoinValues"))
	assert_eq(_economy._data.to_dict(), before)
	TranslationServer.set_locale("tr")
	_popup.hide_odds()
	_popup.show_odds()
	assert_eq(_popup.get_node("SafeArea/Bounds/Frame/OddsView/Scroll/Body/Content/Rows").get_child(0).get_node("Name").text, tr("HUD_CURRENCY"))
	assert_eq(_popup.get_node("SafeArea/Bounds/Frame/OddsView/Title").text, "Ödül Olasılıkları")
	assert_eq(_popup.get_node("SafeArea/Bounds/Frame/OddsView/Footer/Back").text, "Kutuya Dön")
	assert_eq(_popup._close.text, "Kapat", "general close keeps its existing caption")
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/OddsView/CoinValues"))
	_popup.get_node("SafeArea/Bounds/Frame/OddsView/Footer/Back").pressed.emit()
	assert_true(_popup._surface.visible)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/OddsView").visible)


func test_odds_view_title_and_return_button_fit_reference_viewports() -> void:
	var viewport: Viewport = get_viewport()
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280)]:
		viewport.size = dimensions
		_popup.visible = true
		_popup.state = SupplyPopup.State.READY
		_popup.show_odds()
		await wait_process_frames(4)
		var odds: Control = _popup.get_node("SafeArea/Bounds/Frame/OddsView")
		var title: Control = _popup.get_node("SafeArea/Bounds/Frame/OddsView/Title")
		var back: Control = _popup.get_node("SafeArea/Bounds/Frame/OddsView/Footer/Back")
		assert_true(odds.get_global_rect().encloses(title.get_global_rect()), "title stays in odds frame at %s" % dimensions)
		assert_true(odds.get_global_rect().encloses(back.get_global_rect()), "back stays in odds frame at %s" % dimensions)
		assert_false(title.get_global_rect().intersects(back.get_global_rect()), "title and footer stay separate at %s" % dimensions)
	viewport.size = Vector2i(720, 1280)


func test_embedded_continue_returns_to_acquisition_without_inventory_or_regrant() -> void:
	_ads.set_requests_allowed(false)
	_popup.embedded = true
	_popup.present()
	_popup._coin.pressed.emit()
	assert_true(_popup.get_node("SafeArea/Bounds/Frame/RevealView").visible)
	assert_false(_popup._surface.visible)
	assert_false(_popup.get_node("SafeArea/Bounds/Frame/OddsView").visible)
	_popup._continue.pressed.emit()
	assert_true(_popup.visible)
	assert_true(_popup._surface.visible)
	assert_eq(_popup.state, SupplyPopup.State.READY)
	assert_eq(_economy.boost_count(&"slow_start"), 1)


func test_rewarded_ready_hides_coin_fallback_and_no_fill_restores_it() -> void:
	_popup.present()
	assert_false(_popup._ad.disabled)
	assert_false(_popup._coin.get_parent().visible)
	assert_true(_popup._coin.disabled)
	assert_false(_popup.has_node("SafeArea/Bounds/Frame/Surface/Category"))
	_ads.set_requests_allowed(false)
	_popup.refresh()
	assert_true(_popup._ad.disabled)
	assert_true(_popup._coin.get_parent().visible)
	assert_false(_popup._coin.disabled)


func test_variable_coin_tiers_persist_and_reveal_without_reroll() -> void:
	_ads.set_requests_allowed(false)
	_config.reward_table.entries[0].reward_type = &"coins"
	_popup.embedded = true
	for amount: int in [100, 200, 500]:
		_config.reward_table.entries[0].amount = amount
		_popup.present()
		_popup._coin.pressed.emit()
		var id: String = _popup.revealed_box_id
		assert_eq(_popup._reward.text, "%d Coins" % amount)
		assert_eq(int(SaveStore.load_from(PATH).supply_boxes[id]["amount"]), amount)
		assert_eq(SaveStore.load_from(PATH).supply_boxes[id]["state"], "delivered")
		var balance: int = _economy.balance()
		assert_false(_economy.supply_boxes().deliver(id))
		assert_eq(_economy.balance(), balance)
		_popup._continue.pressed.emit()
		_day[0] += 1
