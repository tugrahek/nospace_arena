class_name PurchaseProduct
extends RefCounted

## Store-neutral product metadata. No rewards, entitlements or live IDs are defined here.
enum Kind { CONSUMABLE, NON_CONSUMABLE }

var id: StringName
var kind: Kind
var price_label: String
var title: String = ""
var description: String = ""
var currency_code: String = ""
var price_amount_micros: int = 0


## Creates metadata; the backend supplies its localized display price.
func _init(product_id: StringName = &"", product_kind: Kind = Kind.CONSUMABLE, price: String = "") -> void:
	id = product_id
	kind = product_kind
	price_label = price


## Returns independent metadata so callers cannot mutate the service catalog.
func copy() -> PurchaseProduct:
	var result: PurchaseProduct = PurchaseProduct.new(id, kind, price_label)
	result.title = title
	result.description = description
	result.currency_code = currency_code
	result.price_amount_micros = price_amount_micros
	return result
