extends Node

## Authoritative IAP boundary; Economy owns checked persistence and native code stays in a backend.
const Backend = preload("res://scripts/monetization/purchase_backend.gd")
const NoopBackend = preload("res://scripts/monetization/noop_purchase_backend.gd")

signal initialization_completed(available: bool)
signal products_queried(token: int)
signal purchase_succeeded(token: int, product_id: StringName, transaction_id: String, restored: bool)
signal purchase_delivery_pending(token: int, product_id: StringName, transaction_id: String)
signal purchase_failed(token: int, product_id: StringName, reason: StringName)
signal purchase_cancelled(token: int, product_id: StringName)
signal purchase_pending(token: int, product_id: StringName)
signal request_failed(token: int, operation: StringName, reason: StringName)
signal restore_completed(token: int)

enum State { UNAVAILABLE, INITIALIZING, IDLE, QUERYING, PURCHASING, PENDING, RESTORING }

var state: State = State.UNAVAILABLE
var _backend: Backend = NoopBackend.new()
var _catalog: PurchaseCatalog = PurchaseCatalog.new()
var _available: bool = false
var _backend_locked: bool = false
var _next_token: int = 0
var _active_token: int = 0
var _operation: StringName = &""
var _product_id: StringName = &""
var _seen_transactions: Dictionary = {}
var _delivery_handler: Callable
var _recovery_requested: bool = false
var _recovery_needs_query: bool = false
var _recovery_query_token: int = 0


func _ready() -> void:
	if get_parent() == get_tree().root and name == "PurchaseService":
		_delivery_handler = Callable(Economy, "_deliver_purchase_transaction")
		if OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling"):
			_backend = GooglePlayPurchaseBackend.new()
	_connect_backend()
	initialize()


func _exit_tree() -> void:
	_backend.shutdown()


## Injects a backend before service initialization; replacement later is rejected.
func configure_backend(backend: Backend) -> bool:
	if backend == null or _backend_locked:
		return false
	_backend = backend
	return true


## Installs a durable delivery handler before initialization; production autoload binds Economy.
func configure_delivery_handler(handler: Callable) -> bool:
	if handler.is_null() or _backend_locked:
		return false
	_delivery_handler = handler
	return true


## Starts initialization once at a time. Returns an accepted token, or zero.
func initialize() -> int:
	if _available or _active_token != 0:
		return 0
	_backend_locked = true
	_connect_backend()
	var token: int = _begin(&"initialize", State.INITIALIZING)
	_backend.initialize(token)
	return token


## Whether the backend is initialized, independent of whether an operation is busy.
func is_available() -> bool:
	return _available


## Returns detached catalog entries; no products exist until a successful query.
func products() -> Array[PurchaseProduct]:
	return _catalog.all()


## Queries backend metadata/prices; rejects concurrent operations.
func query_products() -> int:
	if not _can_start():
		return 0
	var token: int = _begin(&"query", State.QUERYING)
	_backend.query_products(token)
	return token


## Starts a known product purchase. Rejection returns zero and never invokes the backend.
func purchase(product_id: StringName) -> int:
	if not _can_start() or _catalog.find(product_id) == null:
		return 0
	var token: int = _begin(&"purchase", State.PURCHASING, product_id)
	_backend.purchase(token, product_id)
	return token


## Starts restore. Backends stream restorable transactions then explicit completion.
func restore_purchases() -> int:
	if not _can_start():
		return 0
	var token: int = _begin(&"restore", State.RESTORING)
	_backend.restore_purchases(token)
	return token


func _can_start() -> bool:
	return _available and _active_token == 0


func _begin(operation: StringName, next_state: State, product_id: StringName = &"") -> int:
	_next_token += 1
	_active_token = _next_token
	_operation = operation
	_product_id = product_id
	state = next_state
	return _active_token


func _matches(token: int, operation: StringName) -> bool:
	return token != 0 and token == _active_token and _operation == operation


func _finish() -> void:
	_active_token = 0
	_operation = &""
	_product_id = &""
	state = State.IDLE if _available else State.UNAVAILABLE
	if _recovery_requested:
		_resume_recovery.call_deferred()


