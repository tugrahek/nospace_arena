extends GutTest

## Isolated profile fixtures; never reads/writes the player's canonical profile.
const EconomyScript = preload("res://scripts/autoload/Economy.gd")
const PATH: String = "user://23f1_supply_box_fixture.json"
const FIXTURE_SEED: int = 7351

class FailingEconomy:
	extends "res://scripts/autoload/Economy.gd"
	var fail_supply_save: bool = false
	func _commit_supply_data(data: SaveData) -> bool:
		return false if fail_supply_save else super._commit_supply_data(data)

var _economy: FailingEconomy
var _core: SupplyBoxCore
var _table: SupplyRewardTable


func before_each() -> void:
	_cleanup()
	_economy = FailingEconomy.new()
	_economy._save_path = PATH
	add_child_autofree(_economy)
	var rng := RandomNumberGenerator.new()
	rng.seed = FIXTURE_SEED
	_core = SupplyBoxCore.new(func() -> SaveData: return _economy._data,
		_economy._commit_supply_data, rng)
	_table = _fixture_table(&"coins", 17)


func after_each() -> void:
	_cleanup()


func _cleanup() -> void:
	for suffix: String in ["", SaveStore.TEMP_SUFFIX, SaveStore.BACKUP_SUFFIX]:
		var absolute: String = ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(PATH + suffix) or DirAccess.dir_exists_absolute(absolute):
			DirAccess.remove_absolute(absolute)


func _fixture_table(type: StringName, amount: int) -> SupplyRewardTable:
	var table := SupplyRewardTable.new()
	table.table_key = &"test_only"
	table.version = 3
	var entry := SupplyRewardEntry.new()
	entry.reward_type = type
	entry.amount = amount
	entry.weight = 1.0
	table.entries.append(entry)
	return table


func _reserve(id: String = "box-1") -> bool:
	return _core.reserve(id, "fixture_source", "fixture_context", _table)


func _authorize(id: String = "box-1") -> bool:
	return _core._authorize(id, "fixture_source", "fixture_context")


func _reload() -> SupplyBoxCore:
	var economy: EconomyScript = EconomyScript.new()
	economy._save_path = PATH
	add_child_autofree(economy)
	return economy.supply_boxes()


func test_weighted_selection_exact_boundaries() -> void:
	var other: SupplyRewardEntry = _fixture_table(&"extra_life", 2).entries[0]
	other.weight = 3.0
	_table.entries.append(other)
	assert_eq(_table.select_reward(0.0), {"reward_type": "coins", "amount": 17})
	assert_eq(_table.select_reward(0.24999)["reward_type"], "coins")
	assert_eq(_table.select_reward(0.25), {"reward_type": "extra_life", "amount": 2})
	assert_eq(_table.select_reward(0.99999)["reward_type"], "extra_life")
	assert_true(_table.select_reward(-0.1).is_empty())
	assert_true(_table.select_reward(1.0).is_empty())
	assert_true(_table.select_reward(NAN).is_empty())


func test_resource_table_round_trip() -> void:
	var path: String = "user://23f1_table_fixture.tres"
	assert_eq(ResourceSaver.save(_table, path), OK)
	var loaded: SupplyRewardTable = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_eq(loaded.table_key, &"test_only")
	assert_eq(loaded.version, 3)
	assert_eq(loaded.select_reward(0.5), _table.select_reward(0.5))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_private_seeded_rng_selects_repeatably() -> void:
	_table.entries.append(_fixture_table(&"slow_start", 2).entries[0])
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = FIXTURE_SEED
	var expected: Dictionary = _table.select_reward(float(expected_rng.randi()) / SupplyBoxCore.RNG_UNIT_SCALE)
	assert_true(_reserve())
	assert_eq(_core.box_status("box-1")["reward_type"], expected["reward_type"])
	assert_eq(_core.box_status("box-1")["amount"], expected["amount"])


func test_reservation_persists_all_frozen_fields() -> void:
	assert_true(_reserve())
	var saved: SaveData = SaveStore.load_from(PATH)
	assert_eq(saved.supply_boxes["box-1"], {
		"box_id": "box-1", "source": "fixture_source", "context": "fixture_context",
		"table_key": "test_only", "table_version": 3.0,
		"reward_type": "coins", "amount": 17.0, "state": "reserved",
	})
	assert_eq(saved.currency, 0)
	assert_true(saved.boost_charges.is_empty())


func test_reload_cannot_reroll_even_after_table_changes() -> void:
	assert_true(_reserve())
	_table.entries[0].amount = 999
	var reloaded: SupplyBoxCore = _reload()
	assert_false(reloaded.reserve("box-1", "different", "different", _table))
	assert_eq(int(reloaded.box_status("box-1")["amount"]), 17)


func test_reserved_never_delivers_or_recovers() -> void:
	assert_true(_reserve())
	assert_false(_core.deliver("box-1"))
	assert_true(_core.recover_authorized().is_empty())
	var reloaded: SupplyBoxCore = _reload()
	assert_true(reloaded.recover_authorized().is_empty())
	assert_eq(reloaded.box_status("box-1")["state"], "reserved")
	assert_eq(SaveStore.load_from(PATH).currency, 0)


