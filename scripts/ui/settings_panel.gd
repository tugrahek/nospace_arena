extends Control

## Non-scrollable Settings navigation with separate audio and control views. Backed by
## AudioManager (which owns AudioSettings + SettingsStore). Live-applies while dragging and
## persists once on drag end (debounced). Mute is a single event -> applied + saved at once.

const LEGAL_SCENE: PackedScene = preload("res://scenes/ui/Credits.tscn")
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const PALETTE: PaletteData = preload("res://config/palette.tres")
const LANGUAGE_SELECTOR = preload("res://scripts/ui/settings_language_selector.gd")
const MAX_CONTENT_WIDTH: float = 800.0
const FOOTER_GAP: float = 12.0
enum View { MAIN, AUDIO, CONTROLS }

## When true the panel was opened as an overlay (e.g. from in-run Pause); Back closes it.
## When false (launched from MainMenu) Back returns to the main menu.
var embedded: bool = false
var _view: View = View.MAIN
var _legal_view: Control
var _language_overlay: SettingsLanguageSelector

@onready var _title: Label = $SafeArea/Bounds/Center/Header/Title
@onready var _bounds: Control = $SafeArea/Bounds
@onready var _center: VBoxContainer = $SafeArea/Bounds/Center
@onready var _bottom: VBoxContainer = $SafeArea/Bounds/Bottom
@onready var _main_view: Control = $SafeArea/Bounds/Center/Views/Main
@onready var _audio_view: Control = $SafeArea/Bounds/Center/Views/Audio
@onready var _controls_view: Control = $SafeArea/Bounds/Center/Views/Controls
@onready var _audio_button: Button = $SafeArea/Bounds/Center/Views/Main/AudioButton
@onready var _controls_button: Button = $SafeArea/Bounds/Center/Views/Main/ControlsButton
@onready var _legal_footer: Control = $SafeArea/Bounds/Bottom/LegalFooter
@onready var _master: HSlider = $SafeArea/Bounds/Center/Views/Audio/MasterRow/Slider
@onready var _sfx: HSlider = $SafeArea/Bounds/Center/Views/Audio/SfxRow/Slider
@onready var _music: HSlider = $SafeArea/Bounds/Center/Views/Audio/MusicRow/Slider
@onready var _master_label: Label = $SafeArea/Bounds/Center/Views/Audio/MasterRow/Header/NameLabel
@onready var _sfx_label: Label = $SafeArea/Bounds/Center/Views/Audio/SfxRow/Header/NameLabel
@onready var _music_label: Label = $SafeArea/Bounds/Center/Views/Audio/MusicRow/Header/NameLabel
@onready var _master_value: Label = $SafeArea/Bounds/Center/Views/Audio/MasterRow/Header/ValueLabel
@onready var _sfx_value: Label = $SafeArea/Bounds/Center/Views/Audio/SfxRow/Header/ValueLabel
@onready var _music_value: Label = $SafeArea/Bounds/Center/Views/Audio/MusicRow/Header/ValueLabel
@onready var _mute_label: Label = $SafeArea/Bounds/Center/Views/Audio/MuteRow/Content/NameLabel
@onready var _mute_state: Label = $SafeArea/Bounds/Center/Views/Audio/MuteRow/Content/StateLabel
@onready var _mute: Button = $SafeArea/Bounds/Center/Views/Audio/MuteRow
@onready var _swipe: Button = $SafeArea/Bounds/Center/Views/Controls/Segment/SwipeButton
@onready var _tap: Button = $SafeArea/Bounds/Center/Views/Controls/Segment/TapButton
@onready var _dpad: Button = $SafeArea/Bounds/Center/Views/Controls/Segment/DpadButton
@onready var _language_button: Button = $SafeArea/Bounds/Center/Views/Main/LanguageRow/LanguageButton
@onready var _copyright: Label = $SafeArea/Bounds/Bottom/LegalFooter/Copyright
@onready var _licenses: Button = $SafeArea/Bounds/Bottom/LegalFooter/LicensesButton
@onready var _privacy: Button = $SafeArea/Bounds/Bottom/LegalFooter/PrivacyButton
@onready var _back: Button = $SafeArea/Bounds/Center/Header/BackButton


