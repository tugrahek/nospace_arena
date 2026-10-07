class_name GooglePlayPurchaseBackend
extends "res://scripts/monetization/purchase_backend.gd"

## Android-only non-consumable adapter. PurchaseService owns correlation and durable delivery.
const Bridge = preload("res://scripts/monetization/google_play_billing_bridge.gd")
const Product = preload("res://scripts/monetization/purchase_product.gd")
const OK: int = 0
const CANCELLED: int = 1
const ALREADY_OWNED: int = 7
const PURCHASED: int = 1
const PENDING: int = 2
var _bridge: RefCounted
var _configured: PurchaseCatalog = PurchaseCatalog.new()
var _offers: Dictionary = {}
var _connected: bool = false
var _established: bool = false
var _connection_token: int = 0
var _token: int = 0
var _operation: StringName = &""
var _product_id: StringName = &""
var _pending_identity: String = ""
var _transactions: Dictionary = {}
var _ack_inflight: Dictionary = {}
var _acknowledged: Dictionary = {}


## Empty configuration is intentional; callers may inject future approved product definitions.
func _init(bridge: RefCounted = null, definitions: Array = []) -> void:
	_bridge = bridge if bridge != null else Bridge.new()
	_configured.replace(definitions)


## Initializes the native client; unsupported platforms report unavailable safely.
func initialize(token: int) -> void:
	if not _bridge.is_native_available():
		initialized.emit(token, false)
		return
	if not _begin(token, &"initialize"):
		return
	_connection_token = token
	_bridge.initialize(_on_connected.bind(token), _on_connect_error.bind(token), _on_disconnected)


## Queries configured non-consumables only; localized prices come exclusively from Google.
func query_products(token: int) -> void:
	if not _ready_request(token, &"query"):
		return
	_offers.clear()
	var ids: PackedStringArray = PackedStringArray()
	for product: Product in _configured.all():
		if product.kind == Product.Kind.NON_CONSUMABLE:
			ids.append(String(product.id))
	if ids.is_empty():
		_on_products({"response_code": OK, "product_details": []}, token)
	else:
		_bridge.query_products(ids, _on_products.bind(token))


## Launches one queried non-consumable; the immutable closure carries the service token.
func purchase(token: int, product_id: StringName) -> void:
	if not _offers.has(product_id):
		operation_failed.emit(token, &"product_unavailable")
		return
	if not _ready_request(token, &"purchase"):
		return
	_product_id = product_id
	_pending_identity = ""
	var result: Dictionary = _bridge.purchase(product_id, _offers[product_id], _on_purchase.bind(token))
	if _matches(token, &"purchase") and result.get("response_code", -1) != OK:
		_purchase_error(token, int(result.get("response_code", -1)))


## Queries owned INAPP purchases, including acknowledged transactions needing local recovery.
func restore_purchases(token: int) -> void:
	if _ready_request(token, &"restore"):
		_bridge.query_owned(_on_owned.bind(token))


## Called only by PurchaseService after checked delivery, including durable duplicates.
func delivery_confirmed(token: int, product_id: StringName, transaction_id: String) -> void:
	var context: Dictionary = _transactions.get(transaction_id, {})
	if context.get("token", 0) != token or context.get("product_id", &"") != product_id:
		return
	context["durable"] = true
	if context.get("acknowledged", false) or _acknowledged.has(transaction_id):
		return
	if _connected and not _ack_inflight.has(transaction_id):
		_ack_inflight[transaction_id] = true
		_bridge.acknowledge(transaction_id, _on_acknowledged)


## Releases native listeners and invalidates active context at the service boundary.
func shutdown() -> void:
	_connected = false
	_established = false
	_finish()
	_bridge.shutdown()
	_transactions.clear()
	_ack_inflight.clear()


func _begin(token: int, operation: StringName) -> bool:
	if token <= 0 or _token != 0:
		operation_failed.emit(token, &"backend_busy")
		return false
	_token = token
	_operation = operation
	return true


func _ready_request(token: int, operation: StringName) -> bool:
	if not _connected:
		operation_failed.emit(token, &"backend_unavailable")
		return false
	return _begin(token, operation)


func _matches(token: int, operation: StringName) -> bool:
	return token != 0 and token == _token and operation == _operation


func _finish() -> void:
	if _operation == &"purchase":
		_bridge.finish_purchase()
	_token = 0
	_operation = &""
	_product_id = &""
	_pending_identity = ""


func _on_connected(token: int) -> void:
	if token != _connection_token or (_connected and _established):
		return
	if _matches(token, &"initialize"):
		_connected = true
		_established = true
		_finish()
		initialized.emit(token, true)
	elif _established:
		_connected = true
		availability_changed.emit(true)
	else:
		return
	recovery_requested.emit()


