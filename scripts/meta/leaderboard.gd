class_name Leaderboard
extends RefCounted

## Per-day best score, keyed by daily seed (date int). Historical scores are kept
## for every day. Pure logic and serialization; legacy extra fields are ignored.

var _entries: Dictionary = {}  # int date -> { "score": int }


## Records a run. New best only if strictly greater (ties don't replace). Returns true
## if this became the new best for that date.
func submit(date: int, score: int) -> bool:
	if _entries.has(date) and score <= _entries[date]["score"]:
		return false
	_entries[date] = {"score": score}
	return true


func best_score(date: int) -> int:
	return _entries[date]["score"] if _entries.has(date) else -1


## All recorded best scores as date(int) -> score(int) (no tracks). For the leaderboard view.
func scores() -> Dictionary:
	var out: Dictionary = {}
	for date in _entries:
		out[date] = int(_entries[date]["score"])
	return out


## Highest score across all days, or -1 if no entries. ("All-time best".)
func best_ever() -> int:
	var best: int = -1
	for date in _entries:
		best = maxi(best, int(_entries[date]["score"]))
	return best


## Serializes scores only; legacy position samples are never written back.
func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for date in _entries:
		out[str(date)] = {
			"score": _entries[date]["score"],
		}
	return out


## Loads historical scores from both old and current saves, ignoring extra fields.
static func from_dict(d: Dictionary) -> Leaderboard:
	var lb := Leaderboard.new()
	for key in d:
		var entry: Dictionary = d[key]
		lb._entries[int(key)] = {
			"score": int(entry["score"]),
		}
	return lb
