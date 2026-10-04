class_name SettingsLanguageSelector
extends Control

## A scrollable presentation list; the Settings controller retains persistence ownership.
signal language_selected(code: String)
const PALETTE: PaletteData = preload("res://config/palette.tres")
const ROW_HEIGHT: float = 84.0
var options: Array[Dictionary] = [
	{"code": "", "key": "LANG_AUTO"}, {"code": "en", "key": "LANG_EN"}, {"code": "tr", "key": "LANG_TR"}
]
var selected_code: String = ""
var _title: Label
var _back: Button
var _list: VBoxContainer
var _buttons: Array[Button] = []
var scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = PALETTE.void_bg
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 72.0
	column.offset_right = -72.0
	column.offset_top = 150.0
	column.offset_bottom = -110.0
	column.add_theme_constant_override("separation", 32)
	add_child(column)
	_title = Label.new()
	_title.theme_type_variation = &"Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_build_list(column)
	_back = Button.new()
	_back.custom_minimum_size = Vector2(220, 56)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.theme_type_variation = &"Secondary"
	_back.pressed.connect(queue_free)
	column.add_child(_back)
	refresh()


func _build_list(column: VBoxContainer) -> void:
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	for option in options:
		var button := Button.new()
		button.custom_minimum_size.y = ROW_HEIGHT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(func() -> void: language_selected.emit(option["code"]))
		_list.add_child(button)
		_buttons.append(button)


## Refreshes localized text and current selection after an immediate locale switch.
func refresh() -> void:
	_title.text = tr("SETTINGS_LANGUAGE")
	_back.text = tr("SETTINGS_BACK")
	for i in _buttons.size():
		var selected: bool = options[i]["code"] == selected_code
		var button: Button = _buttons[i]
		button.text = ("◆   " if selected else "◇   ") + tr(options[i]["key"])
		var style := StyleBoxFlat.new()
		style.bg_color = PALETTE.accent.darkened(0.82) if selected else PALETTE.panel.darkened(0.35)
		style.border_color = PALETTE.accent if selected else PALETTE.text_secondary.darkened(0.65)
		style.border_width_bottom = 2 if selected else 1
		style.content_margin_left = 22.0
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", PALETTE.accent if selected else PALETTE.text_primary)
		button.add_theme_color_override("font_hover_color", PALETTE.accent)
