extends GutTest

## Exercises vendor-shaped signals without constructing a JNI client or launching Play UI.
const Bridge = preload("res://scripts/monetization/google_play_billing_bridge.gd")

class MockClient:
	extends Node
	signal on_purchase_updated(response: Dictionary)
	signal query_product_details_response(response: Dictionary)
	signal query_purchases_response(response: Dictionary)
	signal acknowledge_purchase_response(response: Dictionary)
	var marker: String = ""
	var option_id: String = ""
	var offer_id: String = ""
	var queries: Array[Dictionary] = []
	var owned_types: Array[int] = []
	var ack_tokens: Array[String] = []
	func set_obfuscated_account_id(value: String) -> void:
		marker = value
	func purchase(_id: String, option: String, offer: String) -> Dictionary:
		option_id = option
		offer_id = offer
		return {"response_code": 0}
	func query_product_details(ids: PackedStringArray, type: int) -> void:
		queries.append({"ids": ids, "type": type})
	func query_purchases(type: int) -> void:
		owned_types.append(type)
	func acknowledge_purchase(identity: String) -> void:
		ack_tokens.append(identity)
	func end_connection() -> void:
		pass

var _bridge: Bridge
var _client: MockClient


func before_each() -> void:
	_bridge = Bridge.new()
	_client = MockClient.new()
	_bridge._client = _client


func after_each() -> void:
	_bridge.shutdown()


func test_native_bridge_rejects_old_flow_attribution_and_handles_nullable_offer_ids() -> void:
	var results: Array[Dictionary] = []
	var completed: Callable = func(result: Dictionary) -> void: results.append(result)
	_bridge.purchase(&"test_item", {"purchase_option_id": null, "offer_id": null}, completed)
	var old_marker: String = _client.marker
	assert_eq(_client.option_id, "")
	assert_eq(_client.offer_id, "")
	_bridge.finish_purchase()
	_bridge.purchase(&"test_item", {}, completed)
	assert_ne(_client.marker, old_marker)
	assert_eq(_client.marker.length(), 64)
	var entry: Dictionary = {"original_json": JSON.stringify({"obfuscatedAccountId": old_marker})}
	_client.on_purchase_updated.emit({"response_code": 0, "purchases": [entry]})
	assert_true(results.is_empty(), "old native signal cannot be relabelled as the new request")
	entry["original_json"] = "{}"
	_client.on_purchase_updated.emit({"response_code": 0, "purchases": [entry]})
	assert_true(results.is_empty(), "unattributed live updates cannot authorize delivery")
	entry["original_json"] = JSON.stringify({"obfuscatedAccountId": _client.marker})
	_client.on_purchase_updated.emit({"response_code": 0, "purchases": [entry]})
	assert_eq(results.size(), 1)
	_bridge.finish_purchase()
	_client.on_purchase_updated.emit({"response_code": 0, "purchases": [entry]})
	assert_eq(results.size(), 1)


func test_native_queries_use_inapp_and_one_response_listener() -> void:
	var results: Array[Dictionary] = []
	var completed: Callable = func(result: Dictionary) -> void: results.append(result)
	_bridge.query_products(PackedStringArray(["test_item"]), completed)
	assert_eq(_client.queries[0]["type"], 0)
	assert_eq(_client.queries[0]["ids"], PackedStringArray(["test_item"]))
	_client.query_product_details_response.emit({"response_code": 0})
	_client.query_product_details_response.emit({"response_code": 0})
	assert_eq(results.size(), 1)
	_bridge.query_owned(completed)
	assert_eq(_client.owned_types, [0])
	_client.query_purchases_response.emit({"response_code": 0})
	_client.query_purchases_response.emit({"response_code": 0})
	assert_eq(results.size(), 2)


func test_acknowledge_routes_purchase_token_and_keeps_single_listener() -> void:
	var results: Array[Dictionary] = []
	var completed: Callable = func(result: Dictionary) -> void: results.append(result)
	_bridge.acknowledge("first-token", completed)
	_bridge.acknowledge("second-token", completed)
	assert_eq(_client.ack_tokens, ["first-token", "second-token"])
	_client.acknowledge_purchase_response.emit({"response_code": 0, "token": "first-token"})
	_client.acknowledge_purchase_response.emit({"response_code": 6, "token": "second-token"})
	assert_eq(results.size(), 2)
	assert_eq(results[0]["token"], "first-token")
	assert_eq(results[1]["token"], "second-token")
