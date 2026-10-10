class_name SupplyOddsRow
extends HBoxContainer

## Presentation-only category disclosure with aligned procedural icon, label and probability.
const ICON = preload("res://scripts/ui/boost_icon.gd")


## Builds one compact category row; weights are read from the existing Resource by the view.
func configure(label_text: String, probability: String, effect: int) -> void:
	custom_minimum_size = Vector2(0, 88)
	add_theme_constant_override("separation", 18)
	var icon: Control = ICON.new()
	icon.name = "Icon"
	icon.set("effect", effect)
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var label := Label.new()
	label.name = "Name"
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	var percent := Label.new()
	percent.name = "Probability"
	percent.text = probability
	percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	percent.add_theme_font_size_override("font_size", 26)
	add_child(percent)
