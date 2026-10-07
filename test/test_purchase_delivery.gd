extends GutTest

## Persistence tests use only an isolated user:// fixture; no real profile writes.
const EconomyScript = preload("res://scripts/autoload/Economy.gd")
const SaveDataScript = preload("res://scripts/meta/save_data.gd")
const SaveStoreScript = preload("res://scripts/meta/save_store.gd")
const Product = preload("res://scripts/monetization/purchase_product.gd")
const PurchaseServiceScript = preload("res://scripts/monetization/purchase_service.gd")
const FakeBackend = preload("res://scripts/monetization/fake_purchase_backend.gd")
const PATH: String = "user://24c_purchase_delivery_fixture.json"

class FailingEconomy:
	extends "res://scripts/autoload/Economy.gd"
	var fail_write_number: int = -1
	var write_count: int = 0
	func _persist_iap_data(data: SaveData) -> bool:
		write_count += 1
		if write_count == fail_write_number:
			return false
		return SaveStore.save_to(_save_path, data)

var _economy: EconomyScript


func before_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	_economy = EconomyScript.new()
	_economy._save_path = PATH
	add_child_autofree(_economy)


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_old_save_defaults_and_round_trip_iap_fields() -> void:
	var old: SaveData = SaveDataScript.from_dict({"currency": 17})
	assert_true(old.iap_transactions.is_empty())
	assert_true(old.iap_entitlements.is_empty())
	old.iap_transactions["tx-old"] = {"product_id": "skin", "kind": "non_consumable", "status": "delivered"}
	old.iap_entitlements.append("skin")
	assert_true(SaveStoreScript.save_to(PATH, old))
	var loaded: SaveData = SaveStoreScript.load_from(PATH)
	assert_eq(loaded.iap_transactions, old.iap_transactions)
	assert_eq(loaded.iap_entitlements, ["skin"])


func test_first_transaction_delivery_and_non_consumable_entitlement() -> void:
	var grants: Array[StringName] = []
	_economy.iap_entitlement_granted.connect(func(id: StringName) -> void: grants.append(id))
	var result: Dictionary = _economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(result["durable"])
	assert_false(result["duplicate"])
	assert_true(_economy.owns_iap_entitlement(&"skin"))
	assert_eq(_economy.iap_transaction_status("tx-one"), &"delivered")
	assert_eq(grants, [&"skin"])
	var reloaded: EconomyScript = _reloaded()
	assert_true(reloaded.owns_iap_entitlement(&"skin"))
	assert_eq(reloaded.iap_transaction_status("tx-one"), &"delivered")


func test_duplicate_transaction_and_reload_never_deliver_twice() -> void:
	_economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)
	var duplicate: Dictionary = _economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(duplicate["durable"])
	assert_true(duplicate["duplicate"])
	var reloaded: EconomyScript = _reloaded()
	duplicate = reloaded._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(duplicate["duplicate"])
	assert_eq(reloaded._data.iap_entitlements, ["skin"])


