extends GutTest

## Focused native mapping + real service/consent integration with an injectable SDK.
const Service = preload("res://scripts/monetization/ads_service.gd")
const NativeBackend = preload("res://scripts/monetization/native_ads_backend.gd")
const Consent = preload("res://scripts/monetization/ads_consent_coordinator.gd")
const FakeSDK = preload("res://test/helpers/fake_native_ads_bridge.gd")

var _service: Service
var _sdk: FakeSDK
var _consent: Consent


func before_each() -> void:
	_sdk = FakeSDK.new()
	_service = Service.new()
	_service.configure_backend(NativeBackend.new(_sdk, AdsConfig.ANDROID_TEST_REWARDED_ID))
	_consent = Consent.new(_sdk)
	_service.set("_consent", _consent)
	_consent.consent_changed.connect(Callable(_service, "_on_consent_changed"))
	add_child_autofree(_service)
	watch_signals(_service)


func after_each() -> void:
	_sdk.release_callbacks()
	_consent = null


func _allow_and_initialize(privacy_required: bool = false) -> void:
	_consent.start()
	_sdk.current_consent["allowed"] = true
	_sdk.current_consent["privacy_required"] = privacy_required
	_sdk.updates.back()["updated"].call()
	_sdk.initializations.back().call()


func _ready_ad() -> void:
	_allow_and_initialize()
	_sdk.loads.back()["loaded"].call(RefCounted.new())


func test_consent_gate_blocks_initialization_and_load_until_update_finishes() -> void:
	_service.initialize()
	assert_false(_service.preload_rewarded())
	_consent.start()
	_consent.start()
	assert_eq(_sdk.updates.size(), 1)
	assert_true(_sdk.initializations.is_empty())
	assert_true(_sdk.loads.is_empty())
	assert_eq(_service.state, Service.State.UNAVAILABLE)


func test_allowed_consent_initializes_then_preloads_once() -> void:
	_allow_and_initialize()
	assert_eq(_sdk.initializations.size(), 1)
	assert_eq(_sdk.loads.size(), 1)
	assert_eq(_sdk.loads[0]["id"], AdsConfig.ANDROID_TEST_REWARDED_ID)
	assert_eq(_service.state, Service.State.LOADING)
	_sdk.initializations[0].call()
	assert_eq(_sdk.loads.size(), 1, "duplicate init cannot start another load")
	assert_false(_service.preload_rewarded())


func test_duplicate_load_callback_cannot_dispose_the_ready_native_ad() -> void:
	_allow_and_initialize()
	var loaded: Callable = _sdk.loads[0]["loaded"]
	var ready_ad: RefCounted = RefCounted.new()
	loaded.call(ready_ad)
	loaded.call(ready_ad)
	loaded.call(RefCounted.new())
	assert_true(_sdk.destroyed.is_empty(), "duplicate wrapper must not destroy the same native UID")
	assert_signal_emit_count(_service, "rewarded_ready", 1)
	assert_gt(_service.show_rewarded("run"), 0)
	_sdk.shows[0]["closed"].call()
	assert_eq(_sdk.destroyed.size(), 1)


func test_duplicate_update_callbacks_cannot_launch_another_required_form() -> void:
	_consent.start()
	_sdk.current_consent.merge({"form_required": true, "form_available": true}, true)
	_sdk.updates[0]["updated"].call()
	_sdk.updates[0]["updated"].call()
	_sdk.updates[0]["failed"].call()
	assert_eq(_sdk.required_forms.size(), 1)
	assert_true(_consent.busy)
	assert_true(_sdk.initializations.is_empty())
	_sdk.required_forms[0]["failed"].call()
	assert_false(_consent.busy)


func test_stale_consent_callbacks_cannot_reopen_gate_during_privacy_form() -> void:
	_allow_and_initialize(true)
	assert_true(_service.show_privacy_options())
	_sdk.updates[0]["updated"].call()
	_sdk.updates[0]["failed"].call()
	assert_true(_service.is_privacy_options_busy())
	assert_false(_service.preload_rewarded())
	assert_eq(_sdk.loads.size(), 1)
	_sdk.privacy_forms[0].call()
	_sdk.privacy_forms[0].call()
	assert_false(_service.is_privacy_options_busy())
	assert_eq(_sdk.loads.size(), 2, "duplicate form dismissal starts only one fresh load")


