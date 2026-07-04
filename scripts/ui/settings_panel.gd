extends Control

## Audio settings panel: master/sfx/music sliders + a single master-mute toggle. Backed by
## AudioManager (which owns AudioSettings + SettingsStore). Live-applies while dragging and
## persists once on drag end (debounced). Mute is a single event -> applied + saved at once.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"

## When true the panel was opened as an overlay (e.g. from in-run Pause); Back closes it.
## When false (launched from MainMenu) Back returns to the main menu.
var embedded: bool = false

@onready var _title: Label = $Center/Title
@onready var _master: HSlider = $Center/Rows/MasterRow/Slider
@onready var _sfx: HSlider = $Center/Rows/SfxRow/Slider
@onready var _music: HSlider = $Center/Rows/MusicRow/Slider
@onready var _master_label: Label = $Center/Rows/MasterRow/NameLabel
@onready var _sfx_label: Label = $Center/Rows/SfxRow/NameLabel
@onready var _music_label: Label = $Center/Rows/MusicRow/NameLabel
@onready var _mute: CheckButton = $Center/MuteToggle
@onready var _controls_label: Label = $Center/ControlsRow/NameLabel
@onready var _swipe: Button = $Center/ControlsRow/Segment/SwipeButton
@onready var _tap: Button = $Center/ControlsRow/Segment/TapButton
@onready var _dpad: Button = $Center/ControlsRow/Segment/DpadButton
@onready var _language_label: Label = $Center/LanguageRow/NameLabel
@onready var _lang_auto: Button = $Center/LanguageRow/Segment/AutoButton
@onready var _lang_en: Button = $Center/LanguageRow/Segment/EnButton
@onready var _lang_tr: Button = $Center/LanguageRow/Segment/TrButton
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_apply_texts()
	# Fill controls from the persisted settings (round-trip).
	var s: AudioSettings = AudioManager.settings()
	_master.value = s.master
	_sfx.value = s.sfx
	_music.value = s.music
	_mute.button_pressed = s.muted
	# Controls segment: reflect saved scheme (SchemeId: 0=tap, 1=swipe, 2=dpad), save on press.
	_swipe.button_pressed = s.control_scheme == 1
	_tap.button_pressed = s.control_scheme == 0
	_dpad.button_pressed = s.control_scheme == 2
	_swipe.pressed.connect(func() -> void: AudioManager.set_control_scheme(1))
	_tap.pressed.connect(func() -> void: AudioManager.set_control_scheme(0))
	_dpad.pressed.connect(func() -> void: AudioManager.set_control_scheme(2))
	# Language segment: reflect the saved preference ("" = auto/device), apply+save on press.
	# The panel refreshes its own texts right away (other screens rebuild on scene entry).
	_lang_auto.button_pressed = s.language == ""
	_lang_en.button_pressed = s.language == "en"
	_lang_tr.button_pressed = s.language == "tr"
	_lang_auto.pressed.connect(_on_language.bind(""))
	_lang_en.pressed.connect(_on_language.bind("en"))
	_lang_tr.pressed.connect(_on_language.bind("tr"))
	# Live-apply on change; persist once on drag end (debounced).
	_master.value_changed.connect(func(v: float) -> void: AudioManager.apply_master(v))
	_sfx.value_changed.connect(func(v: float) -> void: AudioManager.apply_sfx(v))
	_music.value_changed.connect(func(v: float) -> void: AudioManager.apply_music(v))
	_master.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_sfx.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_music.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_mute.toggled.connect(func(on: bool) -> void: AudioManager.set_muted(on))
	_back.pressed.connect(_on_back)


## All panel texts from the ACTIVE locale — called on ready and again after a language switch
## so the panel itself updates in place. (Language names stay endonyms: English / Türkçe.)
func _apply_texts() -> void:
	_title.text = tr("SETTINGS_TITLE")
	_master_label.text = tr("SETTINGS_MASTER")
	_sfx_label.text = tr("SETTINGS_SFX")
	_music_label.text = tr("SETTINGS_MUSIC")
	_mute.text = tr("SETTINGS_MUTE")
	_controls_label.text = tr("SETTINGS_CONTROLS")
	_swipe.text = tr("CONTROL_SWIPE")
	_tap.text = tr("CONTROL_TAP")
	_dpad.text = tr("CONTROL_DPAD")
	_language_label.text = tr("SETTINGS_LANGUAGE")
	_lang_auto.text = tr("LANG_AUTO")
	_lang_en.text = tr("LANG_EN")
	_lang_tr.text = tr("LANG_TR")
	_back.text = tr("SETTINGS_BACK")


func _on_language(lang: String) -> void:
	AudioManager.set_language(lang)  # applies the locale + persists
	_apply_texts()  # this panel updates in place; other screens rebuild on scene entry


## Back: close the overlay when embedded (return to Pause), else go to the main menu.
func close() -> void:
	if embedded:
		queue_free()
	else:
		get_tree().change_scene_to_file(MENU_SCENE)


func _on_back() -> void:
	close()
