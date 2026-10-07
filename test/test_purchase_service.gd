extends GutTest

## Pure foundation tests. Fictional metadata never enters the production catalog.
const Service = preload("res://scripts/monetization/purchase_service.gd")
const Fake = preload("res://scripts/monetization/fake_purchase_backend.gd")
const Product = preload("res://scripts/monetization/purchase_product.gd")

class ImmediateBackend:
	extends "res://scripts/monetization/purchase_backend.gd"
	func initialize(token: int) -> void:
		initialized.emit(token, true)
	func query_products(token: int) -> void:
		products_received.emit(token, [Product.new(&"test_immediate")])
	func purchase(token: int, id: StringName) -> void:
		transaction_received.emit(token, id, "immediate-transaction")
	func restore_purchases(token: int) -> void:
		restore_completed.emit(token)

var _service: Service
var _fake: Fake


func before_each() -> void:
	_service = Service.new()
	_fake = Fake.new()
	assert_true(_service.configure_backend(_fake))
	add_child_autofree(_service)
	_fake.complete_initialization(_fake.initialization_tokens.back())
	watch_signals(_service)


func _query() -> int:
	var token: int = _service.query_products()
	_fake.complete_query(token, [Product.new(&"test_consumable", Product.Kind.CONSUMABLE, "test price"),
		Product.new(&"test_permanent", Product.Kind.NON_CONSUMABLE, "test price")])
	return token


func test_noop_and_autoload_are_unavailable_and_empty() -> void:
	var service: Service = Service.new()
	add_child_autofree(service)
	assert_eq(service.state, Service.State.UNAVAILABLE)
	assert_false(service.is_available())
	assert_true(service.products().is_empty())
	assert_eq(service.query_products(), 0)
	assert_eq(service.purchase(&"test_consumable"), 0)
	assert_eq(service.restore_purchases(), 0)
	assert_false(PurchaseService.is_available())
	assert_true(PurchaseService.products().is_empty())


func test_initialization_serializes_retries_and_rejects_stale_callbacks() -> void:
	var service: Service = Service.new()
	var fake: Fake = Fake.new()
	service.configure_backend(fake)
	add_child_autofree(service)
	var first: int = fake.initialization_tokens.back()
	assert_eq(service.state, Service.State.INITIALIZING)
	assert_eq(service.initialize(), 0)
	assert_eq(service.query_products(), 0)
	fake.fail(first)
	assert_eq(service.state, Service.State.UNAVAILABLE)
	var second: int = service.initialize()
	assert_gt(second, first)
	fake.complete_initialization(first)
	assert_false(service.is_available())
	fake.complete_initialization(second)
	assert_eq(service.state, Service.State.IDLE)
	assert_true(service.is_available())
	assert_eq(service.initialize(), 0)
	assert_false(service.configure_backend(Fake.new()))


func test_product_query_correlates_and_copies_metadata() -> void:
	var token: int = _service.query_products()
	assert_eq(_service.state, Service.State.QUERYING)
	_fake.complete_query(token + 1, [])
	assert_eq(_service.state, Service.State.QUERYING)
	var product: Product = Product.new(&"test_consumable", Product.Kind.CONSUMABLE, "test price")
	_fake.complete_query(token, [product])
	product.price_label = "mutated"
	assert_eq(_service.products()[0].price_label, "test price")
	_service.products()[0].id = &"mutated"
	assert_eq(_service.products()[0].id, &"test_consumable")
	_fake.complete_query(token, [])
	assert_signal_emit_count(_service, "products_queried", 1)
	assert_eq(_service.state, Service.State.IDLE)


func test_invalid_catalog_preserves_previous_query() -> void:
	_query()
	var token: int = _service.query_products()
	_fake.complete_query(token, [Product.new(&"same"), Product.new(&"same")])
	assert_eq(_service.products().size(), 2)
	assert_signal_emitted_with_parameters(_service, "request_failed", [token, &"query", &"invalid_catalog"])


func test_empty_query_is_valid_and_does_not_invent_products() -> void:
	var token: int = _service.query_products()
	_fake.complete_query(token, [])
	assert_signal_emitted_with_parameters(_service, "products_queried", [token])
	assert_true(_service.products().is_empty())


