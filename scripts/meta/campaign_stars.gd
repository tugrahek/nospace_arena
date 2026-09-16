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


## The campaign frontier: highest unlocked level index (0 with no progress; -1 for no levels).
static func frontier(levels: Array, stars: Dictionary) -> int:
	var best: int = -1
	for i in levels.size():
		if is_unlocked(i, levels, stars):
			best = i
	return best


## Index of the level that recording `new_stars` for `id` would NEWLY unlock (the frontier grows),
## else -1. Keeps-best semantics like SaveData: a star improvement or a replay of an already-open
## level never counts. Pure: `stars` is not modified. Drives the level-map unlock celebration.
static func newly_unlocked(levels: Array, stars: Dictionary, id: StringName, new_stars: int) -> int:
	var before: int = frontier(levels, stars)
	var after_stars: Dictionary = stars.duplicate()
	after_stars[String(id)] = maxi(int(stars.get(String(id), 0)), clampi(new_stars, 0, 3))
	var after: int = frontier(levels, after_stars)
	return after if after > before else -1
