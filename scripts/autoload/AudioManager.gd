extends Node

## Central audio: SFX playback (round-robin player pool), music control, and bus volume/mute
## driven by persisted AudioSettings. Plays through the SoundBank — unassigned keys are a
## silent no-op (no crash), so the system works fully before any audio asset is added (17b).
## Settings load + apply in _ready, BEFORE any scene can request a sound.

const SETTINGS_PATH: String = "user://settings.json"
const SOUND_BANK: SoundBank = preload("res://config/sound_bank.tres")

@export var sfx_pool_size: int = 3        # concurrent SFX voices (overlapping sounds)
@export var capture_haptic_ms: int = 12   # light haptic on capture (mobile)
@export var life_loss_haptic_ms: int = 30 # heavier haptic on life loss
@export var music_volume_db: float = -6.0 # music sits below SFX (first-pass mix; tune in editor)

var _settings: AudioSettings
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _music: AudioStreamPlayer


func _ready() -> void:
	_settings = SettingsStore.load_from(SETTINGS_PATH)
	for i in maxi(sfx_pool_size, 1):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = music_volume_db  # background level vs SFX (first-pass mix)
	add_child(_music)
	_apply_settings()  # apply before anything plays


## Plays a one-shot SFX by event key (round-robin voices). Unknown/unassigned key -> no-op.
func play_sfx(key: String) -> void:
	var stream: AudioStream = SOUND_BANK.sfx(key)
	if stream == null or _sfx_players.is_empty():
		return
	var p: AudioStreamPlayer = _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = stream
	p.play()


## Plays a music track by key (idempotent: re-requesting the playing track is a no-op).
## Unknown/unassigned key -> no-op. (Smooth crossfade is deferred to 17b.)
func play_music(key: String) -> void:
	var stream: AudioStream = SOUND_BANK.music(key)
	if stream == null:
		return
	# Guarantee music loops: the WAV import loop flag isn't reliably applied headless/exported,
	# so enforce it here (SFX stay one-shot — only music is forced to loop).
	if stream is AudioStreamWAV and (stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()


## Light haptic helpers (mobile). Gameplay events call these; UI haptic lives in JuicyButton.
func haptic_capture() -> void:
	if capture_haptic_ms > 0:
		Input.vibrate_handheld(capture_haptic_ms)


func haptic_life_loss() -> void:
	if life_loss_haptic_ms > 0:
		Input.vibrate_handheld(life_loss_haptic_ms)


# --- Settings (used by the 17b settings UI; persisted immediately) ---

func settings() -> AudioSettings:
	return _settings


# Live-apply setters (no save) — used while dragging a slider. Call commit_settings() once
# on drag end to persist (debounced write).
func apply_master(v: float) -> void:
	_settings.set_master(v)
	_apply_settings()


func apply_sfx(v: float) -> void:
	_settings.set_sfx(v)
	_apply_settings()


func apply_music(v: float) -> void:
	_settings.set_music(v)
	_apply_settings()


## Mute is a single discrete event -> apply and persist immediately.
func set_muted(v: bool) -> void:
	_settings.set_muted(v)
	_apply_settings()
	_save()


## Persists the current settings (call on slider drag end).
func commit_settings() -> void:
	_save()


func _apply_settings() -> void:
	_set_bus_volume("Master", _settings.master)
	_set_bus_volume("SFX", _settings.sfx)
	_set_bus_volume("Music", _settings.music)
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, _settings.muted)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, AudioSettings.to_db(linear))


func _save() -> void:
	SettingsStore.save_to(SETTINGS_PATH, _settings)
