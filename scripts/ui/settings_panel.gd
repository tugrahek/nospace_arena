extends Control

## Audio settings panel: master/sfx/music sliders + a single master-mute toggle. Backed by
## AudioManager (which owns AudioSettings + SettingsStore). Live-applies while dragging and
## persists once on drag end (debounced). Mute is a single event -> applied + saved at once.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"

@onready var _title: Label = $Center/Title
@onready var _master: HSlider = $Center/Rows/MasterRow/Slider
@onready var _sfx: HSlider = $Center/Rows/SfxRow/Slider
@onready var _music: HSlider = $Center/Rows/MusicRow/Slider
@onready var _master_label: Label = $Center/Rows/MasterRow/NameLabel
@onready var _sfx_label: Label = $Center/Rows/SfxRow/NameLabel
@onready var _music_label: Label = $Center/Rows/MusicRow/NameLabel
@onready var _mute: CheckButton = $Center/MuteToggle
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_title.text = tr("SETTINGS_TITLE")
	_master_label.text = tr("SETTINGS_MASTER")
	_sfx_label.text = tr("SETTINGS_SFX")
	_music_label.text = tr("SETTINGS_MUSIC")
	_mute.text = tr("SETTINGS_MUTE")
	_back.text = tr("SETTINGS_BACK")
	# Fill controls from the persisted settings (round-trip).
	var s: AudioSettings = AudioManager.settings()
	_master.value = s.master
	_sfx.value = s.sfx
	_music.value = s.music
	_mute.button_pressed = s.muted
	# Live-apply on change; persist once on drag end (debounced).
	_master.value_changed.connect(func(v: float) -> void: AudioManager.apply_master(v))
	_sfx.value_changed.connect(func(v: float) -> void: AudioManager.apply_sfx(v))
	_music.value_changed.connect(func(v: float) -> void: AudioManager.apply_music(v))
	_master.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_sfx.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_music.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_mute.toggled.connect(func(on: bool) -> void: AudioManager.set_muted(on))
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
