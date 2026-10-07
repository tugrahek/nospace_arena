extends GutTest

## Native responses are deterministic; all persistence uses a dedicated user:// fixture.
const Service = preload("res://scripts/monetization/purchase_service.gd")
const Backend = preload("res://scripts/monetization/google_play_purchase_backend.gd")
const Bridge = preload("res://scripts/monetization/google_play_billing_bridge.gd")
const Product = preload("res://scripts/monetization/purchase_product.gd")
const EconomyScript = preload("res://scripts/autoload/Economy.gd")
const SaveStoreScript = preload("res://scripts/meta/save_store.gd")
const PATH: String = "user://24d2_google_backend_fixture.json"
const ID: StringName = &"test_permanent"

class MockBridge:
	extends RefCounted
	var available: bool = true
	var connected: Callable
	var failed: Callable
	var disconnected: Callable
	var queries: Array[Dictionary] = []
	var purchases: Array[Dictionary] = []
	var owned: Array[Callable] = []
	var acknowledgements: Array[Dictionary] = []
	var launch_result: Dictionary = {"response_code": 0}
	var finished: int = 0
	func is_native_available() -> bool:
		return available
	func initialize(success: Callable, failure: Callable, lost: Callable) -> void:
		connected = success
		failed = failure
		disconnected = lost
	func query_products(ids: PackedStringArray, completed: Callable) -> void:
		queries.append({"ids": ids, "completed": completed})
	func purchase(id: StringName, offer: Dictionary, completed: Callable) -> Dictionary:
		purchases.append({"id": id, "offer": offer.duplicate(true), "completed": completed})
		return launch_result
	func finish_purchase() -> void:
		finished += 1
	func query_owned(completed: Callable) -> void:
		owned.append(completed)
	func acknowledge(identity: String, completed: Callable) -> void:
		acknowledgements.append({"identity": identity, "completed": completed})
	func shutdown() -> void:
		connected = Callable()
		failed = Callable()
		disconnected = Callable()
		queries.clear()
		purchases.clear()
		owned.clear()
		acknowledgements.clear()

class CheckedEconomy:
	extends "res://scripts/autoload/Economy.gd"
	var fail_write: int = -1
	var writes: int = 0
	func _persist_iap_data(data: SaveData) -> bool:
		writes += 1
		return false if writes == fail_write else SaveStore.save_to(_save_path, data)

var _service: Service
var _native: MockBridge
var _backend: Backend
var _economy: CheckedEconomy


func before_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	_economy = CheckedEconomy.new()
	_economy._save_path = PATH
	add_child_autofree(_economy)
	_native = MockBridge.new()
	_backend = Backend.new(_native, [Product.new(ID, Product.Kind.NON_CONSUMABLE)])
	_service = Service.new()
	_service.configure_backend(_backend)
	_service.configure_delivery_handler(Callable(_economy, "_deliver_purchase_transaction"))
	add_child_autofree(_service)
	_native.connected.call()
	await get_tree().process_frame
	_native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	_native.owned.back().call({"response_code": 0, "purchases": []})
	watch_signals(_service)
	watch_signals(_economy)


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func _details() -> Dictionary:
	return {"response_code": 0, "product_details": [{"product_id": String(ID),
		"product_type": "inapp", "title": "Localized title", "description": "Localized description",
		"one_time_purchase_offer_details_list": [{"formatted_price": "test localized price",
		"price_currency_code": "TEST", "price_amount_micros": 123,
		"purchase_option_id": "test-option", "offer_id": "test-offer"}]}]}


func _purchase(identity: String = "test-token", state: int = 1, acknowledged: bool = false) -> Dictionary:
	return {"purchase_token": identity, "purchase_state": state,
		"is_acknowledged": acknowledged, "product_ids": PackedStringArray([String(ID)]), "quantity": 1}


func _update(entry: Dictionary) -> void:
	_native.purchases.back()["completed"].call({"response_code": 0, "purchases": [entry]})


func _restore(entry: Dictionary) -> void:
	assert_gt(_service.restore_purchases(), 0)
	_native.owned.back().call({"response_code": 0, "purchases": [entry]})


