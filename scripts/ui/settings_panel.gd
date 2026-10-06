extends Control

## Audio settings panel: master/sfx/music sliders + a single master-mute toggle. Backed by
## AudioManager (which owns AudioSettings + SettingsStore). Live-applies while dragging and
## persists once on drag end (debounced). Mute is a single event -> applied + saved at once.

const LEGAL_SCENE: PackedScene = preload("res://scenes/ui/Credits.tscn")
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const PALETTE: PaletteData = preload("res://config/palette.tres")
const LANGUAGE_SELECTOR = preload("res://scripts/ui/settings_language_selector.gd")

## When true the panel was opened as an overlay (e.g. from in-run Pause); Back closes it.
## When false (launched from MainMenu) Back returns to the main menu.
var embedded: bool = false
var _legal_view: Control
var _language_overlay: SettingsLanguageSelector

@onready var _title: Label = $Center/Title
@onready var _audio_label: Label = $Center/Rows/AudioHeading
@onready var _master: HSlider = $Center/Rows/MasterRow/Slider
@onready var _sfx: HSlider = $Center/Rows/SfxRow/Slider
@onready var _music: HSlider = $Center/Rows/MusicRow/Slider
@onready var _master_label: Label = $Center/Rows/MasterRow/Header/NameLabel
@onready var _sfx_label: Label = $Center/Rows/SfxRow/Header/NameLabel
@onready var _music_label: Label = $Center/Rows/MusicRow/Header/NameLabel
@onready var _master_value: Label = $Center/Rows/MasterRow/Header/ValueLabel
@onready var _sfx_value: Label = $Center/Rows/SfxRow/Header/ValueLabel
@onready var _music_value: Label = $Center/Rows/MusicRow/Header/ValueLabel
@onready var _mute_label: Label = $Center/Rows/MuteRow/Content/NameLabel
@onready var _mute_state: Label = $Center/Rows/MuteRow/Content/StateLabel
@onready var _mute: Button = $Center/Rows/MuteRow
@onready var _controls_label: Label = $Center/ControlsRow/NameLabel
@onready var _swipe: Button = $Center/ControlsRow/Segment/SwipeButton
@onready var _tap: Button = $Center/ControlsRow/Segment/TapButton
@onready var _dpad: Button = $Center/ControlsRow/Segment/DpadButton
@onready var _language_label: Label = $Center/LanguageRow/NameLabel
@onready var _language_button: Button = $Center/LanguageRow/LanguageButton
@onready var _copyright: Label = $Center/LegalFooter/Copyright
@onready var _licenses: Button = $Center/LegalFooter/LicensesButton
@onready var _privacy: Button = $Center/LegalFooter/PrivacyButton
@onready var _back: Button = $Center/BackButton


func _ready() -> void:
	_style_mute()
	_apply_texts()
	# Fill controls from the persisted settings (round-trip).
	var s: AudioSettings = AudioManager.settings()
	_master.value = s.master
	_sfx.value = s.sfx
	_music.value = s.music
	_update_value_label(s.master, _master_value)
	_update_value_label(s.sfx, _sfx_value)
	_update_value_label(s.music, _music_value)
	_mute.button_pressed = s.muted
	_refresh_mute_state()
	# Controls segment: reflect saved scheme (SchemeId: 0=tap, 1=swipe, 2=dpad), save on press.
	_swipe.button_pressed = s.control_scheme == 1
	_tap.button_pressed = s.control_scheme == 0
	_dpad.button_pressed = s.control_scheme == 2
	_swipe.pressed.connect(func() -> void: AudioManager.set_control_scheme(1))
	_tap.pressed.connect(func() -> void: AudioManager.set_control_scheme(0))
	_dpad.pressed.connect(func() -> void: AudioManager.set_control_scheme(2))
	_style_language_button()
	_language_button.pressed.connect(_open_language_selector)
	_connect_audio()
	_mute.toggled.connect(_on_mute_toggled)
	_back.pressed.connect(_on_back)
	_licenses.pressed.connect(_open_legal)
	_connect_privacy_options()


func _connect_privacy_options() -> void:
	_privacy.pressed.connect(_open_privacy_options)
	AdsService.privacy_options_changed.connect(_on_privacy_options_changed)
	_on_privacy_options_changed(AdsService.is_privacy_options_required(), AdsService.is_privacy_options_busy())


func _connect_audio() -> void:
	# Live-apply on change; persist once on drag end (debounced).
	_master.value_changed.connect(func(v: float) -> void: AudioManager.apply_master(v))
	_sfx.value_changed.connect(func(v: float) -> void: AudioManager.apply_sfx(v))
	_music.value_changed.connect(func(v: float) -> void: AudioManager.apply_music(v))
	_master.value_changed.connect(_update_value_label.bind(_master_value))
	_sfx.value_changed.connect(_update_value_label.bind(_sfx_value))
	_music.value_changed.connect(_update_value_label.bind(_music_value))
	_master.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_sfx.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())
	_music.drag_ended.connect(func(_c: bool) -> void: AudioManager.commit_settings())


