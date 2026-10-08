class_name DailyRewardClaim
extends RefCounted

## Checked login bundle acceptance; the Day 10 gift uses the existing Supply lifecycle.
const CONFIG: SupplyAcquisitionConfig = preload("res://config/supply_box.tres")
const GIFT_SOURCE: String = "daily_reward_gift"


## Saves ordinary reward, daily claim and frozen AUTHORIZED gift in one canonical write.
static func claim(owner: Node) -> Dictionary:
	var today: int = SeedManager.today_epoch()
	var data: SaveData = owner._data
	var result: Dictionary = LoginStreak.evaluate(today, data.last_claim_epoch_day, data.streak_day, owner.LOGIN_REWARDS)
	if not result["claimable"]:
		return {}
	var day: int = int(result["new_streak"])
	var spec: Dictionary = owner.login_reward_spec(day)
	var next: SaveData = SaveData.from_dict(data.to_dict())
	next.earn(int(spec["coins"]))
	for id: Variant in spec["boost_ids"]:
		next.add_boost(StringName(id), 1)
	next.last_claim_epoch_day = today
	next.streak_day = day
	var gift_id: String = ""
	if spec.get("supply_box", false):
		gift_id = "supply/daily_gift/%d" % today
		var cycle: int = today - day + 1
		var record: Dictionary = owner.supply_boxes()._prepare_reservation(gift_id, GIFT_SOURCE,
			"daily/%d/%d" % [cycle, today], CONFIG.reward_table)
		if record.is_empty():
			return {}
		record["state"] = SupplyBoxCore.AUTHORIZED
		record["acquisition_day"] = today
		record["daily_cycle_start"] = cycle
		next.supply_boxes[gift_id] = record
	if not owner._commit_supply_data(next):
		return {}
	owner.login_reward_claimed.emit(day, spec["coins"])
	if not gift_id.is_empty():
		spec["gift_box_id"] = gift_id
		owner.supply_boxes().deliver(gift_id)
		spec["gift_delivered"] = owner.supply_boxes().box_status(gift_id).get("state") == SupplyBoxCore.DELIVERED
	return spec