func test_required_form_holds_gate_until_google_state_allows_ads() -> void:
	_consent.start()
	_sdk.current_consent.merge({"form_required": true, "form_available": true}, true)
	_sdk.updates[0]["updated"].call()
	assert_eq(_sdk.required_forms.size(), 1)
	assert_true(_sdk.initializations.is_empty())
	assert_true(_consent.busy)
	_sdk.current_consent.merge({"allowed": true, "form_required": false}, true)
	_sdk.required_forms[0]["completed"].call()
	assert_false(_consent.busy)
	assert_eq(_sdk.initializations.size(), 1)


func test_denied_or_unavailable_required_form_keeps_ads_unavailable() -> void:
	_consent.start()
	_sdk.current_consent["form_required"] = true
	_sdk.updates[0]["updated"].call()
	assert_true(_sdk.required_forms.is_empty())
	assert_true(_sdk.initializations.is_empty())
	assert_false(_service.is_rewarded_available())
	assert_false(_consent.busy, "gameplay is not held by missing consent UI")


func test_update_failure_reads_actual_ump_state_and_does_not_retry() -> void:
	_consent.start()
	_sdk.updates[0]["failed"].call()
	assert_false(_consent.busy)
	assert_true(_sdk.initializations.is_empty())
	assert_eq(_sdk.updates.size(), 1)
	assert_false(_service.preload_rewarded())


func test_update_failure_can_use_google_previous_valid_state() -> void:
	_consent.start()
	_sdk.current_consent["allowed"] = true
	_sdk.updates[0]["failed"].call()
	assert_eq(_sdk.initializations.size(), 1)
	assert_false(_consent.busy)


func test_required_form_failure_finishes_without_request_or_reload_loop() -> void:
	_consent.start()
	_sdk.current_consent.merge({"form_required": true, "form_available": true}, true)
	_sdk.updates[0]["updated"].call()
	_sdk.required_forms[0]["failed"].call()
	assert_false(_consent.busy)
	assert_true(_sdk.initializations.is_empty())
	assert_eq(_sdk.required_forms.size(), 1)


func test_privacy_entry_is_only_required_state_and_forms_cannot_overlap() -> void:
	assert_false(_service.show_privacy_options())
	_allow_and_initialize(true)
	assert_true(_service.is_privacy_options_required())
	assert_true(_service.show_privacy_options())
	assert_false(_service.show_privacy_options())
	assert_true(_service.is_privacy_options_busy())
	assert_false(_service.preload_rewarded())
	_sdk.current_consent.merge({"allowed": false, "privacy_required": false}, true)
	_sdk.privacy_forms[0].call()
	assert_false(_service.is_privacy_options_required())
	assert_false(_service.is_privacy_options_busy())
	assert_false(_service.is_rewarded_available())
	assert_eq(_sdk.loads.size(), 1)


func test_privacy_revocation_invalidates_inflight_load_and_reapproval_loads_fresh() -> void:
	_allow_and_initialize(true)
	var old_load: Dictionary = _sdk.loads[0]
	assert_true(_service.show_privacy_options())
	var stale_ad: RefCounted = RefCounted.new()
	old_load["loaded"].call(stale_ad)
	assert_false(_service.is_rewarded_available())
	_sdk.privacy_forms[0].call()
	assert_eq(_sdk.loads.size(), 2)
	assert_true(_sdk.destroyed.has(stale_ad))
	_sdk.loads[1]["loaded"].call(RefCounted.new())
	assert_true(_service.is_rewarded_available())


func test_load_success_and_no_fill_failure_map_without_automatic_retry() -> void:
	_allow_and_initialize()
	_sdk.loads[0]["failed"].call(&"no_fill")
	assert_eq(_service.state, Service.State.FAILED)
	assert_signal_emitted_with_parameters(_service, "ad_failed", ["", 2, &"no_fill"])
	assert_eq(_sdk.loads.size(), 1)
	assert_true(_service.preload_rewarded(), "only an explicit safe retry starts a new request")
	_sdk.loads[1]["loaded"].call(RefCounted.new())
	assert_true(_service.is_rewarded_available())