func test_authorization_only_persists_proof_not_reward() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	assert_false(_authorize())
	assert_eq(_economy.balance(), 0)
	assert_eq(SaveStore.load_from(PATH).currency, 0)
	assert_eq(_core.box_status("box-1")["state"], "authorized")


func test_coin_delivery_exactly_once_and_signals_after_save() -> void:
	var rewards: Array = []
	_core.box_delivered.connect(func(id: String, reward: Dictionary) -> void:
		assert_eq(SaveStore.load_from(PATH).supply_boxes[id]["state"], "delivered")
		assert_eq(SaveStore.load_from(PATH).currency, 17)
		rewards.append(reward))
	watch_signals(_economy)
	assert_true(_reserve())
	assert_true(_authorize())
	assert_true(_core.deliver("box-1"))
	assert_false(_core.deliver("box-1"))
	assert_false(_authorize())
	assert_eq(_economy.balance(), 17)
	assert_eq(rewards, [{"reward_type": "coins", "amount": 17}])
	assert_signal_emit_count(_economy, "currency_changed", 1)


func test_slow_start_delivery() -> void:
	_check_boost(&"slow_start")


func test_coin_bonus_delivery() -> void:
	_check_boost(&"coin_bonus")


func test_extra_life_delivery() -> void:
	_check_boost(&"extra_life")


func _check_boost(type: StringName) -> void:
	_table = _fixture_table(type, 2)
	watch_signals(_economy)
	assert_true(_reserve())
	assert_true(_authorize())
	assert_true(_core.deliver("box-1"))
	assert_false(_core.deliver("box-1"))
	assert_eq(_economy.boost_count(type), 2)
	assert_eq(SaveStore.load_from(PATH).boost_count(type), 2)
	assert_eq(_economy.balance(), 0)
	assert_signal_emit_count(_economy, "boosts_changed", 1)


func test_failed_delivery_has_no_reward_signal_and_retry_once() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	_economy.fail_supply_save = true
	watch_signals(_core)
	watch_signals(_economy)
	assert_false(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 0)
	assert_eq(_core.box_status("box-1")["state"], "authorized")
	assert_eq(SaveStore.load_from(PATH).currency, 0)
	assert_signal_not_emitted(_core, "box_delivered")
	assert_signal_not_emitted(_economy, "currency_changed")
	_economy.fail_supply_save = false
	assert_true(_core.deliver("box-1"))
	assert_false(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 17)


func test_real_checked_save_failure_blocks_delivery() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	var temp: String = ProjectSettings.globalize_path(PATH + SaveStore.TEMP_SUFFIX)
	assert_eq(DirAccess.make_dir_absolute(temp), OK)
	assert_false(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 0)
	assert_eq(SaveStore.load_from(PATH).supply_boxes["box-1"]["state"], "authorized")
	DirAccess.remove_absolute(temp)
	assert_true(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 17)


func test_failed_reservation_is_not_visible_or_authorizable() -> void:
	_economy.fail_supply_save = true
	assert_false(_reserve())
	assert_true(_core.box_status("box-1").is_empty())
	assert_false(_authorize())
	assert_false(_core.deliver("box-1"))


func test_failed_authorization_stays_reserved_after_reload() -> void:
	assert_true(_reserve())
	_economy.fail_supply_save = true
	assert_false(_authorize())
	assert_eq(_core.box_status("box-1")["state"], "reserved")
	assert_true(_reload().recover_authorized().is_empty())


func test_authorized_restart_recovers_once() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	var reloaded: SupplyBoxCore = _reload()
	assert_eq(reloaded.recover_authorized(), ["box-1"])
	assert_true(reloaded.recover_authorized().is_empty())
	assert_eq(SaveStore.load_from(PATH).currency, 17)


func test_delivered_restart_cannot_deliver_again() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	assert_true(_core.deliver("box-1"))
	var reloaded: SupplyBoxCore = _reload()
	assert_false(reloaded.deliver("box-1"))
	assert_true(reloaded.recover_authorized().is_empty())
	assert_eq(SaveStore.load_from(PATH).currency, 17)


func test_unknown_duplicate_and_wrong_context_rejected() -> void:
	assert_false(_core.deliver("stale-box"))
	assert_false(_authorize("stale-box"))
	assert_true(_reserve())
	assert_false(_reserve())
	assert_false(_core._authorize("box-1", "wrong_source", "fixture_context"))
	assert_false(_core._authorize("box-1", "fixture_source", "stale_context"))
	assert_eq(_economy.balance(), 0)
	assert_eq(_core.box_status("box-1")["state"], "reserved")


func test_unknown_and_malformed_rewards_fail_closed_without_freeing_id() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	var valid: Dictionary = _economy._data.supply_boxes["box-1"].duplicate(true)
	for value: Variant in ["unknown_reward", "", 7, null]:
		_economy._data.supply_boxes["box-1"] = valid.duplicate(true)
		_economy._data.supply_boxes["box-1"]["reward_type"] = value
		assert_false(_core.deliver("box-1"))
		assert_false(_reserve())
	for amount: Variant in [0, -1, 1.5, "17", null, INF]:
		_economy._data.supply_boxes["box-1"] = valid.duplicate(true)
		_economy._data.supply_boxes["box-1"]["amount"] = amount
		assert_false(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 0)


