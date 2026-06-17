class_name MissionStore
extends RefCounted

## Thin JSON persistence for today's mission progress (user://missions.json).
## Stores { "date": int, "progress": { id -> {progress, claimed} } }. Loading for a
## different date returns empty (missions refreshed daily). Missing/corrupt -> empty
## (safe). Only the active day is kept (overwrite prunes old). Pure serialization, ince IO.


static func load_progress(path: String, date: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	if int(data.get("date", -1)) != date:
		return {}  # new day -> fresh missions
	var p: Variant = data.get("progress", {})
	return p if typeof(p) == TYPE_DICTIONARY else {}


static func save_progress(path: String, date: int, progress: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"date": date, "progress": progress}))
	f.close()
