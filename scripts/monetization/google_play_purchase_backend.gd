class_name GooglePlayPurchaseBackend
extends "res://scripts/monetization/purchase_backend.gd"

## Android adapter. Coin candidates require server verification; non-consumables retain delivery.
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
	_configured.replace(_normalize_definitions(definitions))


func _normalize_definitions(definitions: Array) -> Array:
	var products: Array = []
	for definition: Variant in definitions:
		if definition is CoinPackDefinition:
			if not definition.is_valid():
				return []
			products.append(Product.new(definition.sku, Product.Kind.CONSUMABLE))
		elif definition is Product:
			if CoinPackDefinition.expected_coins(definition.id) > 0 and definition.kind != Product.Kind.CONSUMABLE:
				return []
			if definition.kind == Product.Kind.NON_CONSUMABLE or CoinPackDefinition.expected_coins(definition.id) > 0:
				products.append(definition)
		else:
			return []
	return products


## Initializes the native client; unsupported platforms report unavailable safely.
func initialize(token: int) -> void:
	if not _bridge.is_native_available():
		initialized.emit(token, false)
		return
	if not _begin(token, &"initialize"):
		return
	_connection_token = token
	_bridge.initialize(_on_connected.bind(token), _on_connect_error.bind(token), _on_disconnected)


## Queries explicitly configured products only; localized prices come exclusively from Google.
func query_products(token: int) -> void:
	if not _ready_request(token, &"query"):
		return
	_offers.clear()
	var ids: PackedStringArray = PackedStringArray()
	for product: Product in _configured.all():
		ids.append(String(product.id))
	if ids.is_empty():
		_on_products({"response_code": OK, "product_details": []}, token)
	else:
		_bridge.query_products(ids, _on_products.bind(token))


## Launches one unambiguous queried offer; the immutable closure carries the service token.
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
	# A client delivery claim can never authorize coin acknowledgement or consumption.
	if CoinPackDefinition.expected_coins(product_id) > 0:
		return
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
	_offers.clear()
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
	var details: Variant = response.get("product_details", [])
	if not details is Array:
		_fail(token, &"invalid_product_response")
		return
	for detail: Variant in details:
		if not detail is Dictionary:
			continue
		var id: StringName = _detail_id(detail)
		if _offers.has(id):
			_fail(token, &"ambiguous_product_response")
			return
		var definition: Product = _configured.find(id)
		var offers: Variant = detail.get("one_time_purchase_offer_details_list", [])
		if definition == null:
			continue
		if detail.get("product_type", "") != "inapp" or not offers is Array:
			continue
		var offer: Dictionary = _select_offer(offers, definition.kind == Product.Kind.CONSUMABLE)
		if offer.is_empty():
			continue
		_apply_metadata(definition, detail, offer)
		_offers[id] = offer.duplicate(true)
		products.append(definition)
	_finish()
	products_received.emit(token, products)


func _detail_id(detail: Dictionary) -> StringName:
	var id: Variant = detail.get("product_id")
	return StringName(id) if id is String or id is StringName else &""


func _apply_metadata(product: Product, detail: Dictionary, offer: Dictionary) -> void:
	product.price_label = str(offer["formatted_price"])
	product.title = str(detail.get("title", ""))
	product.description = str(detail.get("description", ""))
	product.currency_code = str(offer.get("price_currency_code", ""))
	product.price_amount_micros = int(offer.get("price_amount_micros", 0))


func _select_offer(offers: Array, consumable: bool) -> Dictionary:
	if not consumable:
		if offers.size() == 1 and offers[0] is Dictionary and not str(offers[0].get("formatted_price", "")).is_empty():
			return offers[0]
		return {}
	var valid: Array[Dictionary] = []
	for offer: Variant in offers:
		if offer is Dictionary and _valid_coin_offer(offer):
			valid.append(offer)
	return valid[0] if valid.size() == 1 else {}


func _valid_coin_offer(offer: Dictionary) -> bool:
	var price: Variant = offer.get("formatted_price")
	var currency: Variant = offer.get("price_currency_code")
	var micros: Variant = offer.get("price_amount_micros")
	var option: Variant = offer.get("purchase_option_id")
	var offer_id: Variant = offer.get("offer_id")
	if not price is String or price.strip_edges().is_empty() or not currency is String or currency.length() != 3:
		return false
	for character: String in currency:
		if character < "A" or character > "Z":
			return false
	return (micros is int or micros is float) and is_finite(float(micros)) and micros > 0 and micros == int(micros) and \
		option is String and not option.strip_edges().is_empty() and (offer_id == null or offer_id is String)


func _on_purchase(response: Dictionary, token: int) -> void:
	if not _matches(token, &"purchase"):
		return
	if response.get("response_code", -1) != OK:
		_purchase_error(token, int(response.get("response_code", -1)))
		return
	var entries: Variant = response.get("purchases", [])
	if not entries is Array:
		_fail(token, &"invalid_purchase_response")
		return
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
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
	if CoinPackDefinition.expected_coins(id) > 0:
		var quantity: Variant = entry.get("quantity")
		if not entry.get("purchase_token") is String:
			return false
		if not (quantity is int or quantity is float) or quantity != 1:
			return false
		if ids.size() != 1 or not (ids[0] is String or ids[0] is StringName):
			return false
	return not str(entry.get("purchase_token", "")).strip_edges().is_empty() and \
		ids.size() == 1 and String(ids[0]) == String(id) and _offers.has(id) and \
		int(entry.get("quantity", 1)) == 1 and not entry.get("is_suspended", false)


func _emit_transaction(token: int, id: StringName, entry: Dictionary) -> void:
	var identity: String = str(entry["purchase_token"])
	if CoinPackDefinition.expected_coins(id) > 0:
		verification_required.emit(token, id, identity)
		return
	_transactions[identity] = {"token": token, "product_id": id,
		"acknowledged": bool(entry.get("is_acknowledged", false)), "durable": false}
	transaction_received.emit(token, id, identity)


func _on_owned(response: Dictionary, token: int) -> void:
	if not _matches(token, &"restore"):
		return
	if response.get("response_code", -1) != OK:
		_fail(token, &"owned_query_failed")
		return
	var entries: Variant = response.get("purchases", [])
	if not entries is Array:
		_fail(token, &"invalid_owned_response")
		return
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
		if not _matches(token, &"restore"):
			return
		var ids: Variant = entry.get("product_ids", [])
		if not ids is Array and not ids is PackedStringArray:
			continue
		if ids.size() != 1 or entry.get("purchase_state", 0) != PURCHASED:
			continue
		if not (ids[0] is String or ids[0] is StringName):
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
	if _operation == &"query":
		_offers.clear()
	_finish()
	operation_failed.emit(token, reason)
