class_name Storefront
extends RefCounted

## Pure store-offer logic (no Economy/IO) — GUT-testable. The actual purchase
## (spend + unlock) is Economy.purchase; this decides whether to OFFER a buy.


## True if the item is buyable now: still locked AND affordable AND non-negative cost.
static func can_purchase(is_unlocked: bool, balance: int, cost: int) -> bool:
	return not is_unlocked and cost >= 0 and balance >= cost