func _ready() -> void:
	_bottom.minimum_size_changed.connect(_refresh_layout)
	for button: Button in [_back, _licenses, _privacy, _language_button, _audio_button, _controls_button, _mute, _swipe, _tap, _dpad]:
		preload("res://scripts/ui/touch_target_sizing.gd").attach(button)
	_bounds.resized.connect(_refresh_layout)
	_refresh_layout()
	_style_mute()
	_style_flat_actions()
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
	_audio_button.pressed.connect(_show_view.bind(View.AUDIO))
	_controls_button.pressed.connect(_show_view.bind(View.CONTROLS))
	_connect_audio()
	_mute.toggled.connect(_on_mute_toggled)
	_back.pressed.connect(_on_back)
	_licenses.pressed.connect(_open_legal)
	_connect_privacy_options()


func _connect_privacy_options() -> void:
	_privacy.pressed.connect(_open_privacy_options)
	AdsService.privacy_options_changed.connect(_on_privacy_options_changed)
	_on_privacy_options_changed(AdsService.is_privacy_options_required(), AdsService.is_privacy_options_busy())


## Keep the legal footer accessible when Android hit minima require more than authored space.
func _refresh_layout() -> void:
	var width: float = minf(_bounds.size.x, MAX_CONTENT_WIDTH)
	_center.offset_left = -width * 0.5
	_center.offset_right = width * 0.5
	_bottom.offset_left = -width * 0.5
	_bottom.offset_right = width * 0.5
	var footer_height: float = _bottom.get_combined_minimum_size().y
	_bottom.offset_top = -footer_height
	_center.offset_bottom = _bottom.offset_top - FOOTER_GAP


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


## Rebuilds this panel's code-assigned text after Godot changes the active translation.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_texts()


## All panel texts from the ACTIVE locale — called on ready and again after a language switch
## so the panel itself updates in place. (Language names stay endonyms: English / Türkçe.)
func _apply_texts() -> void:
	_copyright.text = tr("SETTINGS_COPYRIGHT")
	_licenses.text = tr("SETTINGS_LICENSES")
	_privacy.text = tr("SETTINGS_PRIVACY_CHOICES")
	_title.text = tr(["SETTINGS_TITLE", "SETTINGS_AUDIO", "SETTINGS_CONTROLS"][_view])
	_audio_button.text = tr("SETTINGS_AUDIO")
	_master_label.text = tr("SETTINGS_MASTER")
	_sfx_label.text = tr("SETTINGS_SFX")
	_music_label.text = tr("SETTINGS_MUSIC")
	_mute_label.text = tr("SETTINGS_MUTE")
	_refresh_mute_state()
	_controls_button.text = tr("SETTINGS_CONTROLS")
	_swipe.text = tr("CONTROL_SWIPE")
	_tap.text = tr("CONTROL_TAP")
	_dpad.text = tr("CONTROL_DPAD")
	var language: String = AudioManager.settings().language
	var key: String = "LANG_AUTO" if language.is_empty() else "LANG_" + language.to_upper()
	_language_button.text = tr("SETTINGS_LANGUAGE") + "\n" + tr(key)
	_back.text = "›" if TranslationServer.get_locale() == "ar" else "‹"
	_back.tooltip_text = tr("SETTINGS_BACK")
	_back.accessibility_name = tr("SETTINGS_BACK")


func _on_language(lang: String) -> void:
	AudioManager.set_language(lang)  # applies the locale + persists
	# Auto -> explicit may resolve to the same locale without a translation notification.
	_apply_texts()
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


## Flat header/footer actions retain their hit minima without themed panel padding.
func _style_flat_actions() -> void:
	for button: Button in [_back, _licenses, _privacy]:
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var style: StyleBox = button.get_theme_stylebox(state).duplicate()
			style.content_margin_top = 0.0
			style.content_margin_bottom = 0.0
			style.content_margin_left = 6.0
			style.content_margin_right = 6.0
			button.add_theme_stylebox_override(state, style)


func _style_mute() -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		_mute.add_theme_stylebox_override(state, empty)


## Switches local views without replacing controls or their persisted state.
func _show_view(view: View) -> void:
	_view = view
	_main_view.visible = view == View.MAIN
	_audio_view.visible = view == View.AUDIO
	_controls_view.visible = view == View.CONTROLS
	_legal_footer.visible = view == View.MAIN
	_apply_texts()
	_refresh_layout()
	(_audio_button if view == View.MAIN else _back).grab_focus()


## Back closes the top view first; only the main view may exit to Pause/Main Menu.
func close() -> void:
	if is_instance_valid(_legal_view):
		_legal_view.close()
	elif is_instance_valid(_language_overlay):
		_language_overlay.queue_free()
	elif _view != View.MAIN:
		_show_view(View.MAIN)
	elif embedded:
		queue_free()
	else:
		get_tree().change_scene_to_file(MENU_SCENE)


func _on_back() -> void:
	close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
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
