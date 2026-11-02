class_name CoinPackDefinition
extends Resource

## Authored v1 consumable contract, never a trusted receipt or wallet-credit command.
## Real-money display prices belong exclusively to live Play product metadata.
@export var sku: StringName = &""
@export var coin_amount: int = 0
@export var kind: PurchaseProduct.Kind = PurchaseProduct.Kind.CONSUMABLE


## Validates the exact approved v1 identifier/amount pair and consumable type.
func is_valid() -> bool:
	return kind == PurchaseProduct.Kind.CONSUMABLE and coin_amount > 0 and coin_amount == expected_coins(sku)


## Returns the stable contract amount, or zero for an unknown/unapproved SKU.
static func expected_coins(product_id: StringName) -> int:
	match product_id:
		&"coins_500":
			return 500
		&"coins_1500":
			return 1500
		&"coins_4000":
			return 4000
	return 0
