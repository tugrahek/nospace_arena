class_name PurchaseProduct
extends RefCounted

## Store-neutral product metadata. No rewards, entitlements or live IDs are defined here.
enum Kind { CONSUMABLE, NON_CONSUMABLE }

var id: StringName
var kind: Kind
var price_label: String


## Creates metadata; the backend supplies its localized display price.
func _init(product_id: StringName = &"", product_kind: Kind = Kind.CONSUMABLE, price: String = "") -> void:
	id = product_id
	kind = product_kind
	price_label = price


## Returns independent metadata so callers cannot mutate the service catalog.
func copy() -> PurchaseProduct:
	return PurchaseProduct.new(id, kind, price_label)
