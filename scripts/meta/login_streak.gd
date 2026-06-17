class_name LoginStreak
extends RefCounted

## Pure daily-login streak logic. Given today's epoch-day, the last claim's epoch-day,
## the current streak, and the reward table, decides whether a reward is claimable and
## what the new streak is. No IO/RNG -> GUT-testable. Idempotency (no double claim) comes
## from "already claimed today" returning claimable=false.


## Returns { claimable: bool, reward: int, new_streak: int }.
## first ever (last < 0) -> streak 1; same day -> not claimable; consecutive -> streak+1
## (loops 7->1); missed (gap > 1, or clock back) -> streak resets to 1.
static func evaluate(today_epoch: int, last_epoch: int, streak: int, table: Array) -> Dictionary:
	var n: int = table.size()
	if last_epoch < 0:
		return {"claimable": true, "reward": int(table[0]), "new_streak": 1}
	if today_epoch == last_epoch:
		return {"claimable": false, "reward": 0, "new_streak": streak}
	var new_streak: int
	if today_epoch == last_epoch + 1:
		new_streak = streak + 1
		if new_streak > n:
			new_streak = 1  # loop back to day 1
	else:
		new_streak = 1  # missed a day (or clock moved back)
	new_streak = clampi(new_streak, 1, n)
	return {"claimable": true, "reward": int(table[new_streak - 1]), "new_streak": new_streak}
