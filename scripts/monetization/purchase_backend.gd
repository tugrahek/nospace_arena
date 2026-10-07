class_name PurchaseBackend
extends RefCounted

## Platform-neutral callback contract. Every callback echoes its request token.
## Success describes a backend-reported transaction, NOT durable delivery or validation.
## The service confirms durable delivery before a native backend may acknowledge.
## Transaction IDs must be stable and unique across this backend's products; consumables
## require a fresh ID per purchase. Restore requires queried metadata and never replays consumables.
signal initialized(token: int, available: bool)
signal products_received(token: int, products: Array)
signal transaction_received(token: int, product_id: StringName, transaction_id: String)
signal purchase_pending(token: int)
signal purchase_cancelled(token: int)
signal operation_failed(token: int, reason: StringName)
signal restore_completed(token: int)
signal recovery_requested
signal availability_changed(available: bool)


## Initializes the backend. The default has no purchasing capability.
func initialize(token: int) -> void:
	initialized.emit(token, false)


## Queries configured metadata and localized prices, without inventing products.
func query_products(token: int) -> void:
	operation_failed.emit(token, &"backend_unavailable")


## Starts a purchase of an exact catalog ID.
func purchase(token: int, _product_id: StringName) -> void:
	operation_failed.emit(token, &"backend_unavailable")


## Streams non-consumable transactions, then emits restore_completed (including empty restore).
func restore_purchases(token: int) -> void:
	operation_failed.emit(token, &"backend_unavailable")


## Receives a trusted durable result, including already-delivered transactions.
func delivery_confirmed(_token: int, _product_id: StringName, _transaction_id: String) -> void:
	pass


## Releases native listeners when the owning service leaves the tree.
func shutdown() -> void:
	pass
