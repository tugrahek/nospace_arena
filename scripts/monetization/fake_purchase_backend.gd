class_name FakePurchaseBackend
extends "res://scripts/monetization/purchase_backend.gd"

## Manual deterministic driver. Arbitrary tokens let tests replay duplicate/stale callbacks.
var initialization_tokens: Array[int] = []
var query_tokens: Array[int] = []
var purchases: Array[Dictionary] = []
var restore_tokens: Array[int] = []


## Records initialization until the test explicitly completes it.
func initialize(token: int) -> void:
	initialization_tokens.append(token)


## Records a metadata request.
func query_products(token: int) -> void:
	query_tokens.append(token)


## Records a purchase request without granting anything.
func purchase(token: int, product_id: StringName) -> void:
	purchases.append({"token": token, "product_id": product_id})


## Records a restore request.
func restore_purchases(token: int) -> void:
	restore_tokens.append(token)


## Emits availability, including stale or duplicate results.
func complete_initialization(token: int, available: bool = true) -> void:
	initialized.emit(token, available)


## Supplies only test-owned metadata.
func complete_query(token: int, products: Array) -> void:
	products_received.emit(token, products)


## Reports a purchase or a restored transaction, including replayed callbacks.
func succeed(token: int, product_id: StringName, transaction_id: String) -> void:
	transaction_received.emit(token, product_id, transaction_id)


## Marks a purchase pending; a later callback resolves the same request.
func pend(token: int) -> void:
	purchase_pending.emit(token)


## Cancels a purchase without success.
func cancel(token: int) -> void:
	purchase_cancelled.emit(token)


## Fails the selected operation.
func fail(token: int, reason: StringName = &"test_failure") -> void:
	operation_failed.emit(token, reason)


## Finishes restore after zero or more transaction callbacks.
func complete_restore(token: int) -> void:
	restore_completed.emit(token)
