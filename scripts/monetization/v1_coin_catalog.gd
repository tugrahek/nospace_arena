class_name V1CoinCatalog
extends RefCounted

## Planned definitions only. Never installs products in PurchaseService/native Billing.
const Definition = preload("res://scripts/monetization/coin_pack_definition.gd")
const PACKS: Array[Resource] = [
	preload("res://resources/purchases/coins_500.tres"),
	preload("res://resources/purchases/coins_1500.tres"),
	preload("res://resources/purchases/coins_4000.tres"),
]
const PRODUCT_COUNT: int = 3


## Returns detached valid definitions, or no definitions if authored data is invalid.
static func all() -> Array[CoinPackDefinition]:
	var result: Array[CoinPackDefinition] = []
	if not validate(PACKS):
		return result
	for pack: CoinPackDefinition in PACKS:
		result.append(pack.duplicate() as CoinPackDefinition)
	return result


## Requires the complete unique allowlist, rejecting partial, malformed or mixed data.
static func validate(definitions: Array) -> bool:
	if definitions.size() != PRODUCT_COUNT:
		return false
	var seen: Dictionary = {}
	for definition: Variant in definitions:
		if not definition is Definition or not definition.is_valid() or seen.has(definition.sku):
			return false
		seen[definition.sku] = true
	return true
