extends GutTest

## Mock bridge only. A permissive delivery spy proves callbacks never reach fulfillment.
const Service = preload("res://scripts/monetization/purchase_service.gd")
const Backend = preload("res://scripts/monetization/google_play_purchase_backend.gd")
const Bridge = preload("res://scripts/monetization/google_play_billing_bridge.gd")
const Catalog = preload("res://scripts/monetization/v1_coin_catalog.gd")
const Product = preload("res://scripts/monetization/purchase_product.gd")
const ID: StringName = &"coins_500"

class MockBridge:
	extends "res://test/test_google_play_purchase_backend.gd".MockBridge
	var consumptions: Array[String] = []
	func consume(identity: String, _completed: Callable) -> void:
		consumptions.append(identity)

var _service: Service
var _native: MockBridge
var _backend: Backend
var _deliveries: int = 0
var _routed: Array[Dictionary] = []


func before_each() -> void:
	_deliveries = 0
	_routed.clear()
	_native = MockBridge.new()
	_backend = Backend.new(_native, Catalog.all())
	_service = Service.new()
	_service.configure_backend(_backend)
	_service.configure_delivery_handler(Callable(self, "_deliver"))
	add_child_autofree(_service)
	_native.connected.call()
	await get_tree().process_frame
	_native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	_native.owned.back().call({"response_code": 0, "purchases": []})
	watch_signals(_service)
	watch_signals(_backend)


func _deliver(_identity: String, _id: StringName, _kind: int) -> Dictionary:
	_deliveries += 1
	return {"durable": true, "pending": false, "duplicate": false}


func _details() -> Dictionary:
	var details: Array = []  # Native response fixture also accepts deliberately malformed entries.
	for definition: CoinPackDefinition in Catalog.all():
		details.append({"product_id": String(definition.sku), "product_type": "inapp",
			"title": "Play localized title", "description": "Play localized description",
			"one_time_purchase_offer_details_list": [{"formatted_price": "Play localized price",
			"price_currency_code": "TRY", "price_amount_micros": 123000,
			"purchase_option_id": "mock-buy", "offer_id": null}]})
	return {"response_code": 0, "product_details": details}


func _purchase(identity: String = "mock-token", state: int = 1, id: StringName = ID) -> Dictionary:
	return {"purchase_token": identity, "purchase_state": state,
		"product_ids": PackedStringArray([String(id)]), "quantity": 1, "is_acknowledged": false}


func _update(entry: Dictionary) -> void:
	_native.purchases.back()["completed"].call({"response_code": 0, "purchases": [entry]})


func _assert_no_delivery() -> void:
	assert_eq(_deliveries, 0)
	assert_true(_native.acknowledgements.is_empty())
	assert_true(_native.consumptions.is_empty())
	assert_signal_not_emitted(_service, "purchase_succeeded")
	assert_signal_not_emitted(_backend, "transaction_received")


func test_all_three_skus_query_localized_metadata_and_exact_offer() -> void:
	assert_eq(_native.queries[0]["ids"], PackedStringArray(["coins_500", "coins_1500", "coins_4000"]))
	assert_eq(_service.products().size(), 3)
	for product: PurchaseProduct in _service.products():
		assert_eq(product.kind, Product.Kind.CONSUMABLE)
		assert_eq(product.price_label, "Play localized price")
		assert_eq(product.currency_code, "TRY")
		assert_eq(product.price_amount_micros, 123000)
	assert_gt(_service.purchase(ID), 0)
	assert_eq(_native.purchases.back()["offer"]["purchase_option_id"], "mock-buy")
	assert_null(_native.purchases.back()["offer"]["offer_id"])
	_assert_no_delivery()


func test_purchased_candidates_require_verification_for_each_sku_without_grants() -> void:
	for definition: CoinPackDefinition in Catalog.all():
		var token: int = _service.purchase(definition.sku)
		_update(_purchase("mock-" + String(definition.sku), 1, definition.sku))
		assert_signal_emitted_with_parameters(_service, "purchase_verification_required",
			[token, definition.sku, "mock-" + String(definition.sku)])
		assert_eq(_service.state, Service.State.IDLE)
	_assert_no_delivery()