func test_connection_initializes_and_automatically_queries_products_and_owned() -> void:
	assert_true(_service.is_available())
	assert_eq(_service.state, Service.State.IDLE)
	assert_eq(_native.queries.size(), 1)
	assert_eq(_native.owned.size(), 1)
	assert_eq(_native.queries[0]["ids"], PackedStringArray([String(ID)]))
	assert_true(_native.acknowledgements.is_empty())


func test_connection_failure_retry_and_stale_connection_callback() -> void:
	var native: MockBridge = MockBridge.new()
	var service: Service = Service.new()
	service.configure_backend(Backend.new(native))
	add_child_autofree(service)
	var old_connected: Callable = native.connected
	native.failed.call(2, "offline")
	assert_false(service.is_available())
	assert_eq(service.state, Service.State.UNAVAILABLE)
	assert_gt(service.initialize(), 0)
	old_connected.call()
	assert_false(service.is_available())
	native.connected.call()
	assert_true(service.is_available())


func test_localized_metadata_and_exact_offer_mapping_are_copied() -> void:
	var product: Product = _service.products()[0]
	assert_eq(product.price_label, "test localized price")
	assert_eq(product.title, "Localized title")
	assert_eq(product.description, "Localized description")
	assert_eq(product.currency_code, "TEST")
	assert_eq(product.price_amount_micros, 123)
	product.title = "mutated"
	assert_eq(_service.products()[0].title, "Localized title")
	assert_gt(_service.purchase(ID), 0)
	assert_eq(_native.purchases[0]["offer"]["purchase_option_id"], "test-option")
	assert_eq(_native.purchases[0]["offer"]["offer_id"], "test-offer")
	assert_eq(_service.purchase(ID), 0)


func test_cancelled_purchase_grants_nothing() -> void:
	var token: int = _service.purchase(ID)
	_native.purchases.back()["completed"].call({"response_code": 1})
	assert_signal_emitted_with_parameters(_service, "purchase_cancelled", [token, ID])
	assert_false(_economy.owns_iap_entitlement(ID))
	assert_true(_native.acknowledgements.is_empty())


func test_purchase_error_and_launch_error_grant_nothing() -> void:
	_service.purchase(ID)
	_native.purchases.back()["completed"].call({"response_code": 6})
	assert_signal_emit_count(_service, "purchase_failed", 1)
	_native.launch_result = {"response_code": 6}
	_service.purchase(ID)
	assert_signal_emit_count(_service, "purchase_failed", 2)
	assert_eq(_service.state, Service.State.IDLE)
	assert_false(_economy.owns_iap_entitlement(ID))
	assert_true(_native.acknowledgements.is_empty())


func test_pending_then_purchased_delivers_before_acknowledge() -> void:
	_service.purchase(ID)
	_update(_purchase("test-token", 2))
	assert_eq(_service.state, Service.State.PENDING)
	assert_false(_economy.owns_iap_entitlement(ID))
	assert_true(_native.acknowledgements.is_empty())
	_update(_purchase())
	assert_eq(_economy.iap_transaction_status("test-token"), &"delivered")
	assert_true(SaveStoreScript.load_from(PATH).iap_entitlements.has(String(ID)))
	assert_eq(_native.acknowledgements.size(), 1)
	assert_eq(_native.acknowledgements[0]["identity"], "test-token")
	assert_signal_emit_count(_service, "purchase_succeeded", 1)


func test_failed_first_save_does_not_acknowledge_or_report_success() -> void:
	_economy.fail_write = 1
	_service.purchase(ID)
	_update(_purchase())
	assert_false(_economy.owns_iap_entitlement(ID))
	assert_true(_native.acknowledgements.is_empty())
	assert_signal_not_emitted(_service, "purchase_succeeded")
	assert_signal_emit_count(_service, "purchase_failed", 1)
	_restore(_purchase())
	assert_true(_economy.owns_iap_entitlement(ID))
	assert_eq(_native.acknowledgements.size(), 1)
	assert_signal_emit_count(_economy, "iap_entitlement_granted", 1)