func test_purchase_rejection_and_single_active_request() -> void:
	assert_eq(_service.purchase(&"unknown"), 0)
	_query()
	assert_eq(_service.purchase(&"unknown"), 0)
	var token: int = _service.purchase(&"test_consumable")
	assert_gt(token, 0)
	assert_eq(_fake.purchases.back(), {"token": token, "product_id": &"test_consumable"})
	assert_eq(_service.state, Service.State.PURCHASING)
	assert_eq(_service.purchase(&"test_permanent"), 0)
	assert_eq(_service.query_products(), 0)
	assert_eq(_service.restore_purchases(), 0)
	assert_eq(_fake.purchases.size(), 1)


func test_success_and_duplicate_terminal_callbacks() -> void:
	_query()
	var token: int = _service.purchase(&"test_consumable")
	_fake.succeed(token, &"test_permanent", "wrong product")
	_fake.succeed(token, &"test_consumable", "")
	assert_eq(_service.state, Service.State.PURCHASING)
	_fake.succeed(token, &"test_consumable", "transaction-1")
	_fake.succeed(token, &"test_consumable", "transaction-1")
	_fake.cancel(token)
	_fake.fail(token)
	_fake.pend(token)
	assert_eq(_service.state, Service.State.IDLE)
	assert_signal_emitted_with_parameters(_service, "purchase_succeeded", [token, &"test_consumable", "transaction-1", false])
	assert_signal_emit_count(_service, "purchase_succeeded", 1)
	assert_signal_not_emitted(_service, "purchase_cancelled")
	assert_signal_not_emitted(_service, "purchase_failed")
	assert_signal_not_emitted(_service, "purchase_pending")


func test_cancel_is_terminal_and_allows_retry() -> void:
	_query()
	var token: int = _service.purchase(&"test_consumable")
	_fake.cancel(token)
	_fake.cancel(token)
	_fake.succeed(token, &"test_consumable", "late")
	assert_eq(_service.state, Service.State.IDLE)
	assert_signal_emit_count(_service, "purchase_cancelled", 1)
	assert_signal_emitted_with_parameters(_service, "purchase_cancelled", [token, &"test_consumable"])
	assert_signal_not_emitted(_service, "purchase_succeeded")
	assert_gt(_service.purchase(&"test_consumable"), token)


func test_failure_is_terminal_and_stale_token_cannot_finish_new_request() -> void:
	_query()
	var old: int = _service.purchase(&"test_consumable")
	_fake.fail(old, &"failed")
	assert_signal_emitted_with_parameters(_service, "purchase_failed", [old, &"test_consumable", &"failed"])
	var current: int = _service.purchase(&"test_consumable")
	_fake.succeed(old, &"test_consumable", "old")
	_fake.fail(old)
	_fake.cancel(old)
	_fake.pend(old)
	assert_eq(_service.state, Service.State.PURCHASING)
	_fake.succeed(current, &"test_consumable", "new")
	assert_signal_emit_count(_service, "purchase_succeeded", 1)


func test_pending_remains_active_and_resolves_once() -> void:
	_query()
	var token: int = _service.purchase(&"test_consumable")
	_fake.pend(token)
	_fake.pend(token)
	assert_eq(_service.state, Service.State.PENDING)
	assert_signal_emit_count(_service, "purchase_pending", 1)
	assert_eq(_service.restore_purchases(), 0)
	assert_eq(_service.purchase(&"test_consumable"), 0)
	_fake.succeed(token, &"test_consumable", "pending-transaction")
	assert_eq(_service.state, Service.State.IDLE)
	assert_signal_emit_count(_service, "purchase_succeeded", 1)