func test_pending_then_purchased_and_duplicate_update_do_not_fulfill() -> void:
	var token: int = _service.purchase(ID)
	_update(_purchase("pending-token", 2))
	_update(_purchase("pending-token", 2))
	assert_eq(_service.state, Service.State.PENDING)
	assert_signal_emit_count(_service, "purchase_pending", 1)
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_update(_purchase("different-token"))
	assert_eq(_service.state, Service.State.PENDING)
	_update(_purchase("pending-token"))
	_update(_purchase("pending-token"))
	assert_signal_emitted_with_parameters(_service, "purchase_verification_required", [token, ID, "pending-token"])
	assert_signal_emit_count(_service, "purchase_verification_required", 1)
	_assert_no_delivery()


func test_cancellation_and_launch_errors_do_not_submit_candidates() -> void:
	var token: int = _service.purchase(ID)
	_native.purchases.back()["completed"].call({"response_code": 1})
	assert_signal_emitted_with_parameters(_service, "purchase_cancelled", [token, ID])
	_native.launch_result = {"response_code": 6}
	_service.purchase(ID)
	assert_signal_emit_count(_service, "purchase_failed", 1)
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_assert_no_delivery()


func test_invalid_state_quantity_product_identity_and_suspension_are_rejected() -> void:
	_service.purchase(ID)
	var invalid: Array[Dictionary] = []
	for quantity: Variant in [0, 2, 1.5, "1", true, null]:
		var entry: Dictionary = _purchase()
		entry["quantity"] = quantity
		invalid.append(entry)
	for fields: Dictionary in [{"purchase_state": 0}, {"purchase_token": " "}, {"purchase_token": 42},
		{"product_ids": ["coins_1500"]}, {"product_ids": ["coins_500", "coins_1500"]}, {"is_suspended": true}]:
		var entry: Dictionary = _purchase()
		entry.merge(fields, true)
		invalid.append(entry)
	for entry: Dictionary in invalid:
		_update(entry)
	assert_eq(_service.state, Service.State.PURCHASING)
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_assert_no_delivery()


func test_stale_purchase_callback_cannot_finish_a_new_request() -> void:
	_service.purchase(ID)
	var old: Callable = _native.purchases.back()["completed"]
	old.call({"response_code": 1})
	var token: int = _service.purchase(ID)
	old.call({"response_code": 0, "purchases": [_purchase("stale")]})
	old.call({"response_code": 6})
	assert_eq(_service.state, Service.State.PURCHASING)
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_update(_purchase("current"))
	assert_signal_emitted_with_parameters(_service, "purchase_verification_required", [token, ID, "current"])
	_assert_no_delivery()


func test_owned_recovery_deduplicates_candidates_but_later_retry_is_allowed() -> void:
	var token: int = _service.restore_purchases()
	_native.owned.back().call({"response_code": 0, "purchases": [_purchase(), _purchase(),
		_purchase("pending", 2), _purchase("unknown", 1, &"unknown")]})
	assert_signal_emitted_with_parameters(_service, "purchase_verification_required", [token, ID, "mock-token"])
	assert_signal_emit_count(_service, "purchase_verification_required", 1)
	assert_signal_emitted_with_parameters(_service, "restore_completed", [token])
	_service.restore_purchases()
	_native.owned.back().call({"response_code": 0, "purchases": [_purchase()]})
	assert_signal_emit_count(_service, "purchase_verification_required", 2, "future server deduplication owns durable state")
	_assert_no_delivery()


func test_disconnect_invalidates_active_callbacks_and_reconnect_recovers() -> void:
	_service.purchase(ID)
	var stale: Callable = _native.purchases.back()["completed"]
	_native.disconnected.call()
	assert_eq(_service.purchase(ID), 0)
	stale.call({"response_code": 0, "purchases": [_purchase("stale")]})
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_native.connected.call()
	await get_tree().process_frame
	_native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	_native.owned.back().call({"response_code": 0, "purchases": [_purchase("recovered")]})
	assert_true(_service.is_available())
	assert_signal_emit_count(_service, "purchase_verification_required", 1)
	_assert_no_delivery()


func test_stale_product_and_owned_callbacks_cannot_submit_candidates() -> void:
	_service.query_products()
	var query: Callable = _native.queries.back()["completed"]
	_native.disconnected.call()
	query.call(_details())
	_native.connected.call()
	await get_tree().process_frame
	_native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	var old_owned: Callable = _native.owned.back()
	old_owned.call({"response_code": 0, "purchases": []})
	_service.restore_purchases()
	old_owned.call({"response_code": 0, "purchases": [_purchase("stale-owned")]})
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_assert_no_delivery()


