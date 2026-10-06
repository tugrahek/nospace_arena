extends GutTest

const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const Service = preload("res://scripts/monetization/ads_service.gd")
const FakeBackend = preload("res://scripts/monetization/fake_ads_backend.gd")
const BonusButton = preload("res://scripts/ui/results_rewarded_bonus.gd")
const Profile = preload("res://scripts/meta/save_data.gd")
const Store = preload("res://scripts/meta/save_store.gd")
const PATH: String = "user://23c2_results_bonus_fixture.json"

class SynchronousBackend:
	extends "res://scripts/monetization/fake_ads_backend.gd"
	var fail_show: bool = false
	func show_rewarded(token: int) -> void:
		super.show_rewarded(token)
		if fail_show:
			fail(token, &"show_failed")
		else:
			earn_reward(token)
			close(token)

var _service: Service
var _fake: FakeBackend
var _hud: HUD
var _button: BonusButton
var _old_data: Profile
var _old_path: String
var _old_bonus: Array


func before_each() -> void:
	_old_data = Economy._data
	_old_path = Economy._save_path
	_old_bonus = [Economy._bonus_context_id, Economy._bonus_base_payout,
		Economy._bonus_epoch_day, Economy._bonus_context_prepared]
	Economy._data = Profile.new_default()
	Economy._save_path = PATH
	GameState.reset()
	_service = Service.new()
	_fake = FakeBackend.new()
	_service.configure_backend(_fake)
	_service.set_requests_allowed(true)
	add_child_autofree(_service)
	_fake.complete_initialization(_fake.initialization_tokens.back())
	_hud = HUD_SCENE.instantiate()
	_button = _hud.get_node("ResultPanel/VBox/RewardedBonusButton")
	_button.ads_service = _service
	add_child_autofree(_hud)
	_hud.setup(3)


func after_each() -> void:
	GameState.reset()
	Economy._data = _old_data
	Economy._save_path = _old_path
	Economy._bonus_context_id = _old_bonus[0]
	Economy._bonus_base_payout = _old_bonus[1]
	Economy._bonus_epoch_day = _old_bonus[2]
	Economy._bonus_context_prepared = _old_bonus[3]
	TranslationServer.set_locale("en")
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func _finish(base: int = 100, finalize: bool = true) -> void:
	GameState.start_run(1)
	GameState.win_run()
	Economy.earn(base)
	Economy.prepare_rewarded_mission_bonus(base)
	if finalize:
		_hud.finalize_result_rewards()


func _ready_ad() -> void:
	_service.preload_rewarded()
	_fake.complete_load(_fake.load_tokens.back())


func _tap() -> int:
	_button.pressed.emit()
	return _fake.show_tokens.back()


func test_eligible_ready_offer_waits_for_finalized_results_and_localizes() -> void:
	_ready_ad()
	_finish(101, false)
	assert_false(_button.visible)
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		_hud.finalize_result_rewards()
		assert_true(_button.visible)
		assert_false(_button.disabled)
		assert_eq(_button.text, "Watch Ad +50" if locale == "en" else "Reklam İzle +50")
	assert_eq(_button.theme_type_variation, &"Secondary")


func test_zero_payout_hides_offer_without_requesting_ad() -> void:
	_finish(0)
	assert_false(_button.visible)
	assert_eq(_fake.load_tokens.size(), 0)
	_button.pressed.emit()
	assert_eq(_fake.show_tokens.size(), 0)


func test_already_claimed_today_hides_offer() -> void:
	Economy._data.rewarded_mission_bonus_epoch_day = SeedManager.today_epoch()
	_ready_ad()
	_finish()
	assert_false(_button.visible)
	assert_false(_button.is_visible_in_tree())


func test_unavailable_no_fill_does_not_block_normal_navigation() -> void:
	_finish()
	assert_false(_button.visible)
	_fake.fail(_fake.load_tokens.back(), &"no_fill")
	await get_tree().process_frame
	assert_false(_button.visible)
	var counts := [0, 0, 0]
	_hud.retry_pressed.connect(func() -> void: counts[0] += 1)
	_hud.menu_pressed.connect(func() -> void: counts[1] += 1)
	_hud.next_pressed.connect(func() -> void: counts[2] += 1)
	_hud.show_campaign_stars(3, false, true)
	for name in ["ButtonRow/RetryButton", "ButtonRow/MenuButton", "NextButton"]:
		var button: Button = _hud.get_node("ResultPanel/VBox/" + name)
		assert_false(button.disabled)
		button.pressed.emit()
	assert_eq(counts, [1, 1, 1])


func test_tap_locks_and_deduplicates_show_without_granting_coins() -> void:
	_ready_ad()
	_finish()
	_tap()
	assert_true(_button.disabled)
	_button.pressed.emit()
	assert_eq(_fake.show_tokens.size(), 1)
	assert_eq(Economy.balance(), 100)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)


func test_matching_reward_claims_exactly_once_and_updates_real_currency() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_fake.earn_reward(token)
	_fake.earn_reward(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 150)
	assert_eq(Store.load_from(PATH).currency, 150)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, SeedManager.today_epoch())
	assert_eq(_hud.get_node("CurrencyLabel").text, tr("HUD_CURRENCY") + ": 150")
	assert_false(_button.visible)
	_fake.close(token)
	await get_tree().process_frame
	assert_false(_hud.get_node("ResultPanel/VBox/ButtonRow/RetryButton").disabled)
	assert_false(_hud.get_node("ResultPanel/VBox/ButtonRow/MenuButton").disabled)


