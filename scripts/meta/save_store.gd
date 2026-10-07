class_name SaveStore
extends RefCounted

## Checked profile persistence. A completed temp file replaces canonical only after
## preserving its valid predecessor. Recovery prefers canonical, then backup, then temp.

const SaveDataScript = preload("res://scripts/meta/save_data.gd")
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"


## Loads canonical first; otherwise restores backup before temp, or returns existing defaults.
static func load_from(path: String) -> SaveDataScript:
	var data: Variant = _read_candidate(path)
	if data == null:
		data = _recover(path)
	return SaveDataScript.new_default() if data == null else SaveDataScript.from_dict(data)


## Returns true only after the flushed, closed and verified temp becomes canonical.
## Failed writes/replacements retain a valid canonical or recovery candidate.
static func save_to(path: String, data: SaveDataScript) -> bool:
	# Recover before reusing temp: it may be the only surviving valid profile.
	if _read_candidate(path) == null:
		var recovered: Variant = _recover(path)
		if recovered != null and _read_candidate(path) == null:
			return false
	var temp_path: String = path + TEMP_SUFFIX
	var backup_path: String = path + BACKUP_SUFFIX
	if not _write_temp(temp_path, JSON.stringify(data.to_dict())):
		return false
	if _read_candidate(path) != null:
		if not _remove_file(backup_path) or not _move_file(path, backup_path):
			return false
	elif not _remove_file(path):
		return false
	return _move_file(temp_path, path)


static func _write_temp(path: String, text: String) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	var success: bool = f.get_error() == OK
	f.close()
	# Read back after close so truncated or incomplete output never replaces canonical.
	return success and FileAccess.get_file_as_string(path) == text and _read_candidate(path) != null


static func _read_candidate(path: String) -> Variant:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return null
	return json.data


static func _recover(path: String) -> Variant:
	for suffix: String in [BACKUP_SUFFIX, TEMP_SUFFIX]:
		var candidate_path: String = path + suffix
		var data: Variant = _read_candidate(candidate_path)
		if data == null:
			continue
		# Never rotate an invalid canonical over the valid recovery copy.
		if _remove_file(path):
			_move_file(candidate_path, path)
		# Loading can still use the valid candidate if filesystem permissions block promotion.
		return data
	return null


static func _remove_file(path: String) -> bool:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute_path):
		return false  # A path collision is a checked failure, never a directory deletion.
	return not FileAccess.file_exists(path) or DirAccess.remove_absolute(absolute_path) == OK


static func _move_file(from: String, to: String) -> bool:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from),
		ProjectSettings.globalize_path(to)) == OK