func test_multiple_or_invalid_offers_are_not_purchasable() -> void:
	for fields: Dictionary in [{"formatted_price": " "}, {"price_currency_code": "bad!"},
		{"price_amount_micros": 0}, {"price_amount_micros": 1.5}, {"purchase_option_id": null}, {"offer_id": 42}]:
		_service.query_products()
		var details: Dictionary = _details()
		details["product_details"] = [details["product_details"][0]]
		details["product_details"][0]["one_time_purchase_offer_details_list"][0].merge(fields, true)
		_native.queries.back()["completed"].call(details)
		assert_true(_service.products().is_empty())
		assert_eq(_service.purchase(ID), 0)
	_service.query_products()
	var details: Dictionary = _details()
	for detail: Dictionary in details["product_details"]:
		detail["one_time_purchase_offer_details_list"].append(detail["one_time_purchase_offer_details_list"][0].duplicate())
	_native.queries.back()["completed"].call(details)
	assert_true(_service.products().is_empty())
	_assert_no_delivery()


func test_one_valid_offer_with_invalid_alternative_and_detached_metadata() -> void:
	_service.query_products()
	var details: Dictionary = _details()
	for detail: Dictionary in details["product_details"]:
		detail["one_time_purchase_offer_details_list"].append({"formatted_price": "invalid"})
	_native.queries.back()["completed"].call(details)
	assert_eq(_service.products().size(), 3)
	details["product_details"][0]["one_time_purchase_offer_details_list"][0]["purchase_option_id"] = "mutated"
	_service.products()[0].price_label = "mutated"
	_service.purchase(ID)
	assert_eq(_native.purchases.back()["offer"]["purchase_option_id"], "mock-buy")
	assert_eq(_service.products()[0].price_label, "Play localized price")
	_assert_no_delivery()


func test_spoofed_delivery_and_wrong_transaction_signal_never_grant_or_ack() -> void:
	var token: int = _service.purchase(ID)
	_backend.transaction_received.emit(token, ID, "wrong-channel")
	_backend.delivery_confirmed(token, ID, "wrong-channel")
	assert_signal_emitted_with_parameters(_service, "purchase_verification_required", [token, ID, "wrong-channel"])
	assert_eq(_deliveries, 0)
	assert_true(_native.acknowledgements.is_empty())
	assert_true(_native.consumptions.is_empty())
	assert_signal_not_emitted(_service, "purchase_succeeded")


func test_wrong_request_and_product_verification_signals_are_ignored() -> void:
	var token: int = _service.purchase(ID)
	_backend.verification_required.emit(token + 1, ID, "wrong-request")
	_backend.verification_required.emit(token, &"coins_1500", "wrong-product")
	_backend.verification_required.emit(token, ID, " ")
	assert_signal_not_emitted(_service, "purchase_verification_required")
	_assert_no_delivery()


func test_acknowledged_or_spoofed_durable_coin_still_cannot_be_acknowledged() -> void:
	var token: int = _service.purchase(ID)
	var entry: Dictionary = _purchase()
	entry["is_acknowledged"] = true
	_update(entry)
	_backend._transactions["mock-token"] = {"token": token, "product_id": ID,
		"acknowledged": false, "durable": true}
	_backend.delivery_confirmed(token, ID, "mock-token")
	assert_signal_emit_count(_service, "purchase_verification_required", 1)
	_assert_no_delivery()


func test_malformed_response_arrays_fail_closed_without_delivery() -> void:
	_service.purchase(ID)
	_native.purchases.back()["completed"].call({"response_code": 0, "purchases": "invalid"})
	assert_signal_emit_count(_service, "purchase_failed", 1)
	_service.query_products()
	_native.queries.back()["completed"].call({"response_code": 0, "product_details": "invalid"})
	assert_signal_emit_count(_service, "request_failed", 1)
	_assert_no_delivery()


func test_malformed_entries_and_owned_response_fail_without_receipt_logging() -> void:
	_service.query_products()
	var details: Dictionary = _details()
	details["product_details"].append(null)
	details["product_details"].append({"product_id": 42})
	_native.queries.back()["completed"].call(details)
	assert_eq(_service.products().size(), 3)
	_service.purchase(ID)
	_native.purchases.back()["completed"].call({"response_code": 0, "purchases": [null, 42]})
	assert_eq(_service.state, Service.State.PURCHASING)
	_native.purchases.back()["completed"].call({"response_code": 1})
	_service.restore_purchases()
	_native.owned.back().call({"response_code": 0, "purchases": "invalid"})
	assert_signal_emit_count(_service, "request_failed", 1)
	_assert_no_delivery()