func _connect_backend() -> void:
	if _backend.initialized.is_connected(_on_initialized):
		return
	_backend.initialized.connect(_on_initialized)
	_backend.products_received.connect(_on_products)
	_backend.transaction_received.connect(_on_transaction)
	_backend.purchase_pending.connect(_on_pending)
	_backend.purchase_cancelled.connect(_on_cancelled)
	_backend.operation_failed.connect(_on_failed)
	_backend.restore_completed.connect(_on_restore_completed)
	_backend.recovery_requested.connect(_on_recovery_requested)
	_backend.availability_changed.connect(_on_availability_changed)


func _on_initialized(token: int, available: bool) -> void:
	if not _matches(token, &"initialize"):
		return
	_available = available
	_finish()
	initialization_completed.emit(available)


func _on_products(token: int, entries: Array) -> void:
	if not _matches(token, &"query"):
		return
	if not _catalog.replace(entries):
		_on_failed(token, &"invalid_catalog")
		return
	if token == _recovery_query_token:
		_recovery_needs_query = false
		_recovery_query_token = 0
	_finish()
	products_queried.emit(token)


## Correlation and session deduplication are enforced before any outward success signal.
func _on_transaction(token: int, product_id: StringName, transaction_id: String) -> void:
	var restoring: bool = _matches(token, &"restore")
	if not restoring and not _matches(token, &"purchase"):
		return
	var product: PurchaseProduct = _catalog.find(product_id)
	if product == null or transaction_id.is_empty():
		return
	if restoring and product.kind != PurchaseProduct.Kind.NON_CONSUMABLE:
		return
	if not restoring and product_id != _product_id:
		return
	if _handle_seen_transaction(token, product, transaction_id, restoring):
		return
	if not _delivery_handler.is_valid():
		return
	var delivery: Dictionary = _delivery_handler.call(transaction_id, product_id, product.kind)
	if not delivery.get("durable", false):
		if restoring:
			return
		_finish()
		if delivery.get("pending", false):
			purchase_delivery_pending.emit(token, product_id, transaction_id)
		else:
			purchase_failed.emit(token, product_id, &"delivery_not_persisted")
		return
	_seen_transactions[transaction_id] = {"product_id": product_id, "kind": product.kind}
	if not restoring:
		_finish()
	_backend.delivery_confirmed(token, product_id, transaction_id)
	if not delivery.get("duplicate", false):
		purchase_succeeded.emit(token, product_id, transaction_id, restoring)


func _handle_seen_transaction(token: int, product: PurchaseProduct, identity: String, restoring: bool) -> bool:
	if not _seen_transactions.has(identity):
		return false
	var seen: Dictionary = _seen_transactions[identity]
	if seen["product_id"] != product.id or seen["kind"] != product.kind:
		return true
	if not restoring:
		_finish()
	_backend.delivery_confirmed(token, product.id, identity)
	if not restoring:
		purchase_failed.emit(token, product.id, &"duplicate_transaction")
	return true


func _on_pending(token: int) -> void:
	if not _matches(token, &"purchase") or state == State.PENDING:
		return
	state = State.PENDING
	purchase_pending.emit(token, _product_id)


func _on_cancelled(token: int) -> void:
	if not _matches(token, &"purchase"):
		return
	var id: StringName = _product_id
	_finish()
	purchase_cancelled.emit(token, id)


func _on_failed(token: int, reason: StringName) -> void:
	if token == 0 or token != _active_token:
		return
	var operation: StringName = _operation
	var id: StringName = _product_id
	if token == _recovery_query_token:
		_recovery_requested = false
		_recovery_query_token = 0
	_finish()
	if operation == &"purchase":
		purchase_failed.emit(token, id, reason)
	else:
		request_failed.emit(token, operation, reason)


func _on_restore_completed(token: int) -> void:
	if not _matches(token, &"restore"):
		return
	_finish()
	restore_completed.emit(token)


func _on_recovery_requested() -> void:
	_recovery_requested = true
	_recovery_needs_query = true
	_resume_recovery.call_deferred()


func _resume_recovery() -> void:
	if not is_inside_tree() or not _recovery_requested or not _can_start():
		return
	if _recovery_needs_query:
		_recovery_query_token = _next_token + 1
		query_products()
	else:
		_recovery_requested = false
		restore_purchases()


func _on_availability_changed(available: bool) -> void:
	_available = available
	if not available and _active_token != 0:
		_on_failed(_active_token, &"backend_disconnected")
	elif _active_token == 0:
		state = State.IDLE if available else State.UNAVAILABLE
