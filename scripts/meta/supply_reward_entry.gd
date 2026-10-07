class_name SupplyRewardEntry
extends Resource

## One weighted outcome; weights are relative, not approved production probabilities.
@export var reward_type: StringName = &""
@export var amount: int = 0
@export var weight: float = 0.0

const TYPES: Array[StringName] = [&"coins", &"slow_start", &"coin_bonus", &"extra_life"]
const MAX_AMOUNT: int = 2147483647  # Serialization-safe positive reward bound, not balance.


## Accepts only supported, positive integral reward amounts (JSON may decode floats).
static func valid_reward(type: Variant, count: Variant) -> bool:
	if not (type is String or type is StringName) or StringName(type) not in TYPES:
		return false
	if not (count is int or count is float):
		return false
	var value: float = float(count)
	return is_finite(value) and value > 0 and value <= MAX_AMOUNT and value == floor(value)


## Invalid entries invalidate the table instead of silently changing its distribution.
func is_valid() -> bool:
	return valid_reward(reward_type, amount) and is_finite(weight) and weight > 0.0