func test_close_without_reward_cancels_claim_and_late_reward_grants_nothing() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_fake.close(token)
	_fake.earn_reward(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)
	assert_false(_button.visible)


func test_show_failure_grants_nothing() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_fake.fail(token, &"show_failed")
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_false(_button.visible)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)


func test_wrong_token_or_context_cannot_claim() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_fake.earn_reward(token + 1)
	_service.reward_earned.emit("wrong_context", token)
	_service.reward_earned.emit(_button._ad_context, token + 1)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	_fake.earn_reward(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 150)


func test_callback_for_prior_run_cannot_claim_after_retry() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	GameState.start_run(1)
	_fake.earn_reward(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_false(_button.visible)


func test_scene_freed_before_callback_is_safe_and_grants_nothing() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_hud.queue_free()
	await get_tree().process_frame
	_fake.earn_reward(token)
	_fake.close(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)


func test_synchronous_backend_reward_and_close_are_correlated() -> void:
	var service: Service = Service.new()
	var fake := SynchronousBackend.new()
	service.configure_backend(fake)
	service.set_requests_allowed(true)
	add_child_autofree(service)
	fake.complete_initialization(fake.initialization_tokens.back())
	var button: BonusButton = BonusButton.new()
	button.ads_service = service
	add_child_autofree(button)
	_finish()
	button.present()
	fake.complete_load(fake.load_tokens.back())
	button.pressed.emit()
	await get_tree().process_frame
	assert_eq(Economy.balance(), 150)
	assert_false(button.visible)
	assert_eq(fake.show_tokens.size(), 1)


func test_synchronous_show_failure_leaves_no_offer_or_claim() -> void:
	var service: Service = Service.new()
	var fake := SynchronousBackend.new()
	fake.fail_show = true
	service.configure_backend(fake)
	service.set_requests_allowed(true)
	add_child_autofree(service)
	fake.complete_initialization(fake.initialization_tokens.back())
	var button: BonusButton = BonusButton.new()
	button.ads_service = service
	add_child_autofree(button)
	_finish()
	button.present()
	fake.complete_load(fake.load_tokens.back())
	button.pressed.emit()
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_false(button.visible)


func test_results_hidden_then_restored_cannot_accept_old_reward() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	var panel: Control = _hud.get_node("ResultPanel")
	panel.hide()
	panel.show()
	_fake.earn_reward(token)
	_fake.close(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_false(_button.visible)


func test_hud_queued_for_deletion_rejects_callback_before_actual_free() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_hud.queue_free()
	_fake.earn_reward(token)
	_fake.close(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 100)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)


func test_background_foreground_while_loading_preserves_single_request() -> void:
	_finish()
	var token: int = _fake.load_tokens.back()
	_hud.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_service.notification(NOTIFICATION_APPLICATION_PAUSED)
	_hud.finalize_result_rewards()
	assert_eq(_service.state, Service.State.LOADING)
	assert_eq(_fake.load_tokens.size(), 1)
	assert_false(_button.visible)
	_fake.complete_load(token)
	_hud.propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	_service.notification(NOTIFICATION_APPLICATION_RESUMED)
	assert_true(_button.visible)
	assert_eq(_fake.load_tokens.size(), 1)
	assert_eq(Economy.balance(), 100)


func test_background_reward_close_then_foreground_claims_once() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_hud.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_hud.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_service.notification(NOTIFICATION_APPLICATION_PAUSED)
	_button.pressed.emit()
	_hud.finalize_result_rewards()
	_fake.earn_reward(token)
	_fake.close(token)
	_fake.close(token)
	_hud.propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	_hud.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_service.notification(NOTIFICATION_APPLICATION_RESUMED)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 150)
	assert_eq(_fake.show_tokens.size(), 1)
	assert_eq(_fake.load_tokens.size(), 1)
	assert_false(_button.visible)


func test_old_callbacks_do_not_reward_new_results_or_end_new_show() -> void:
	_ready_ad()
	_finish()
	var old_token: int = _tap()
	_fake.close(old_token)
	await get_tree().process_frame
	_finish(60)
	_ready_ad()
	var token: int = _tap()
	_fake.earn_reward(old_token)
	_fake.close(old_token)
	_fake.fail(old_token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 160)
	assert_eq(_service.state, Service.State.SHOWING)
	assert_true(_button.disabled)
	_fake.earn_reward(token)
	_fake.close(token)
	await get_tree().process_frame
	assert_eq(Store.load_from(PATH).currency, 190)


func test_new_results_scene_during_old_show_cannot_take_old_reward() -> void:
	_ready_ad()
	_finish()
	var token: int = _tap()
	_hud.queue_free()
	await get_tree().process_frame
	_hud = HUD_SCENE.instantiate()
	_button = _hud.get_node("ResultPanel/VBox/RewardedBonusButton")
	_button.ads_service = _service
	add_child_autofree(_hud)
	_finish(60)
	assert_false(_button.visible)
	_fake.earn_reward(token)
	_fake.close(token)
	await get_tree().process_frame
	assert_eq(Economy.balance(), 160)
	assert_eq(Store.load_from(PATH).rewarded_mission_bonus_epoch_day, -1)
