class_name PurchaseCatalog
extends RefCounted

## Empty by default. Validates and snapshots backend metadata without defining products.
var _products: Dictionary = {}


## Replaces the complete catalog only if every entry is valid and unique.
func replace(products: Array) -> bool:
	var next: Dictionary = {}
	for entry in products:
		if not entry is PurchaseProduct or entry.id == &"" or next.has(entry.id):
			return false
		if entry.kind not in [PurchaseProduct.Kind.CONSUMABLE, PurchaseProduct.Kind.NON_CONSUMABLE]:
			return false
		next[entry.id] = entry.copy()
	_products = next
	return true


## Returns detached metadata, or null for an unknown product.
func find(id: StringName) -> PurchaseProduct:
	return _products[id].copy() if _products.has(id) else null


## Returns independent metadata in backend order.
func all() -> Array[PurchaseProduct]:
	var result: Array[PurchaseProduct] = []
	for product in _products.values():
		result.append(product.copy())
	return result
