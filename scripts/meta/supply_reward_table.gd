class_name SupplyRewardTable
extends Resource

## Versioned, data-driven outcomes. No live table or approved balance is supplied here.
@export var table_key: StringName = &""
@export var version: int = 1
@export var entries: Array[SupplyRewardEntry] = []


## Maps an injected unit roll [0, 1) to an outcome, without accessing any RNG.
func select_reward(unit_roll: float) -> Dictionary:
	if String(table_key).strip_edges().is_empty() \
			or not SupplyRewardEntry.valid_reward(&"coins", version) or entries.is_empty() \
			or not is_finite(unit_roll) or unit_roll < 0 or unit_roll >= 1:
		return {}
	var total: float = 0.0
	for entry: SupplyRewardEntry in entries:
		if entry == null or not entry.is_valid():
			return {}
		total += entry.weight
	if not is_finite(total) or total <= 0:
		return {}
	var cursor: float = unit_roll * total
	for entry: SupplyRewardEntry in entries:
		cursor -= entry.weight
		if cursor < 0:
			return {"reward_type": String(entry.reward_type), "amount": entry.amount}
	# Floating point rounding at the last boundary still selects the final valid entry.
	var last: SupplyRewardEntry = entries.back()
	return {"reward_type": String(last.reward_type), "amount": last.amount}
