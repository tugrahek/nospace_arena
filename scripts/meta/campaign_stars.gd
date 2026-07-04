class_name CampaignStars
extends RefCounted

## Pure Campaign scoring + unlock logic (no nodes, no IO, no RNG) -> GUT-testable.
## Stars: clearing the level = 1; +1 for meeting the score threshold; +1 for flawless (no life
## lost). Unlock is derived from progress: a level opens once the previous one has at least one
## star (the first level is always open).

## Stars (0..3) for a level attempt. 0 if the target wasn't reached (level failed). Otherwise:
## 1 = cleared; +1 if the score threshold is met; +1 if flawless (no life lost). So 2 stars = one
## of {score, flawless}, 3 stars = BOTH. (Percent isn't used: the run ends at the target %, so a
## higher-percent star would be unreachable -- score + no-death are the reachable skill metrics.)
static func star_for(reached_target: bool, score: int, lives_lost: int, level: LevelData) -> int:
	if not reached_target:
		return 0
	var stars: int = 1
	if level.star2_score > 0 and score >= level.star2_score:
		stars += 1
	if lives_lost <= 0:
		stars += 1
	return mini(stars, 3)


## Whether the level at `index` is unlocked, given the ordered `levels` and a { id -> stars } map.
static func is_unlocked(index: int, levels: Array, stars: Dictionary) -> bool:
	if index <= 0:
		return true  # the first level is always open
	if index >= levels.size():
		return false
	var prev: LevelData = levels[index - 1]
	return int(stars.get(String(prev.id), 0)) >= 1
