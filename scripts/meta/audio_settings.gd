class_name AudioSettings
extends RefCounted

## Persistent audio settings: per-channel linear volumes [0,1] + a global mute. Pure logic +
## serialization (no IO) -> GUT-testable. SettingsStore handles the file; AudioManager applies
## these to the audio buses (linear -> dB).

const SILENCE_DB: float = -80.0  # volume 0 maps here (effectively silent)
const SCHEME_MIN: int = 0
const SCHEME_MAX: int = 2  # 0 = tap-turn, 1 = swipe, 2 = d-pad (mirrors Player.SchemeId)

var master: float = 1.0
var sfx: float = 1.0
var music: float = 1.0
var muted: bool = false
var control_scheme: int = 1  # swipe (default)


func set_master(v: float) -> void:
	master = clampf(v, 0.0, 1.0)


func set_sfx(v: float) -> void:
	sfx = clampf(v, 0.0, 1.0)


func set_music(v: float) -> void:
	music = clampf(v, 0.0, 1.0)


func set_muted(v: bool) -> void:
	muted = v


## Input control scheme (clamped to the valid SchemeId range).
func set_control_scheme(v: int) -> void:
	control_scheme = clampi(v, SCHEME_MIN, SCHEME_MAX)


## Converts a linear volume [0,1] to decibels for a bus; 0 -> SILENCE_DB (no -inf).
static func to_db(linear: float) -> float:
	var v: float = clampf(linear, 0.0, 1.0)
	if v <= 0.0:
		return SILENCE_DB
	return linear_to_db(v)


func to_dict() -> Dictionary:
	return {"master": master, "sfx": sfx, "music": music, "muted": muted, "control_scheme": control_scheme}


static func from_dict(d: Dictionary) -> AudioSettings:
	var s := AudioSettings.new()
	s.set_master(float(d.get("master", 1.0)))
	s.set_sfx(float(d.get("sfx", 1.0)))
	s.set_music(float(d.get("music", 1.0)))
	s.set_muted(bool(d.get("muted", false)))
	s.set_control_scheme(int(d.get("control_scheme", 1)))
	return s
