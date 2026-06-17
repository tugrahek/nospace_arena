class_name LeaderboardStore
extends RefCounted

## Thin JSON persistence for the local leaderboard (user://). Corrupt/missing files
## load as an empty leaderboard (safe). Prunes ghost tracks before saving so the file
## doesn't grow without bound. IO is impure; the serialization it relies on is pure
## (Leaderboard.to_dict/from_dict, GUT-tested). Step 12's unified save may absorb this.

const LeaderboardScript = preload("res://scripts/meta/leaderboard.gd")
const KEEP_TRACK_DAYS: int = 5


static func load_from(path: String) -> LeaderboardScript:
	if not FileAccess.file_exists(path):
		return LeaderboardScript.new()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return LeaderboardScript.new()
	var text: String = f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return LeaderboardScript.new()  # corrupt -> empty, never crash
	return LeaderboardScript.from_dict(data)


static func save_to(path: String, leaderboard: LeaderboardScript) -> void:
	leaderboard.prune_tracks(KEEP_TRACK_DAYS)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(leaderboard.to_dict()))
	f.close()