func test_failed_second_save_leaves_pending_then_restore_recovers() -> void:
	_economy.fail_write = 2
	_service.purchase(ID)
	_update(_purchase())
	assert_eq(SaveStoreScript.load_from(PATH).iap_transactions["test-token"]["status"], "pending")
	assert_true(_native.acknowledgements.is_empty())
	assert_signal_emit_count(_service, "purchase_delivery_pending", 1)
	_restore(_purchase())
	assert_true(_economy.owns_iap_entitlement(ID))
	assert_eq(_native.acknowledgements.size(), 1)


func test_duplicate_purchase_callback_cannot_repeat_delivery_or_acknowledgement() -> void:
	_service.purchase(ID)
	_update(_purchase())
	_update(_purchase())
	assert_eq(_native.acknowledgements.size(), 1)
	assert_signal_emit_count(_service, "purchase_succeeded", 1)
	assert_signal_emit_count(_economy, "iap_entitlement_granted", 1)


func test_stale_request_callback_cannot_complete_a_new_purchase() -> void:
	_service.purchase(ID)
	var old: Callable = _native.purchases.back()["completed"]
	old.call({"response_code": 1})
	_service.purchase(ID)
	old.call({"response_code": 0, "purchases": [_purchase("old-token")]})
	old.call({"response_code": 6})
	assert_eq(_service.state, Service.State.PURCHASING)
	assert_false(_economy.owns_iap_entitlement(ID))
	assert_true(_native.acknowledgements.is_empty())
	_update(_purchase("new-token"))
	assert_eq(_economy.iap_transaction_status("old-token"), &"")
	assert_eq(_economy.iap_transaction_status("new-token"), &"delivered")


func test_wrong_product_and_changed_pending_identity_are_rejected() -> void:
	_service.purchase(ID)
	var wrong: Dictionary = _purchase()
	wrong["product_ids"] = PackedStringArray(["unknown"])
	_update(wrong)
	_update(_purchase("pending-token", 2))
	_update(_purchase("wrong-token"))
	assert_eq(_service.state, Service.State.PENDING)
	assert_true(_native.acknowledgements.is_empty())
	_update(_purchase("pending-token"))
	assert_eq(_economy.iap_transaction_status("pending-token"), &"delivered")


func test_already_acknowledged_purchase_is_still_delivered_but_not_acknowledged_again() -> void:
	_service.purchase(ID)
	_update(_purchase("ack-token", 1, true))
	assert_true(_economy.owns_iap_entitlement(ID))
	assert_true(_native.acknowledgements.is_empty())
	_restore(_purchase("ack-token", 1, true))
	assert_signal_emit_count(_economy, "iap_entitlement_granted", 1)


func test_owned_recovery_of_prior_durable_delivery_acknowledges_without_regrant() -> void:
	_economy._deliver_purchase_transaction("owned-token", ID, Product.Kind.NON_CONSUMABLE)
	var writes: int = _economy.writes
	_restore(_purchase("owned-token"))
	assert_eq(_economy.writes, writes)
	assert_eq(_native.acknowledgements.size(), 1)
	assert_signal_not_emitted(_service, "purchase_succeeded")
	_restore(_purchase("owned-token"))
	assert_eq(_native.acknowledgements.size(), 1, "no duplicate acknowledgement while in flight")


func test_acknowledge_failure_retries_on_later_owned_query_without_duplicate_entitlement() -> void:
	_service.purchase(ID)
	_update(_purchase())
	_native.acknowledgements[0]["completed"].call({"response_code": 6, "token": "test-token"})
	assert_true(_economy.owns_iap_entitlement(ID))
	assert_eq(_native.acknowledgements.size(), 1)
	_restore(_purchase())
	assert_eq(_native.acknowledgements.size(), 2)
	assert_signal_emit_count(_economy, "iap_entitlement_granted", 1)
	assert_signal_emit_count(_service, "purchase_succeeded", 1)
	_native.acknowledgements[1]["completed"].call({"response_code": 0, "token": "test-token"})
	_restore(_purchase())
	assert_eq(_native.acknowledgements.size(), 2)


