class_name BoostPolicy
extends RefCounted

## Single source of truth for whether boosts apply in a play mode. Daily is OFF (leaderboard
## fairness + ghost determinism); Free / Level-Endless are ON. Unknown/future modes (e.g. Campaign
## in Step 21) default ON — the hook is ready; the per-level flag will refine it later. Pure.

static func boosts_allowed(mode: int) -> bool:
	return mode != SeedManager.Mode.DAILY