func test_corrupt_record_reload_preserves_dedupe_identity() -> void:
	_economy._data.supply_boxes["bad"] = {"state": "delivered", "amount": -3}
	assert_true(SaveStore.save_to(PATH, _economy._data))
	var reloaded: SupplyBoxCore = _reload()
	assert_true(reloaded.box_status("bad").is_empty())
	assert_false(reloaded.reserve("bad", "source", "context", _table))
	assert_true(reloaded.recover_authorized().is_empty())


func test_invalid_record_states_identity_and_version_rejected() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	var valid: Dictionary = _economy._data.supply_boxes["box-1"].duplicate(true)
	for patch: Dictionary in [{"state": "unknown"}, {"box_id": "other"},
			{"table_version": 0}, {"table_version": "3"}, {"context": ""}, {"source": false}]:
		var record: Dictionary = valid.duplicate(true)
		record.merge(patch, true)
		_economy._data.supply_boxes["box-1"] = record
		assert_false(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 0)


func test_invalid_tables_cannot_reserve() -> void:
	for weight: float in [0.0, -1.0, INF, NAN]:
		_table.entries[0].weight = weight
		assert_false(_reserve())
	_table.entries[0].weight = 1.0
	_table.entries[0].reward_type = &"unapproved"
	assert_false(_reserve())
	_table.entries[0].reward_type = &"coins"
	_table.table_key = &" "
	assert_false(_reserve())
	assert_true(_core.box_status("box-1").is_empty())


func test_gameplay_and_global_rng_unchanged() -> void:
	var gameplay := RandomNumberGenerator.new()
	gameplay.seed = FIXTURE_SEED
	var state_before: int = gameplay.state
	var seed_before: int = SeedManager.daily_seed
	seed(FIXTURE_SEED)
	var expected_global: int = randi()
	seed(FIXTURE_SEED)
	assert_true(_reserve())
	assert_true(_authorize())
	assert_true(_core.deliver("box-1"))
	assert_eq(randi(), expected_global)
	assert_eq(gameplay.state, state_before)
	assert_eq(SeedManager.daily_seed, seed_before)


func test_production_rng_initialization_and_selection_leave_global_rng_unchanged() -> void:
	seed(FIXTURE_SEED)
	var expected: int = randi()
	seed(FIXTURE_SEED)
	var production_core: SupplyBoxCore = _economy.supply_boxes()
	assert_true(production_core.reserve("production-rng", "fixture_source", "fixture_context", _table))
	assert_eq(randi(), expected)


func test_recovery_skips_corrupt_authorized_reward_and_completes_valid_box() -> void:
	assert_true(_reserve("bad"))
	assert_true(_authorize("bad"))
	assert_true(_reserve("good"))
	assert_true(_authorize("good"))
	_economy._data.supply_boxes["bad"]["reward_type"] = "unknown"
	assert_true(SaveStore.save_to(PATH, _economy._data))
	assert_eq(_reload().recover_authorized(), ["good"])
	assert_eq(SaveStore.load_from(PATH).currency, 17)
	assert_eq(SaveStore.load_from(PATH).supply_boxes["bad"]["state"], "authorized")


func test_old_save_defaults_and_malformed_container() -> void:
	assert_true(SaveData.from_dict({"currency": 21}).supply_boxes.is_empty())
	assert_true(SaveData.from_dict({"supply_boxes": []}).supply_boxes.is_empty())
	var old: SaveData = SaveData.from_dict({"currency": 21})
	assert_true(SaveStore.save_to(PATH, old))
	assert_true(_reload().recover_authorized().is_empty())
	assert_eq(SaveStore.load_from(PATH).currency, 21)


func test_recovery_sorted_and_reserved_skipped() -> void:
	assert_true(_reserve("z"))
	assert_true(_authorize("z"))
	assert_true(_reserve("a"))
	assert_true(_authorize("a"))
	assert_true(_reserve("r"))
	assert_eq(_reload().recover_authorized(), ["a", "z"])
	assert_eq(SaveStore.load_from(PATH).currency, 34)
	assert_eq(SaveStore.load_from(PATH).supply_boxes["r"]["state"], "reserved")


func test_intervening_economy_mutation_is_not_overwritten() -> void:
	assert_true(_reserve())
	_economy.earn(5)
	assert_true(_authorize())
	_economy._data.add_boost(&"slow_start", 3)
	assert_true(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 22)
	assert_eq(SaveStore.load_from(PATH).boost_count(&"slow_start"), 3)


func test_reentrant_currency_callback_cannot_duplicate_delivery() -> void:
	assert_true(_reserve())
	assert_true(_authorize())
	_economy.currency_changed.connect(func(_balance: int) -> void:
		assert_false(_core.deliver("box-1")))
	assert_true(_core.deliver("box-1"))
	assert_eq(_economy.balance(), 17)
