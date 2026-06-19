class_name SoundBank
extends Resource

## Maps logical event keys to AudioStreams. Streams are assigned in config/sound_bank.tres.
## Left empty in 17a (no license-clean assets yet) -> lookups return null -> AudioManager
## plays nothing (silent no-op). 17b drops CC0 .ogg files in assets/audio/ and assigns them.

@export var capture: AudioStream
@export var life_loss: AudioStream
@export var near_miss: AudioStream
@export var ui_tap: AudioStream
@export var music_menu: AudioStream
@export var music_game: AudioStream


## SFX stream for an event key, or null if unknown/unassigned.
func sfx(key: String) -> AudioStream:
	match key:
		"capture":
			return capture
		"life_loss":
			return life_loss
		"near_miss":
			return near_miss
		"ui_tap":
			return ui_tap
	return null


## Music stream for a track key, or null if unknown/unassigned.
func music(key: String) -> AudioStream:
	match key:
		"menu":
			return music_menu
		"game":
			return music_game
	return null
