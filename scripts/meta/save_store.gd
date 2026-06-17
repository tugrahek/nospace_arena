class_name SaveStore
extends RefCounted

## Thin JSON persistence for the player profile (user://save.json). Missing/corrupt
## files load as a fresh default profile (safe — never crashes). IO is impure; the
## serialization it relies on is pure (SaveData.to_dict/from_dict, GUT-tested).

const SaveDataScript = preload("res://scripts/meta/save_data.gd")


static func load_from(path: String) -> SaveDataScript:
	if not FileAccess.file_exists(path):
		return SaveDataScript.new_default()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return SaveDataScript.new_default()
	var text: String = f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return SaveDataScript.new_default()  # corrupt -> safe default
	return SaveDataScript.from_dict(data)


static func save_to(path: String, data: SaveDataScript) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data.to_dict()))
	f.close()
