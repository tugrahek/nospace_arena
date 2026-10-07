class_name SupplyAcquisitionConfig
extends Resource

## Approved balance data; no acquisition policy constants are embedded in gameplay.
@export var reward_table: SupplyRewardTable
@export var coin_cost: int = 0
@export var coin_daily_limit: int = 0
@export var rewarded_daily_limit: int = 0


## Refuses broken configuration instead of offering free or unlimited acquisitions.
func is_valid() -> bool:
	return reward_table != null and not reward_table.select_reward(0.0).is_empty() \
		and coin_cost > 0 and coin_daily_limit >= 0 and rewarded_daily_limit >= 0
