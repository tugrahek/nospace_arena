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
	Economy.boosts_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_coins.text = tr("HUD_CURRENCY") + ": " + str(Economy.balance())
	for c in _list.get_children():
		c.queue_free()
	_add_header(tr("STORE_CHARACTERS"))
	for ch in ContentCatalog.CHARACTERS:
		_add_item("character", ch.id, tr(ch.display_name_key), tr(ch.description_key), ch.unlock_cost,
			Economy.selected_character() == ch.id, Color())
	_add_header(tr("STORE_ARENAS"))
	for ar in ContentCatalog.ARENAS:
		# trail_color reads more distinct per arena than border_color (Void/Frost borders are
		# near-identical blue; trails are cyan / gold / icy-white).
		var swatch: Color = ar.theme.trail_color if ar.theme != null else Color(1, 1, 1, 1)
		_add_item("arena", ar.id, tr(ar.display_name_key), tr(ar.description_key), ar.unlock_cost,
			Economy.selected_arena() == ar.id, swatch)
	_add_header(tr("STORE_BOOSTS"))
	for b in ContentCatalog.BOOSTS:
		_add_boost_item(b)


func _add_header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"Heading"
	_list.add_child(l)


const EffectIcon = preload("res://scripts/ui/effect_icon.gd")
const BoostIcon = preload("res://scripts/ui/boost_icon.gd")


func _add_item(kind: String, id: StringName, item_name: String, desc: String, cost: int, is_selected: bool, swatch: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_make_visual(kind, id, swatch))  # leading motoriçi icon / color swatch
	# Left column: name + one-line description (data-driven from the .tres description_key).
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(260, 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	var nl := Label.new()
	nl.text = item_name
	nl.add_theme_font_size_override("font_size", 20)
	var dl := Label.new()
	dl.text = desc
	dl.add_theme_font_size_override("font_size", 14)
	dl.add_theme_color_override("font_color", Color(0.74, 0.72, 0.84, 1.0))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(nl)
	info.add_child(dl)
	row.add_child(info)
	if Economy.is_unlocked(kind, id):
		if is_selected:
			var s := Label.new()
			s.text = tr("STORE_SELECTED")
			s.add_theme_color_override("font_color", Color(0.4, 1, 0.55, 1))  # success/selected
			row.add_child(s)
		else:
			var b := JuicyButton.new()
			b.text = tr("STORE_SELECT")
			b.custom_minimum_size = Vector2(150, 44)
			b.pressed.connect(_on_select.bind(kind, id))
			row.add_child(b)
	else:
		var b := JuicyButton.new()
		b.text = "%s (%d)" % [tr("STORE_BUY"), cost]
		b.custom_minimum_size = Vector2(150, 44)
		b.disabled = not Storefront.can_purchase(false, Economy.balance(), cost)
		b.pressed.connect(_on_buy.bind(kind, id, cost))
		row.add_child(b)
	_list.add_child(row)


## A consumable boost row: name + description + owned count + Buy (disabled if unaffordable).
## Unlike characters/arenas, boosts are bought repeatedly (charges), never "selected".
func _add_boost_item(b: BoostData) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var icon := BoostIcon.new()  # distinct per-effect glyph (heart / coin / clock)
	icon.set("effect", b.effect)
	icon.custom_minimum_size = Vector2(44, 44)
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(260, 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	var nl := Label.new()
	nl.text = tr(b.display_name_key)
	nl.add_theme_font_size_override("font_size", 20)
	var dl := Label.new()
	dl.text = tr(b.description_key)
	dl.add_theme_font_size_override("font_size", 14)
	dl.add_theme_color_override("font_color", Color(0.74, 0.72, 0.84, 1.0))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ol := Label.new()
	ol.text = tr("STORE_OWNED") % Economy.boost_count(b.id)
	ol.add_theme_font_size_override("font_size", 13)
	ol.add_theme_color_override("font_color", Color(0.4, 1, 0.55, 1))
	info.add_child(nl)
	info.add_child(dl)
	info.add_child(ol)
	row.add_child(info)
	var buy := JuicyButton.new()
	buy.text = "%s (%d)" % [tr("STORE_BUY"), b.cost]
	buy.custom_minimum_size = Vector2(150, 44)
	buy.disabled = not Economy.can_afford(b.cost)
	buy.pressed.connect(_on_buy_boost.bind(b.id, b.cost))
	row.add_child(buy)
	_list.add_child(row)


func _on_buy_boost(id: StringName, cost: int) -> void:
	Economy.buy_boost(id, cost)  # success refreshes via currency/boosts signals


## Leading visual: character -> effect symbol (push/slow/freeze); arena -> theme color swatch.
func _make_visual(kind: String, id: StringName, swatch: Color) -> Control:
	if kind == "character":
		var icon: Control = EffectIcon.new()
		icon.set("kind", _effect_kind(id))
		icon.custom_minimum_size = Vector2(44, 44)
		return icon
	var sw := ColorRect.new()
	sw.color = swatch
	sw.custom_minimum_size = Vector2(44, 44)
	return sw


## Character id -> effect symbol kind (0 push / 1 slow / 2 freeze).
func _effect_kind(id: StringName) -> int:
	match String(id):
		"drag":
			return 1
		"halt":
			return 2
		_:
			return 0


func _on_select(kind: String, id: StringName) -> void:
	if kind == "character":
		Economy.set_selected_character(id)
	else:
		Economy.set_selected_arena(id)
	_refresh()


func _on_buy(kind: String, id: StringName, cost: int) -> void:
	Economy.purchase(kind, id, cost)  # success refreshes via currency/unlocks signals
