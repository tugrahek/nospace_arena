extends GutTest

## Pure service lifecycle coverage. No SDK, economy, real ads, or persistent writes.
const Service = preload("res://scripts/monetization/ads_service.gd")
const FakeBackend = preload("res://scripts/monetization/fake_ads_backend.gd")
const NoopBackend = preload("res://scripts/monetization/noop_ads_backend.gd")

class Caller:
	extends Node
	func received_reward(_context: String, _token: int) -> void:
		pass

var _service: Service
var _fake: FakeBackend


func before_each() -> void:
	_service = Service.new()
	_fake = FakeBackend.new()
	_service.configure_backend(_fake)
	_service.set_requests_allowed(true)
	add_child_autofree(_service)
	_fake.complete_initialization(_fake.initialization_tokens.back())
	watch_signals(_service)


func _load_ready() -> void:
	assert_true(_service.preload_rewarded())
	_fake.complete_load(_fake.load_tokens.back())


func test_noop_boot_and_project_autoload_remain_unavailable() -> void:
	var noop: Service = Service.new()
	watch_signals(noop)
	add_child_autofree(noop)
	assert_eq(noop.state, Service.State.UNAVAILABLE)
	assert_false(noop.is_rewarded_available())
	assert_false(noop.preload_rewarded())
	assert_eq(noop.show_rewarded("run"), 0)
	assert_signal_emitted_with_parameters(noop, "ads_unavailable", [&"sdk_unavailable"])
	assert_signal_not_emitted(noop, "reward_earned")
	assert_eq(AdsService.state, Service.State.UNAVAILABLE, "real autoload uses the no-op backend")
	assert_false(AdsService.is_rewarded_available())


func test_network_backend_waits_for_explicit_permission() -> void:
	var service: Service = Service.new()
	var fake: FakeBackend = FakeBackend.new()
	service.configure_backend(fake)
	watch_signals(service)
	add_child_autofree(service)
	assert_true(fake.initialization_tokens.is_empty())
	assert_signal_emitted_with_parameters(service, "ads_unavailable", [&"privacy_blocked"])
	assert_false(service.preload_rewarded())
	service.set_requests_allowed(true)
	service.initialize()
	assert_eq(fake.initialization_tokens.size(), 1)
	assert_eq(service.state, Service.State.INITIALIZING)


func test_initialization_and_load_reject_overlapping_work() -> void:
	_service.initialize()
	assert_eq(_fake.initialization_tokens.size(), 1)
	assert_true(_service.preload_rewarded())
	assert_false(_service.preload_rewarded())
	assert_eq(_fake.load_tokens.size(), 1)
	assert_eq(_service.show_rewarded("early"), 0)
	assert_true(_fake.show_tokens.is_empty())


func test_fake_load_to_ready_emits_once() -> void:
	_load_ready()
	assert_eq(_service.state, Service.State.READY)
	assert_true(_service.is_rewarded_available())
	_fake.complete_load(_fake.load_tokens.back())
	assert_signal_emit_count(_service, "rewarded_ready", 1)
	assert_false(_service.preload_rewarded(), "ready inventory is not replaced")


func test_show_reward_then_close_keeps_distinct_events() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("mission-run-1")
	assert_gt(token, 0)
	assert_eq(_service.state, Service.State.SHOWING)
	assert_false(_service.is_rewarded_available())
	_fake.earn_reward(token)
	assert_eq(_service.state, Service.State.REWARDED)
	assert_signal_emitted_with_parameters(_service, "reward_earned", ["mission-run-1", token])
	assert_signal_not_emitted(_service, "ad_closed")
	_fake.close(token)
	assert_eq(_service.state, Service.State.CLOSED)
	assert_signal_emitted_with_parameters(_service, "ad_closed", ["mission-run-1", token])


func test_close_without_reward_never_grants_reward() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("cancelled")
	_fake.close(token)
	assert_eq(_service.state, Service.State.CLOSED)
	assert_signal_not_emitted(_service, "reward_earned")
	assert_signal_emit_count(_service, "ad_closed", 1)


func test_no_fill_is_reported_and_can_be_retried() -> void:
	_service.preload_rewarded()
	var token: int = _fake.load_tokens.back()
	_fake.fail(token)
	assert_eq(_service.state, Service.State.FAILED)
	assert_signal_emitted_with_parameters(_service, "ad_failed", ["", token, &"no_fill"])
	assert_false(_service.is_rewarded_available())
	assert_signal_not_emitted(_service, "reward_earned")
	_load_ready()
	assert_true(_service.is_rewarded_available())


func test_initialization_failure_can_retry_without_old_callback() -> void:
	var service: Service = Service.new()
	var fake: FakeBackend = FakeBackend.new()
	service.configure_backend(fake)
	service.set_requests_allowed(true)
	add_child_autofree(service)
	var old_token: int = fake.initialization_tokens.back()
	fake.fail(old_token, &"initialization_failed")
	assert_eq(service.state, Service.State.FAILED)
	service.initialize()
	fake.complete_initialization(old_token)
	assert_eq(service.state, Service.State.INITIALIZING)
	fake.complete_initialization(fake.initialization_tokens.back())
	assert_eq(service.state, Service.State.IDLE)


