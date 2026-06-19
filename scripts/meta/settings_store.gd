class_name SettingsStore
extends RefCounted

## Thin JSON persistence for audio settings (user://settings.json). Missing/corrupt files
## load as fresh defaults (safe — never crashes). IO is impure; the serialization it relies
## on is pure (AudioSettings.to_dict/from_dict, GUT-tested).

const AudioSettingsScript = preload("res://scripts/meta/audio_settings.gd")


static func load_from(path: String) -> AudioSettingsScript:
	if not FileAccess.file_exists(path):
		return AudioSettingsScript.new()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return AudioSettingsScript.new()
	var text: String = f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return AudioSettingsScript.new()  # corrupt -> safe default
	return AudioSettingsScript.from_dict(data)


static func save_to(path: String, settings: AudioSettingsScript) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(settings.to_dict()))
	f.close()
