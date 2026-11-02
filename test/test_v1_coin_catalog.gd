extends GutTest

const Definition = preload("res://scripts/monetization/coin_pack_definition.gd")
const Catalog = preload("res://scripts/monetization/v1_coin_catalog.gd")


func test_stable_exact_consumable_skus_and_amounts() -> void:
	var definitions: Array[CoinPackDefinition] = Catalog.all()
	assert_eq(definitions.size(), 3)
	var expected: Dictionary = {&"coins_500": 500, &"coins_1500": 1500, &"coins_4000": 4000}
	for definition: CoinPackDefinition in definitions:
		assert_true(definition.is_valid())
		assert_true(expected.has(definition.sku))
		assert_eq(definition.coin_amount, expected[definition.sku])
		assert_eq(definition.kind, PurchaseProduct.Kind.CONSUMABLE)
		expected.erase(definition.sku)
	assert_true(expected.is_empty())


func test_rejects_unknown_empty_and_wrong_case_identifiers() -> void:
	for id: StringName in [&"", &"coins_0500", &"COINS_500", &"coins_9999", &"coins_500 "]:
		var definition: CoinPackDefinition = Definition.new()
		definition.sku = id
		definition.coin_amount = 500
		assert_false(definition.is_valid(), str(id))
		assert_eq(Definition.expected_coins(id), 0)


func test_rejects_mismatched_zero_negative_and_non_consumable_rewards() -> void:
	var definition: CoinPackDefinition = Definition.new()
	definition.sku = &"coins_500"
	for amount: int in [0, -500, 1, 1500, 4000]:
		definition.coin_amount = amount
		assert_false(definition.is_valid())
	definition.coin_amount = 500
	definition.kind = PurchaseProduct.Kind.NON_CONSUMABLE
	assert_false(definition.is_valid())


func test_rejects_missing_duplicate_null_and_untyped_catalog_entries() -> void:
	assert_false(Catalog.validate([]))
	var definitions: Array[CoinPackDefinition] = Catalog.all()
	assert_false(Catalog.validate([definitions[0], definitions[1]]))
	assert_false(Catalog.validate([definitions[0], definitions[0], definitions[2]]))
	assert_false(Catalog.validate([definitions[0], null, definitions[2]]))
	assert_false(Catalog.validate([definitions[0], {"sku": "coins_1500", "coin_amount": 1500}, definitions[2]]))


func test_returns_detached_definitions_and_revalidates_mutated_input() -> void:
	var definitions: Array[CoinPackDefinition] = Catalog.all()
	definitions[0].coin_amount = 4000
	assert_false(Catalog.validate(definitions))
	assert_true(Catalog.validate(Catalog.all()))
	assert_eq(Catalog.all()[0].coin_amount, 500)


func test_definitions_have_no_hardcoded_real_money_prices() -> void:
	for definition: CoinPackDefinition in Catalog.all():
		for property: Dictionary in definition.get_property_list():
			assert_false(str(property.name) in ["price", "price_label", "currency_code", "price_amount_micros"])


func test_autoload_purchases_stay_disabled_and_catalog_is_not_installed() -> void:
	assert_false(PurchaseService.REAL_PURCHASES_ENABLED)
	assert_false(PurchaseService.is_available())
	assert_true(PurchaseService.products().is_empty())
	for definition: CoinPackDefinition in Catalog.all():
		assert_eq(PurchaseService.purchase(definition.sku), 0)
