class_name BoostLoadoutChip
extends Button

## Whole-chip boost arm intent. Economy remains authoritative for inventory and arming.
signal armed_changed(pressed: bool, boost_id: StringName)
const PALETTE: PaletteData = preload("res://config/palette.tres")
const ICON = preload("res://scripts/ui/boost_icon.gd")
const CHIP_HEIGHT: float = 176.0
const CONTENT_INSET: float = 12.0
const ICON_SIZE: float = 40.0
const NAME_FONT_SIZE: int = 22
const COUNT_FONT_SIZE: int = 24
var boost_id: StringName
var _marker: Label


## Builds a compact icon/name/count target; zero charges disable the whole chip.
func configure(data: BoostData, count: int, armed: bool) -> void:
	boost_id = data.id
	toggle_mode = true
	armed = armed and count > 0
	button_pressed = armed
	disabled = count <= 0
	custom_minimum_size = Vector2(0, CHIP_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modulate.a = 0.65 if disabled else 1.0
	_build_content(data, count)
	_style(armed)
	toggled.connect(_on_toggled)


func _build_content(data: BoostData, count: int) -> void:
	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = CONTENT_INSET
	content.offset_top = CONTENT_INSET
	content.offset_right = -CONTENT_INSET
	content.offset_bottom = -CONTENT_INSET
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 6)
	var icon: Control = ICON.new()
	icon.name = "Icon"
	icon.set("effect", ICON.COIN_BONUS_ICON if data.id == &"coin_bonus" else data.effect)
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var name_label: Label = _label(tr(data.display_name_key), NAME_FONT_SIZE)
	name_label.name = "Name"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(name_label)
	var count_label: Label = _label("×%d" % count, COUNT_FONT_SIZE)
	count_label.name = "Count"
	content.add_child(count_label)
	add_child(content)
	_build_marker()


func _build_marker() -> void:
	_marker = _label("◆", 16)
	_marker.name = "Selected"
	_marker.anchor_left = 1.0
	_marker.anchor_right = 1.0
	_marker.offset_left = -28.0
	_marker.offset_right = -8.0
	_marker.offset_top = 8.0
	_marker.offset_bottom = 28.0
	_marker.add_theme_color_override("font_color", PALETTE.accent)
	add_child(_marker)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