func _on_connect_error(_code: int, _message: String, token: int) -> void:
	if not _matches(token, &"initialize"):
		return
	_finish()
	initialized.emit(token, false)


func _on_disconnected() -> void:
	_connected = false
	_finish()
	_ack_inflight.clear()
	availability_changed.emit(false)


func _on_products(response: Dictionary, token: int) -> void:
	if not _matches(token, &"query"):
		return
	if response.get("response_code", -1) != OK:
		_fail(token, &"product_query_failed")
		return
	var products: Array = []
	_offers.clear()
	for detail: Dictionary in response.get("product_details", []):
		var id: StringName = StringName(detail.get("product_id", ""))
		var definition: Product = _configured.find(id)
		var offers: Variant = detail.get("one_time_purchase_offer_details_list", [])
		if definition == null or definition.kind != Product.Kind.NON_CONSUMABLE:
			continue
		if detail.get("product_type", "") != "inapp" or not offers is Array or offers.size() != 1:
			continue
		var offer: Dictionary = offers[0]
		if str(offer.get("formatted_price", "")).is_empty():
			continue
		definition.price_label = str(offer["formatted_price"])
		definition.title = str(detail.get("title", ""))
		definition.description = str(detail.get("description", ""))
		definition.currency_code = str(offer.get("price_currency_code", ""))
		definition.price_amount_micros = int(offer.get("price_amount_micros", 0))
		_offers[id] = offer.duplicate(true)
		products.append(definition)
	_finish()
	products_received.emit(token, products)


func _on_purchase(response: Dictionary, token: int) -> void:
	if not _matches(token, &"purchase"):
		return
	if response.get("response_code", -1) != OK:
		_purchase_error(token, int(response.get("response_code", -1)))
		return
	for entry: Dictionary in response.get("purchases", []):
		var identity: String = str(entry.get("purchase_token", ""))
		if not _valid_purchase(entry, _product_id):
			continue
		if _transactions.has(identity) and _transactions[identity].get("token", 0) != token:
			continue
		if not _pending_identity.is_empty() and identity != _pending_identity:
			continue
		if entry.get("purchase_state", 0) == PENDING:
			_pending_identity = identity
			purchase_pending.emit(token)
		elif entry.get("purchase_state", 0) == PURCHASED:
			var id: StringName = _product_id
			_finish()
			_emit_transaction(token, id, entry)
			return


func _valid_purchase(entry: Dictionary, id: StringName) -> bool:
	var ids: Variant = entry.get("product_ids", [])
	if not ids is Array and not ids is PackedStringArray:
		return false
	return not str(entry.get("purchase_token", "")).strip_edges().is_empty() and \
		ids.size() == 1 and String(ids[0]) == String(id) and _offers.has(id) and \
		int(entry.get("quantity", 1)) == 1 and not entry.get("is_suspended", false)


func _emit_transaction(token: int, id: StringName, entry: Dictionary) -> void:
	var identity: String = str(entry["purchase_token"])
	_transactions[identity] = {"token": token, "product_id": id,
		"acknowledged": bool(entry.get("is_acknowledged", false)), "durable": false}
	transaction_received.emit(token, id, identity)


func _on_owned(response: Dictionary, token: int) -> void:
	if not _matches(token, &"restore"):
		return
	if response.get("response_code", -1) != OK:
		_fail(token, &"owned_query_failed")
		return
	for entry: Dictionary in response.get("purchases", []):
		if not _matches(token, &"restore"):
			return
		var ids: Variant = entry.get("product_ids", [])
		if not ids is Array and not ids is PackedStringArray:
			continue
		if ids.size() != 1 or entry.get("purchase_state", 0) != PURCHASED:
			continue
		var id: StringName = StringName(ids[0])
		if _valid_purchase(entry, id):
			_emit_transaction(token, id, entry)
	if not _matches(token, &"restore"):
		return
	_finish()
	restore_completed.emit(token)


func _on_acknowledged(response: Dictionary) -> void:
	var identity: String = str(response.get("token", ""))
	if not _ack_inflight.has(identity):
		return
	_ack_inflight.erase(identity)
	if response.get("response_code", -1) == OK:
		_acknowledged[identity] = true
	# Failure keeps local durable ownership; only a later owned query retries acknowledgement.


func _purchase_error(token: int, code: int) -> void:
	_finish()
	if code == CANCELLED:
		purchase_cancelled.emit(token)
	else:
		operation_failed.emit(token, &"purchase_error")
	if code == ALREADY_OWNED:
		# ITEM_ALREADY_OWNED can follow reinstall/crash; reconcile via the durable restore path.
		recovery_requested.emit()


func _fail(token: int, reason: StringName) -> void:
	_finish()
	operation_failed.emit(token, reason)