func test_reward_and_close_are_independent_and_duplicate_callbacks_emit_once() -> void:
	_ready_ad()
	var token: int = _service.show_rewarded("scene-independent-context")
	var shown: Dictionary = _sdk.shows[0]
	shown["rewarded"].call()
	shown["rewarded"].call()
	assert_signal_emit_count(_service, "reward_earned", 1)
	assert_signal_emitted_with_parameters(_service, "reward_earned", ["scene-independent-context", token])
	assert_signal_not_emitted(_service, "ad_closed")
	shown["closed"].call()
	shown["closed"].call()
	assert_signal_emit_count(_service, "ad_closed", 1)
	assert_eq(_sdk.destroyed.size(), 1)


func test_close_without_reward_and_late_reward_never_grant() -> void:
	_ready_ad()
	_service.show_rewarded("run")
	var shown: Dictionary = _sdk.shows[0]
	shown["closed"].call()
	shown["rewarded"].call()
	assert_signal_not_emitted(_service, "reward_earned")
	assert_eq(_service.state, Service.State.CLOSED)


func test_show_failure_consumes_ad_and_rejects_late_reward() -> void:
	_ready_ad()
	var token: int = _service.show_rewarded("run")
	var shown: Dictionary = _sdk.shows[0]
	shown["failed"].call(&"show_failed")
	shown["rewarded"].call()
	shown["closed"].call()
	assert_signal_emitted_with_parameters(_service, "ad_failed", ["run", token, &"show_failed"])
	assert_signal_not_emitted(_service, "reward_earned")
	assert_signal_not_emitted(_service, "ad_closed")
	assert_eq(_sdk.destroyed.size(), 1)


func test_failure_after_reward_still_allows_close_without_duplicate_reward() -> void:
	_ready_ad()
	_service.show_rewarded("run")
	_sdk.shows[0]["rewarded"].call()
	_sdk.shows[0]["failed"].call(&"show_failed")
	_sdk.shows[0]["closed"].call()
	assert_signal_emit_count(_service, "reward_earned", 1)
	assert_signal_emit_count(_service, "ad_closed", 1)
	assert_signal_not_emitted(_service, "ad_failed")


func test_old_load_and_show_callbacks_cannot_replace_or_reward_new_request() -> void:
	_ready_ad()
	_service.show_rewarded("run")
	var old_show: Dictionary = _sdk.shows[0]
	old_show["closed"].call()
	assert_true(_service.preload_rewarded())
	var stale_ad: RefCounted = RefCounted.new()
	_sdk.loads[0]["loaded"].call(stale_ad)
	assert_true(_sdk.destroyed.has(stale_ad))
	assert_eq(_service.state, Service.State.LOADING)
	_sdk.loads[1]["loaded"].call(RefCounted.new())
	_service.show_rewarded("run")
	old_show["rewarded"].call()
	old_show["closed"].call()
	assert_eq(_service.state, Service.State.SHOWING)
	assert_signal_not_emitted(_service, "reward_earned")
	_sdk.shows[1]["closed"].call()


func test_missing_native_sdk_keeps_editor_and_consent_noop() -> void:
	_sdk.available = false
	_consent.start()
	assert_true(_sdk.updates.is_empty())
	assert_false(_consent.busy)
	assert_false(_service.is_privacy_options_required())
	assert_false(_service.is_rewarded_available())
	assert_false(NativeBackend.native_sdk_available(), "desktop plugin mock does not activate native ads")
	assert_false(AdsService.is_rewarded_available())


func test_unconfigured_production_unit_fails_closed_without_native_load() -> void:
	var native: NativeBackend = NativeBackend.new(_sdk, "")
	watch_signals(native)
	native.load_rewarded(42)
	assert_signal_emitted_with_parameters(native, "operation_failed", [42, &"ad_config_missing"])
	assert_true(_sdk.loads.is_empty())
	assert_eq(AdsConfig.rewarded_id(), AdsConfig.ANDROID_TEST_REWARDED_ID)


func test_invalid_production_config_never_initializes_or_loads_even_after_consent() -> void:
	var blocked_sdk: FakeSDK = FakeSDK.new()
	var blocked: Service = Service.new()
	var id: String = AdsConfig.resolve_rewarded_id(false, true, "", "invalid")
	blocked.configure_backend(NativeBackend.new(blocked_sdk, id))
	blocked.set_requests_allowed(true)
	add_child_autofree(blocked)
	assert_true(blocked_sdk.initializations.is_empty())
	assert_true(blocked_sdk.loads.is_empty())
	assert_false(blocked.preload_rewarded())
	assert_eq(blocked.state, Service.State.UNAVAILABLE)
	blocked_sdk.release_callbacks()