func test_mixed_catalog_preserves_non_consumable_delivery_but_isolates_coins() -> void:
	var native: MockBridge = MockBridge.new()
	var definitions: Array = []
	definitions.append_array(Catalog.all())
	definitions.append(Product.new(&"mock_permanent", Product.Kind.NON_CONSUMABLE))
	var service: Service = Service.new()
	service.configure_backend(Backend.new(native, definitions))
	service.configure_delivery_handler(Callable(self, "_deliver"))
	add_child_autofree(service)
	native.connected.call()
	await get_tree().process_frame
	var details: Dictionary = _details()
	var permanent: Dictionary = details["product_details"][0].duplicate(true)
	permanent["product_id"] = "mock_permanent"
	details["product_details"].append(permanent)
	native.queries.back()["completed"].call(details)
	await get_tree().process_frame
	native.owned.back().call({"response_code": 0, "purchases": []})
	watch_signals(service)
	service.purchase(&"mock_permanent")
	native.purchases.back()["completed"].call({"response_code": 0,
		"purchases": [_purchase("permanent-token", 1, &"mock_permanent")]})
	assert_eq(_deliveries, 1)
	assert_eq(native.acknowledgements.size(), 1)
	assert_signal_emit_count(service, "purchase_succeeded", 1)
	service.purchase(ID)
	native.purchases.back()["completed"].call({"response_code": 0, "purchases": [_purchase()]})
	assert_eq(_deliveries, 1)
	assert_eq(native.acknowledgements.size(), 1)
	assert_true(native.consumptions.is_empty())
	assert_signal_emit_count(service, "purchase_verification_required", 1)


func test_duplicate_product_details_invalidate_all_launch_offers() -> void:
	_service.query_products()
	var details: Dictionary = _details()
	details["product_details"].append(details["product_details"][0].duplicate(true))
	_native.queries.back()["completed"].call(details)
	assert_signal_emit_count(_service, "request_failed", 1)
	_service.purchase(ID)
	assert_true(_native.purchases.is_empty())
	_assert_no_delivery()


func test_already_owned_launch_requests_recovery_without_fulfillment() -> void:
	_native.launch_result = {"response_code": 7}
	_service.purchase(ID)
	assert_signal_emit_count(_service, "purchase_failed", 1)
	await get_tree().process_frame
	_native.queries.back()["completed"].call(_details())
	await get_tree().process_frame
	_native.owned.back().call({"response_code": 0, "purchases": [_purchase("already-owned")]})
	assert_signal_emit_count(_service, "purchase_verification_required", 1)
	_assert_no_delivery()


func test_reserved_coin_cannot_be_configured_as_non_consumable() -> void:
	var native: MockBridge = MockBridge.new()
	var backend: Backend = Backend.new(native, [Product.new(ID, Product.Kind.NON_CONSUMABLE)])
	backend.initialize(100)
	native.connected.call()
	backend.query_products(101)
	assert_true(native.queries.is_empty())
	backend.purchase(102, ID)
	backend.delivery_confirmed(102, ID, "spoofed")
	assert_true(native.purchases.is_empty())
	assert_true(native.acknowledgements.is_empty())
	backend.shutdown()


func test_native_bridge_rejects_unrelated_flow_markers_without_native_sdk() -> void:
	var bridge: Bridge = Bridge.new()
	var response: Dictionary = {"response_code": 0, "purchases": [
		{"original_json": JSON.stringify({"obfuscatedAccountId": "old"})},
		{"original_json": "malformed"}]}
	bridge._route_purchase(response, Callable(self, "_routed_response"), "current")
	assert_true(_routed.is_empty())
	response["purchases"].append({"original_json": JSON.stringify({"obfuscatedAccountId": "current"})})
	bridge._route_purchase(response, Callable(self, "_routed_response"), "current")
	assert_eq(_routed.size(), 1)
	assert_eq(_routed[0]["purchases"].size(), 1)
	_assert_no_delivery()


func _routed_response(response: Dictionary) -> void:
	_routed.append(response)
