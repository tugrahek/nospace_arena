class_name CampaignStars
extends RefCounted

## Pure Campaign scoring + unlock logic (no nodes, no IO, no RNG) -> GUT-testable.
## Stars are earned by count: clearing the level = 1, plus one for each optional threshold met
## (score, capture %). Unlock is derived from progress: a level opens once the previous one has
## at least one star (the first level is always open).

## Stars (0..3) for a level attempt. 0 if the target wasn't reached (level failed).
static func star_for(reached_target: bool, score: int, percent: float, level: LevelData) -> int:
	if not reached_target:
		return 0
	var stars: int = 1
	if level.star2_score > 0 and score >= level.star2_score:
		stars += 1
	if level.star3_percent > 0.0 and percent >= level.star3_percent:
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
