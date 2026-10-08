class_name BoostLoadoutChip
extends Button

## Whole-chip boost arm intent. Economy remains authoritative for inventory and arming.
signal armed_changed(pressed: bool, boost_id: StringName)
const PALETTE: PaletteData = preload("res://config/palette.tres")
const ICON = preload("res://scripts/ui/boost_icon.gd")
var boost_id: StringName
var _marker: Label


## Builds a compact icon/name/count target; zero charges disable the whole chip.
func configure(data: BoostData, count: int, armed: bool) -> void:
	boost_id = data.id
	toggle_mode = true
	armed = armed and count > 0
	button_pressed = armed
	disabled = count <= 0
	custom_minimum_size = Vector2(0, 80)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modulate.a = 0.4 if disabled else 1.0
	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_right = -8
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	var icon: Control = ICON.new()
	icon.set("effect", ICON.COIN_BONUS_ICON if data.id == &"coin_bonus" else data.effect)
	icon.custom_minimum_size = Vector2(26, 26)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var labels := VBoxContainer.new()
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(_label(tr(data.display_name_key), 14))
	labels.add_child(_label("×%d" % count, 16))
	content.add_child(labels)
	_marker = _label("◆", 12)
	_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_marker.add_theme_color_override("font_color", PALETTE.accent)
	content.add_child(_marker)
	add_child(content)
	_style(armed)
	toggled.connect(_on_toggled)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _style(armed: bool) -> void:
	_marker.visible = armed
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.panel
	style.border_color = PALETTE.accent if armed else PALETTE.border.darkened(0.6)
	style.set_border_width_all(2 if armed else 1)
	for key: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(key, style)


func _on_toggled(pressed: bool) -> void:
	if disabled:
		set_pressed_no_signal(false)
		return
	_style(pressed)
	armed_changed.emit(pressed, boost_id)
