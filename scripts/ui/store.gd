extends Control

## Store: buy locked characters/arenas with coins, or select an unlocked one. Rows are
## built in code from ContentCatalog. Functional scaffold — visual polish is Step 15.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"

@onready var _list: VBoxContainer = $Scroll/List
@onready var _coins: Label = $Coins
@onready var _back: Button = $BackButton


func _ready() -> void:
	_back.text = tr("STORE_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	Economy.currency_changed.connect(func(_b: int) -> void: _refresh())
	Economy.unlocks_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_coins.text = tr("HUD_CURRENCY") + ": " + str(Economy.balance())
	for c in _list.get_children():
		c.queue_free()
	_add_header(tr("STORE_CHARACTERS"))
	for ch in ContentCatalog.CHARACTERS:
		_add_item("character", ch.id, tr(ch.display_name_key), ch.unlock_cost,
			Economy.selected_character() == ch.id)
	_add_header(tr("STORE_ARENAS"))
	for ar in ContentCatalog.ARENAS:
		_add_item("arena", ar.id, tr(ar.display_name_key), ar.unlock_cost,
			Economy.selected_arena() == ar.id)


func _add_header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"Heading"
	_list.add_child(l)


func _add_item(kind: String, id: StringName, item_name: String, cost: int, is_selected: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var nl := Label.new()
	nl.text = item_name
	nl.custom_minimum_size = Vector2(260, 44)
	nl.add_theme_font_size_override("font_size", 20)
	row.add_child(nl)
	if Economy.is_unlocked(kind, id):
		if is_selected:
			var s := Label.new()
			s.text = tr("STORE_SELECTED")
			s.add_theme_color_override("font_color", Color(0.4, 1, 0.55, 1))  # success/selected
			row.add_child(s)
		else:
			var b := Button.new()
			b.text = tr("STORE_SELECT")
			b.custom_minimum_size = Vector2(150, 44)
			b.pressed.connect(_on_select.bind(kind, id))
			row.add_child(b)
	else:
		var b := Button.new()
		b.text = "%s (%d)" % [tr("STORE_BUY"), cost]
		b.custom_minimum_size = Vector2(150, 44)
		b.disabled = not Storefront.can_purchase(false, Economy.balance(), cost)
		b.pressed.connect(_on_buy.bind(kind, id, cost))
		row.add_child(b)
	_list.add_child(row)


func _on_select(kind: String, id: StringName) -> void:
	if kind == "character":
		Economy.set_selected_character(id)
	else:
		Economy.set_selected_arena(id)
	_refresh()


func _on_buy(kind: String, id: StringName, cost: int) -> void:
	Economy.purchase(kind, id, cost)  # success refreshes via currency/unlocks signals