## All panel texts from the ACTIVE locale — called on ready and again after a language switch
## so the panel itself updates in place. (Language names stay endonyms: English / Türkçe.)
func _apply_texts() -> void:
	_copyright.text = tr("SETTINGS_COPYRIGHT")
	_licenses.text = tr("SETTINGS_LICENSES")
	_privacy.text = tr("SETTINGS_PRIVACY_CHOICES")
	_title.text = tr("SETTINGS_TITLE")
	_audio_label.text = tr("SETTINGS_AUDIO")
	_master_label.text = tr("SETTINGS_MASTER")
	_sfx_label.text = tr("SETTINGS_SFX")
	_music_label.text = tr("SETTINGS_MUSIC")
	_mute_label.text = tr("SETTINGS_MUTE")
	_refresh_mute_state()
	_controls_label.text = tr("SETTINGS_CONTROLS")
	_swipe.text = tr("CONTROL_SWIPE")
	_tap.text = tr("CONTROL_TAP")
	_dpad.text = tr("CONTROL_DPAD")
	_language_label.text = tr("SETTINGS_LANGUAGE")
	var key: String = {"": "LANG_AUTO", "en": "LANG_EN", "tr": "LANG_TR"}.get(AudioManager.settings().language, "LANG_AUTO")
	_language_button.text = tr(key)
	_back.text = tr("SETTINGS_BACK")


func _on_language(lang: String) -> void:
	AudioManager.set_language(lang)  # applies the locale + persists
	_apply_texts()  # this panel updates in place; other screens rebuild on scene entry
	if is_instance_valid(_language_overlay):
		_language_overlay.selected_code = lang
		_language_overlay.refresh()


func _open_language_selector() -> void:
	if is_instance_valid(_language_overlay):
		return
	_language_overlay = LANGUAGE_SELECTOR.new()
	_language_overlay.selected_code = AudioManager.settings().language
	_language_overlay.language_selected.connect(_on_language)
	_language_overlay.tree_exited.connect(func() -> void: _language_overlay = null, CONNECT_ONE_SHOT)
	add_child(_language_overlay)


func _style_language_button() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.panel.darkened(0.25)
	style.border_width_bottom = 2
	style.border_color = PALETTE.text_secondary.darkened(0.35)
	style.content_margin_left = 22.0
	for state in ["normal", "hover", "pressed", "focus"]:
		_language_button.add_theme_stylebox_override(state, style)


func _on_mute_toggled(on: bool) -> void:
	AudioManager.set_muted(on)
	_refresh_mute_state()


func _update_value_label(value: float, label: Label) -> void:
	label.text = "%d%%" % roundi(value * 100.0)


func _refresh_mute_state() -> void:
	_mute_state.text = tr("SETTINGS_STATE_ON") if _mute.button_pressed else tr("SETTINGS_STATE_OFF")
	_mute_state.add_theme_color_override("font_color", PALETTE.accent if _mute.button_pressed else PALETTE.text_secondary)
	var state_style := StyleBoxFlat.new()
	state_style.bg_color = PALETTE.accent.darkened(0.82) if _mute.button_pressed else PALETTE.panel.darkened(0.25)
	state_style.border_color = PALETTE.accent if _mute.button_pressed else PALETTE.text_secondary.darkened(0.4)
	state_style.set_border_width_all(1)
	state_style.content_margin_left = 14.0
	state_style.content_margin_right = 14.0
	state_style.content_margin_top = 8.0
	state_style.content_margin_bottom = 8.0
	_mute_state.add_theme_stylebox_override("normal", state_style)


func _style_mute() -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		_mute.add_theme_stylebox_override(state, empty)


## Back: close the overlay when embedded (return to Pause), else go to the main menu.
func close() -> void:
	if is_instance_valid(_legal_view):
		_legal_view.close()
	elif is_instance_valid(_language_overlay):
		_language_overlay.queue_free()
	elif embedded:
		queue_free()
	else:
		get_tree().change_scene_to_file(MENU_SCENE)


func _on_back() -> void:
	close()


func _open_privacy_options() -> void:
	AdsService.show_privacy_options()


func _on_privacy_options_changed(required: bool, busy: bool) -> void:
	_privacy.visible = required
	_privacy.disabled = busy


## Opens licenses above this same Settings instance, preserving paused/embedded context.
func _open_legal() -> void:
	if is_instance_valid(_legal_view):
		return
	_legal_view = LEGAL_SCENE.instantiate() as Control
	_legal_view.tree_exited.connect(func() -> void: _legal_view = null, CONNECT_ONE_SHOT)
	add_child(_legal_view)