func test_show_failure_invalidates_late_reward_and_close() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("failed-show")
	_fake.fail(token, &"show_failed")
	_fake.earn_reward(token)
	_fake.close(token)
	assert_eq(_service.state, Service.State.FAILED)
	assert_signal_emitted_with_parameters(_service, "ad_failed", ["failed-show", token, &"show_failed"])
	assert_signal_not_emitted(_service, "reward_earned")
	assert_signal_not_emitted(_service, "ad_closed")
	assert_true(_service.preload_rewarded())


func test_duplicate_reward_and_close_are_ignored() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("duplicate")
	_fake.earn_reward(token)
	_fake.earn_reward(token)
	_fake.close(token)
	_fake.close(token)
	assert_signal_emit_count(_service, "reward_earned", 1)
	assert_signal_emit_count(_service, "ad_closed", 1)


func test_reward_after_close_is_stale() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("late-reward")
	_fake.close(token)
	_fake.earn_reward(token)
	assert_signal_not_emitted(_service, "reward_earned")
	assert_eq(_service.state, Service.State.CLOSED)


func test_old_request_cannot_affect_new_request_even_with_same_context() -> void:
	_load_ready()
	var old_token: int = _service.show_rewarded("same-context")
	_fake.close(old_token)
	_load_ready()
	var new_token: int = _service.show_rewarded("same-context")
	assert_ne(old_token, new_token)
	_fake.earn_reward(old_token)
	_fake.close(old_token)
	_fake.fail(old_token)
	assert_eq(_service.state, Service.State.SHOWING)
	assert_signal_not_emitted(_service, "reward_earned")
	_fake.earn_reward(new_token)
	assert_signal_emitted_with_parameters(_service, "reward_earned", ["same-context", new_token])


func test_only_one_show_is_active_including_rewarded_until_close() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("first")
	assert_eq(_service.show_rewarded("second"), 0)
	assert_false(_service.preload_rewarded())
	_fake.earn_reward(token)
	assert_eq(_service.show_rewarded("second"), 0)
	assert_false(_service.preload_rewarded())
	assert_eq(_fake.show_tokens.size(), 1)
	_fake.close(token)
	_load_ready()
	assert_gt(_service.show_rewarded("second"), token)


func test_empty_context_does_not_consume_ready_ad() -> void:
	_load_ready()
	assert_eq(_service.show_rewarded("  "), 0)
	assert_true(_service.is_rewarded_available())
	assert_true(_fake.show_tokens.is_empty())


func test_caller_scene_disappearance_does_not_cancel_valid_events() -> void:
	var scene: Node = Node.new()
	var caller: Caller = Caller.new()
	scene.add_child(caller)
	_service.reward_earned.connect(caller.received_reward)
	_load_ready()
	var token: int = _service.show_rewarded("departed-scene")
	scene.free()
	_fake.earn_reward(token)
	_fake.close(token)
	assert_signal_emitted_with_parameters(_service, "reward_earned", ["departed-scene", token])
	assert_signal_emit_count(_service, "ad_closed", 1)
	assert_eq(_service.state, Service.State.CLOSED)


func test_revoked_permission_invalidates_pending_load_callbacks() -> void:
	_service.preload_rewarded()
	var old_token: int = _fake.load_tokens.back()
	_service.set_requests_allowed(false)
	_fake.complete_load(old_token)
	assert_eq(_service.state, Service.State.UNAVAILABLE)
	assert_false(_service.preload_rewarded())
	assert_signal_not_emitted(_service, "rewarded_ready")
	_service.set_requests_allowed(true)
	_load_ready()
	assert_true(_service.is_rewarded_available())


func test_revoked_permission_blocks_show_but_honors_already_open_ad() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("already-open")
	_service.set_requests_allowed(false)
	_fake.earn_reward(token)
	_fake.close(token)
	assert_signal_emit_count(_service, "reward_earned", 1)
	assert_signal_emit_count(_service, "ad_closed", 1)
	assert_false(_service.preload_rewarded())
	assert_eq(_service.show_rewarded("blocked"), 0)


func test_backend_replacement_is_rejected_after_initialization() -> void:
	assert_false(_service.configure_backend(NoopBackend.new()))
	assert_false(_service.configure_backend(null))
	_load_ready()
	assert_true(_service.is_rewarded_available())


func test_unsolicited_or_stale_operation_callbacks_are_ignored() -> void:
	_fake.earn_reward(0)
	_fake.close(0)
	_fake.fail(0)
	_fake.complete_load(_fake.initialization_tokens.back())
	_fake.fail(_fake.initialization_tokens.back())
	assert_eq(_service.state, Service.State.IDLE)
	assert_signal_not_emitted(_service, "reward_earned")
	assert_signal_not_emitted(_service, "ad_failed")


func test_failure_after_confirmed_reward_does_not_erase_or_repeat_reward() -> void:
	_load_ready()
	var token: int = _service.show_rewarded("earned")
	_fake.earn_reward(token)
	_fake.fail(token, &"late_failure")
	assert_eq(_service.state, Service.State.REWARDED)
	assert_signal_not_emitted(_service, "ad_failed")
	_fake.close(token)
	_fake.earn_reward(token)
	assert_signal_emit_count(_service, "reward_earned", 1)
	assert_signal_emit_count(_service, "ad_closed", 1)