func test_restore_stream_filters_and_deduplicates_transactions() -> void:
	_query()
	var token: int = _service.restore_purchases()
	assert_eq(_service.state, Service.State.RESTORING)
	assert_eq(_service.query_products(), 0)
	assert_eq(_service.restore_purchases(), 0)
	_fake.succeed(token, &"unknown", "unknown")
	_fake.succeed(token, &"test_consumable", "consumed")
	_fake.succeed(token, &"test_permanent", "restored")
	_fake.succeed(token, &"test_permanent", "restored")
	_fake.complete_restore(token + 1)
	assert_eq(_service.state, Service.State.RESTORING)
	_fake.complete_restore(token)
	_fake.complete_restore(token)
	_fake.succeed(token, &"test_permanent", "late")
	assert_signal_emitted_with_parameters(_service, "purchase_succeeded", [token, &"test_permanent", "restored", true])
	assert_signal_emit_count(_service, "purchase_succeeded", 1)
	assert_signal_emit_count(_service, "restore_completed", 1)
	assert_eq(_service.state, Service.State.IDLE)
	var next: int = _service.restore_purchases()
	_fake.succeed(next, &"test_permanent", "restored")
	_fake.complete_restore(next)
	assert_signal_emit_count(_service, "purchase_succeeded", 1)


func test_empty_restore_and_restore_failure() -> void:
	var token: int = _service.restore_purchases()
	_fake.complete_restore(token)
	assert_signal_emitted_with_parameters(_service, "restore_completed", [token])
	token = _service.restore_purchases()
	_fake.fail(token, &"restore_failed")
	assert_signal_emitted_with_parameters(_service, "request_failed", [token, &"restore", &"restore_failed"])
	assert_eq(_service.state, Service.State.IDLE)


func test_transaction_replay_on_new_purchase_cannot_emit_second_success() -> void:
	_query()
	var first: int = _service.purchase(&"test_consumable")
	_fake.succeed(first, &"test_consumable", "same-transaction")
	var second: int = _service.purchase(&"test_consumable")
	_fake.succeed(second, &"test_consumable", "same-transaction")
	assert_signal_emit_count(_service, "purchase_succeeded", 1)
	assert_signal_emitted_with_parameters(_service, "purchase_failed", [second, &"test_consumable", &"duplicate_transaction"])
	assert_eq(_service.state, Service.State.IDLE)


func test_synchronous_backend_callbacks_preserve_tokens_and_idle_state() -> void:
	var service: Service = Service.new()
	service.configure_backend(ImmediateBackend.new())
	watch_signals(service)
	add_child_autofree(service)
	assert_true(service.is_available())
	var query_token: int = service.query_products()
	assert_gt(query_token, 0)
	assert_signal_emitted_with_parameters(service, "products_queried", [query_token])
	var token: int = service.purchase(&"test_immediate")
	assert_signal_emitted_with_parameters(service, "purchase_succeeded", [token, &"test_immediate", "immediate-transaction", false])
	var restored: int = service.restore_purchases()
	assert_signal_emitted_with_parameters(service, "restore_completed", [restored])
	assert_eq(service.state, Service.State.IDLE)


func test_success_listener_can_start_next_request_without_old_callback_finishing_it() -> void:
	_query()
	var tokens: Array[int] = []
	_service.purchase_succeeded.connect(func(_token: int, _id: StringName, _transaction: String, _restored: bool) -> void:
		tokens.append(_service.purchase(&"test_consumable")))
	var first: int = _service.purchase(&"test_consumable")
	_fake.succeed(first, &"test_consumable", "first")
	assert_gt(tokens[0], first)
	_fake.succeed(first, &"test_consumable", "first")
	_fake.fail(first)
	assert_eq(_service.state, Service.State.PURCHASING)
	assert_signal_emit_count(_service, "purchase_succeeded", 1)
	_fake.cancel(tokens[0])
	assert_eq(_service.state, Service.State.IDLE)


func test_pending_can_fail_or_cancel_without_success() -> void:
	_query()
	var token: int = _service.purchase(&"test_permanent")
	_fake.pend(token)
	_fake.fail(token)
	assert_eq(_service.state, Service.State.IDLE)
	token = _service.purchase(&"test_permanent")
	_fake.pend(token)
	_fake.cancel(token)
	assert_eq(_service.state, Service.State.IDLE)
	assert_signal_emit_count(_service, "purchase_pending", 2)
	assert_signal_emit_count(_service, "purchase_failed", 1)
	assert_signal_emit_count(_service, "purchase_cancelled", 1)
	assert_signal_not_emitted(_service, "purchase_succeeded")
