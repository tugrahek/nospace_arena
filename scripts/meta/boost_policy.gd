class_name BoostPolicy
extends RefCounted

## Single source of truth for whether boosts apply in a play mode. Daily is OFF (leaderboard
## fairness + ghost determinism); Free / Level-Endless are ON. Campaign defers to the level's own
## `boosts_allowed` flag (passed as `campaign_allows`). Unknown modes default ON. Pure.

static func boosts_allowed(mode: int, campaign_allows: bool = true) -> bool:
	if mode == SeedManager.Mode.DAILY:
		return false
	if mode == SeedManager.Mode.CAMPAIGN:
		return campaign_allows
	return true
