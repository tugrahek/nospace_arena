class_name ChaserPolicy
extends RefCounted

## Single source of truth for the adaptive chaser: does the Stalker hunt the NEAREST threat point
## (head or active trail) instead of just the player's head? On only where the difficulty curve
## calls for it — late Campaign levels and late Level-Endless stages. Free stays predictable and
## Daily stays off entirely (leaderboard fairness + ghost determinism). Pure, no RNG.
##
## The flag is resolved ONCE per stage/level and passed down per frame — it is never written onto
## the shared ChaserBehavior/EnemyType resources, which would leak across runs.

## `campaign_flag` = LevelData.chaser_hunts_nearest, `stage` = 0-based Level-Endless stage index,
## `endless_from_stage` = ProgressionConfig threshold (negative disables it entirely).
static func hunts_nearest(mode: int, campaign_flag: bool, stage: int, endless_from_stage: int) -> bool:
	if mode == SeedManager.Mode.CAMPAIGN:
		return campaign_flag
	if mode == SeedManager.Mode.LEVEL_ENDLESS:
		return endless_from_stage >= 0 and stage >= endless_from_stage
	return false  # Free, Daily and anything unknown: always the classic head-hunt