func test_duplicate_restore_transaction_is_harmless_and_new_restore_grants_once() -> void:
	_economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)
	var grants: Array[int] = [0]
	_economy.iap_entitlement_granted.connect(func(_id: StringName) -> void: grants[0] += 1)
	var duplicate: Dictionary = _economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(duplicate["duplicate"])
	var restored: Dictionary = _economy._deliver_purchase_transaction("tx-restore", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(restored["durable"])
	assert_false(restored["duplicate"])
	assert_eq(grants[0], 0, "an already owned entitlement is never granted twice")
	assert_eq(_economy._data.iap_entitlements, ["skin"])


func test_consumable_identity_is_durable_without_invented_reward() -> void:
	var result: Dictionary = _economy._deliver_purchase_transaction("tx-consume", &"future_item", Product.Kind.CONSUMABLE)
	assert_true(result["durable"])
	assert_false(_economy.owns_iap_entitlement(&"future_item"))
	assert_eq(_economy.iap_transaction_status("tx-consume"), &"delivered")
	assert_eq(SaveStoreScript.load_from(PATH).currency, 0)


func test_persisted_pending_delivery_recovers_deterministically() -> void:
	var economy: FailingEconomy = FailingEconomy.new()
	economy._save_path = PATH
	economy.fail_write_number = 2
	add_child_autofree(economy)
	var first: Dictionary = economy._deliver_purchase_transaction("tx-pending", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_false(first["durable"])
	assert_true(first["pending"])
	assert_eq(SaveStoreScript.load_from(PATH).iap_transactions["tx-pending"]["status"], "pending")
	assert_false(economy.owns_iap_entitlement(&"skin"))
	var recovered: Array[String] = economy.recover_pending_iap_deliveries()
	assert_eq(recovered, ["tx-pending"])
	assert_true(economy.owns_iap_entitlement(&"skin"))
	assert_eq(economy.iap_transaction_status("tx-pending"), &"delivered")
	assert_true(economy.recover_pending_iap_deliveries().is_empty())


func test_reload_reconciles_pending_record_and_retry_completes_once() -> void:
	var economy: FailingEconomy = FailingEconomy.new()
	economy._save_path = PATH
	economy.fail_write_number = 2
	add_child_autofree(economy)
	economy._deliver_purchase_transaction("tx-retry", &"skin", Product.Kind.NON_CONSUMABLE)
	var reloaded: EconomyScript = _reloaded()
	assert_eq(reloaded.iap_transaction_status("tx-retry"), &"pending")
	assert_eq(reloaded.recover_pending_iap_deliveries(), ["tx-retry"])
	assert_true(reloaded.owns_iap_entitlement(&"skin"))
	var duplicate: Dictionary = reloaded._deliver_purchase_transaction("tx-retry", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(duplicate["duplicate"])
	assert_eq(reloaded._data.iap_entitlements, ["skin"])


func test_first_save_failure_reports_no_delivery_and_retry_succeeds_once() -> void:
	var economy: FailingEconomy = FailingEconomy.new()
	economy._save_path = "user://24c_missing_directory/save.json"
	add_child_autofree(economy)
	var failed: Dictionary = economy._deliver_purchase_transaction("tx-failed", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_false(failed["durable"])
	assert_false(failed["pending"])
	assert_eq(economy.iap_transaction_status("tx-failed"), &"")
	economy._save_path = PATH
	var retry: Dictionary = economy._deliver_purchase_transaction("tx-failed", &"skin", Product.Kind.NON_CONSUMABLE)
	assert_true(retry["durable"])
	assert_eq(SaveStoreScript.load_from(PATH).iap_entitlements, ["skin"])


func test_stale_wrong_and_conflicting_transaction_context_rejected() -> void:
	assert_false(_economy._deliver_purchase_transaction("", &"skin", Product.Kind.NON_CONSUMABLE)["durable"])
	assert_false(_economy._deliver_purchase_transaction("tx-one", &"", Product.Kind.NON_CONSUMABLE)["durable"])
	assert_false(_economy._deliver_purchase_transaction("tx-one", &"skin", 99)["durable"])
	assert_true(_economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.NON_CONSUMABLE)["durable"])
	assert_false(_economy._deliver_purchase_transaction("tx-one", &"other", Product.Kind.NON_CONSUMABLE)["durable"])
	assert_false(_economy._deliver_purchase_transaction("tx-one", &"skin", Product.Kind.CONSUMABLE)["durable"])
	assert_true(_economy._data.iap_entitlements.has("skin"))


func test_service_reports_only_durable_delivery_and_restore_deduplicates() -> void:
	var service: PurchaseServiceScript = PurchaseServiceScript.new()
	var backend: FakeBackend = FakeBackend.new()
	service.configure_backend(backend)
	service.configure_delivery_handler(Callable(_economy, "_deliver_purchase_transaction"))
	add_child_autofree(service)
	backend.complete_initialization(backend.initialization_tokens.back())
	var successes: Array[int] = [0]
	service.purchase_succeeded.connect(func(_token: int, _id: StringName, _tx: String, _restored: bool) -> void:
		successes[0] += 1)
	var query: int = service.query_products()
	backend.complete_query(query, [Product.new(&"skin", Product.Kind.NON_CONSUMABLE)])
	var purchase_token: int = service.purchase(&"skin")
	backend.succeed(purchase_token, &"skin", "tx-service")
	assert_eq(successes[0], 1)
	assert_true(_economy.owns_iap_entitlement(&"skin"))
	var restore: int = service.restore_purchases()
	backend.succeed(restore, &"skin", "tx-service")
	backend.complete_restore(restore)
	assert_eq(successes[0], 1)
	assert_eq(_economy._data.iap_entitlements, ["skin"])


func test_service_never_reports_pending_write_as_success() -> void:
	var economy: FailingEconomy = FailingEconomy.new()
	economy._save_path = PATH
	economy.fail_write_number = 2
	add_child_autofree(economy)
	var service: PurchaseServiceScript = PurchaseServiceScript.new()
	var backend: FakeBackend = FakeBackend.new()
	service.configure_backend(backend)
	service.configure_delivery_handler(Callable(economy, "_deliver_purchase_transaction"))
	add_child_autofree(service)
	backend.complete_initialization(backend.initialization_tokens.back())
	var query: int = service.query_products()
	backend.complete_query(query, [Product.new(&"skin", Product.Kind.NON_CONSUMABLE)])
	var successes: Array[int] = [0]
	var pending: Array[int] = [0]
	service.purchase_succeeded.connect(func(_token: int, _id: StringName, _tx: String, _restored: bool) -> void:
		successes[0] += 1)
	service.purchase_delivery_pending.connect(func(_token: int, _id: StringName, _tx: String) -> void:
		pending[0] += 1)
	var token: int = service.purchase(&"skin")
	backend.succeed(token, &"skin", "tx-pending-service")
	assert_eq(successes[0], 0)
	assert_eq(pending[0], 1)
	assert_eq(economy.iap_transaction_status("tx-pending-service"), &"pending")
	assert_eq(economy.recover_pending_iap_deliveries(), ["tx-pending-service"])
	assert_true(economy.owns_iap_entitlement(&"skin"))


func _reloaded() -> EconomyScript:
	var economy: EconomyScript = EconomyScript.new()
	economy._save_path = PATH
	add_child_autofree(economy)
	return economy
