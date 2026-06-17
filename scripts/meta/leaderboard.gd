class_name Leaderboard
extends RefCounted

## Per-day best score + ghost track, keyed by daily seed (date int). Scores are kept
## for every day (tiny); ghost tracks are pruned to the most recent days on save so
## storage stays bounded. Pure (logic + serialization), GUT-testable.

const GhostTrackScript = preload("res://scripts/meta/ghost_track.gd")

var _entries: Dictionary = {}  # int date -> { "score": int, "track": GhostTrack }


## Records a run. New best only if strictly greater (ties don't replace). Returns true
## if this became the new best for that date.
func submit(date: int, score: int, track: GhostTrackScript) -> bool:
	if _entries.has(date) and score <= _entries[date]["score"]:
		return false
	_entries[date] = {"score": score, "track": track}
	return true


func best_score(date: int) -> int:
	return _entries[date]["score"] if _entries.has(date) else -1


func best_track(date: int) -> GhostTrackScript:
	return _entries[date]["track"] if _entries.has(date) else null


## Keeps full ghost tracks only for the `keep_recent` highest dates; older entries keep
## their score but drop the track (empty). Bounds storage growth.
func prune_tracks(keep_recent: int) -> void:
	var dates: Array = _entries.keys()
	dates.sort()  # ascending; newest at the end
	var cutoff: int = dates.size() - keep_recent
	for i in dates.size():
		if i < cutoff:
			_entries[dates[i]]["track"] = GhostTrackScript.new()


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for date in _entries:
		out[str(date)] = {
			"score": _entries[date]["score"],
			"track": _entries[date]["track"].to_array(),
		}
	return out


static func from_dict(d: Dictionary) -> Leaderboard:
	var lb := Leaderboard.new()
	for key in d:
		var entry: Dictionary = d[key]
		lb._entries[int(key)] = {
			"score": int(entry["score"]),
			"track": GhostTrackScript.from_array(entry["track"]),
		}
	return lb