func test_owned_pending_unknown_and_duplicate_entries_are_harmless() -> void:
	_service.restore_purchases()
	var unknown: Dictionary = _purchase("unknown-token")
	unknown["product_ids"] = PackedStringArray(["unknown"])
	_native.owned.back().call({"response_code": 0,
		"purchases": [_purchase("pending", 2), unknown, _purchase(), _purchase()]})
	assert_eq(_economy.iap_transaction_status("pending"), &"")
	assert_eq(_economy.iap_transaction_status("unknown-token"), &"")
	assert_eq(_native.acknowledgements.size(), 1)
	assert_signal_emit_count(_economy, "iap_entitlement_granted", 1)


func test_disconnect_reconnect_recovers_and_rejects_old_active_callback() -> void:
	_service.purchase(ID)
	var stale: Callable = _native.purchases.back()["completed"]
	_native.disconnected.call()
	assert_false(_service.is_available())
	stale.call({"response_code": 0, "purchases": [_purchase("stale")]})
	assert_false(_economy.owns_iap_entitlement(ID))
	_native.connected.call()
	await get_tree().process_frame
	_native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	_native.owned.back().call({"response_code": 0, "purchases": [_purchase("recovered")]})
	assert_true(_service.is_available())
	assert_eq(_economy.iap_transaction_status("recovered"), &"delivered")


func test_stale_product_and_owned_query_callbacks_do_not_finish_new_requests() -> void:
	_service.query_products()
	var old_query: Callable = _native.queries.back()["completed"]
	old_query.call(_details())
	_service.query_products()
	old_query.call({"response_code": 6})
	assert_eq(_service.state, Service.State.QUERYING)
	_native.queries.back()["completed"].call(_details())
	_service.restore_purchases()
	var old_owned: Callable = _native.owned.back()
	old_owned.call({"response_code": 0, "purchases": []})
	_service.restore_purchases()
	old_owned.call({"response_code": 0, "purchases": [_purchase()]})
	assert_eq(_service.state, Service.State.RESTORING)
	assert_false(_economy.owns_iap_entitlement(ID))


func test_non_android_bridge_and_backend_are_unavailable_without_native_errors() -> void:
	assert_false(Bridge.new().is_native_available())
	var service: Service = Service.new()
	service.configure_backend(Backend.new())
	add_child_autofree(service)
	assert_false(service.is_available())
	assert_eq(service.state, Service.State.UNAVAILABLE)
	assert_eq(service.purchase(ID), 0)


func test_startup_owned_query_uses_reloaded_dedupe_without_regranting() -> void:
	_economy._deliver_purchase_transaction("saved-token", ID, Product.Kind.NON_CONSUMABLE)
	var reloaded: EconomyScript = EconomyScript.new()
	reloaded._save_path = PATH
	add_child_autofree(reloaded)
	watch_signals(reloaded)
	var native: MockBridge = MockBridge.new()
	var service: Service = Service.new()
	service.configure_backend(Backend.new(native, [Product.new(ID, Product.Kind.NON_CONSUMABLE)]))
	service.configure_delivery_handler(Callable(reloaded, "_deliver_purchase_transaction"))
	add_child_autofree(service)
	watch_signals(service)
	native.connected.call()
	await get_tree().process_frame
	native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	native.owned.back().call({"response_code": 0, "purchases": [_purchase("saved-token")]})
	assert_eq(native.acknowledgements.size(), 1)
	assert_true(reloaded.owns_iap_entitlement(ID))
	assert_signal_not_emitted(reloaded, "iap_entitlement_granted")
	assert_signal_not_emitted(service, "purchase_succeeded")


func test_unsupported_consumable_and_multiple_offer_metadata_are_not_purchasable() -> void:
	_service.query_products()
	var details: Dictionary = _details()
	details["product_details"][0]["one_time_purchase_offer_details_list"].append(
		details["product_details"][0]["one_time_purchase_offer_details_list"][0].duplicate())
	_native.queries.back()["completed"].call(details)
	assert_true(_service.products().is_empty())
	assert_eq(_service.purchase(ID), 0)
	var native: MockBridge = MockBridge.new()
	var service: Service = Service.new()
	service.configure_backend(Backend.new(native, [Product.new(&"future_consumable")]))
	add_child_autofree(service)
	native.connected.call()
	await get_tree().process_frame
	assert_true(native.queries.is_empty())
	assert_true(service.products().is_empty())
