class_name GooglePlayBillingBridge
extends RefCounted

## Owns the vendor client and freezes each request's callback at dispatch time.
const Client = preload("res://addons/GodotGooglePlayBilling/BillingClient.gd")
const SESSION_NONCE_BYTES: int = 16
var _client: Node
var _links: Dictionary = {}
var _session: String = Crypto.new().generate_random_bytes(SESSION_NONCE_BYTES).hex_encode()
var _purchase_sequence: int = 0


## Desktop execution never constructs the vendor JNI client.
func is_native_available() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling")


## Installs connection listeners before starting the native connection.
func initialize(connected: Callable, failed: Callable, disconnected: Callable) -> void:
	if not is_native_available():
		failed.call(-1, "native_unavailable")
		return
	if _client == null:
		_client = Client.new()
	_link(&"connected", connected)
	_link(&"connect_error", failed)
	_link(&"disconnected", disconnected)
	_client.start_connection()


## Requests only INAPP metadata; the backend supplies configured identifiers.
func query_products(ids: PackedStringArray, completed: Callable) -> void:
	_link(&"query_product_details_response", completed, CONNECT_ONE_SHOT)
	_client.query_product_details(ids, Client.ProductType.INAPP)


## Launches the exact queried one-time offer and keeps its listener through pending.
func purchase(id: StringName, offer: Dictionary, completed: Callable) -> Dictionary:
	_purchase_sequence += 1
	var marker: String = (_session + ":" + str(_purchase_sequence)).sha256_text()
	_link(&"on_purchase_updated", _route_purchase.bind(completed, marker))
	# The vendor exposes no request token. An opaque account-attribution marker correlates
	# this flow; it is not account authentication. Billing 9.1.0 exposes it in original_json.
	_client.set_obfuscated_account_id(marker)
	var option_id: Variant = offer.get("purchase_option_id")
	var offer_id: Variant = offer.get("offer_id")
	return _client.purchase(String(id), str(option_id) if option_id != null else "",
		str(offer_id) if offer_id != null else "")


## Retires the purchase listener before the service can begin another request.
func finish_purchase() -> void:
	_unlink(&"on_purchase_updated")
	if _client != null:
		_client.set_obfuscated_account_id("")


## Owned purchases are authoritative recovery input, never UI-granted entitlements.
func query_owned(completed: Callable) -> void:
	_link(&"query_purchases_response", completed, CONNECT_ONE_SHOT)
	_client.query_purchases(Client.ProductType.INAPP)


## Acknowledgement responses contain the Google purchase token, not a request token.
func acknowledge(transaction_id: String, completed: Callable) -> void:
	_link(&"acknowledge_purchase_response", completed)
	_client.acknowledge_purchase(transaction_id)


## Disconnects every owned listener and frees the otherwise unparented vendor Node.
func shutdown() -> void:
	if _client == null:
		return
	for signal_name: StringName in _links.keys():
		_unlink(signal_name)
	_client.end_connection()
	_client.free()
	_client = null


func _link(signal_name: StringName, callback: Callable, flags: int = 0) -> void:
	_unlink(signal_name)
	_links[signal_name] = callback
	_client.connect(signal_name, callback, flags)


func _unlink(signal_name: StringName) -> void:
	if _links.has(signal_name) and _client.is_connected(signal_name, _links[signal_name]):
		_client.disconnect(signal_name, _links[signal_name])
	_links.erase(signal_name)


func _route_purchase(response: Dictionary, completed: Callable, marker: String) -> void:
	if response.get("response_code", -1) != Client.BillingResponseCode.OK:
		completed.call(response)
		return
	var matching: Array = []
	for purchase_data: Dictionary in response.get("purchases", []):
		var original: Variant = JSON.parse_string(str(purchase_data.get("original_json", "")))
		if original is Dictionary and original.get("obfuscatedAccountId", "") == marker:
			matching.append(purchase_data)
	if not matching.is_empty():
		var correlated: Dictionary = response.duplicate(true)
		correlated["purchases"] = matching
		completed.call(correlated)
