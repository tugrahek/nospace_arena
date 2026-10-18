extends Control

## Category-first Store view. Economy remains the sole owner of purchase, selection and persistence.

const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const StoreOfferTile = preload("res://scripts/ui/store_offer_tile.gd")
const StoreShowcase = preload("res://scripts/ui/store_showcase.gd")
const PALETTE = preload("res://config/palette.tres")
const MAX_CONTENT_WIDTH: float = 800.0
const FRONTIER_INSET: float = 18.0
const FRONTIER_BOTTOM: float = 6.0
const FRONTIER_HEIGHT: float = 2.0
const SELECTOR_BOTTOM_BREATHING: float = 36.0

@export var minimum_balance_font_size: int = 18

enum Category { CHARACTERS, ARENAS, BOOSTS, SUPPLY }

@onready var _bounds: Control = $SafeArea/Bounds
@onready var _frame: VBoxContainer = $SafeArea/Bounds/Frame
@onready var _scroll: ScrollContainer = $SafeArea/Bounds/Frame/Scroll
@onready var _list: VBoxContainer = $SafeArea/Bounds/Frame/Scroll/List
@onready var _coins: Label = $SafeArea/Bounds/Frame/Header/Coins
@onready var _back: Button = $SafeArea/Bounds/Frame/BackButton
@onready var _title: Label = $SafeArea/Bounds/Frame/Header/Title
@onready var _strip: Control = $SafeArea/Bounds/Frame/CategoryStrip
@onready var _frontier: ColorRect = $SafeArea/Bounds/Frame/CategoryStrip/Frontier
@onready var _tabs: Array[Button] = [$SafeArea/Bounds/Frame/CategoryStrip/Tabs/Characters, $SafeArea/Bounds/Frame/CategoryStrip/Tabs/Arenas, $SafeArea/Bounds/Frame/CategoryStrip/Tabs/Boosts, $SafeArea/Bounds/Frame/CategoryStrip/Tabs/Supply]

var _active_category: int = Category.CHARACTERS
var _focused_indices: Array[int] = [0, 0, 0, 0]
var _supply: SupplyPopup
var _refresh_pending: bool = false
var _selector: HBoxContainer
var _layout_pending: bool = false
var _balance_font_size: int = 0


func _ready() -> void:
	_balance_font_size = _coins.get_theme_font_size("font_size")
	var selector_space := Control.new()
	selector_space.name = "SelectorVerticalBreathing"
	selector_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(selector_space)
	_frame.move_child(selector_space, _back.get_index())
	selector_space.custom_minimum_size.y = SELECTOR_BOTTOM_BREATHING
	_title.text = tr("MENU_STORE")
	_back.text = tr("STORE_BACK")
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	_tabs[Category.CHARACTERS].pressed.connect(set_category.bind(Category.CHARACTERS))
	_tabs[Category.ARENAS].pressed.connect(set_category.bind(Category.ARENAS))
	_tabs[Category.BOOSTS].pressed.connect(set_category.bind(Category.BOOSTS))
	_tabs[Category.SUPPLY].pressed.connect(set_category.bind(Category.SUPPLY))
	_strip.resized.connect(_layout_frontier)
	_bounds.resized.connect(_queue_layout)
	_scroll.resized.connect(_queue_layout)
	Economy.currency_changed.connect(func(_balance: int) -> void: _request_refresh())
	Economy.unlocks_changed.connect(_request_refresh)
	Economy.boosts_changed.connect(_request_refresh)
	_refresh()


## Local view state only; changing categories never changes Economy or persisted data.
func set_category(category: int) -> void:
	if category < Category.CHARACTERS or category > Category.SUPPLY:
		return
	_active_category = category
	_request_refresh(true)


func active_category() -> int:
	return _active_category


func offer_count() -> int:
	return _selector.get_child_count() if _selector != null else 0


func focused_index() -> int:
	return _focused_indices[_active_category]


func _refresh() -> void:
	_refresh_pending = false
	_coins.text = tr("HUD_CURRENCY_VALUE") % Economy.balance()
	for child in _list.get_children():
		child.free()
	_selector = null
	_supply = null
	var selector_space: Control = _frame.get_node("SelectorVerticalBreathing")
	selector_space.custom_minimum_size.y = 0.0 if _active_category == Category.SUPPLY else SELECTOR_BOTTOM_BREATHING
	_list.alignment = BoxContainer.ALIGNMENT_CENTER if _active_category == Category.SUPPLY else BoxContainer.ALIGNMENT_END
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if _active_category == Category.SUPPLY else ScrollContainer.SCROLL_MODE_AUTO
	match _active_category:
		Category.CHARACTERS:
			_build_characters()
		Category.ARENAS:
			_build_arenas()
		Category.BOOSTS:
			_build_boosts()
		Category.SUPPLY:
			_supply = preload("res://scenes/ui/SupplyPopup.tscn").instantiate()
			_supply.embedded = true
			# The embedded popup owns body scrolling; its Store host must not scroll too.
			_supply.custom_minimum_size.y = 0.0
			_list.add_child(_supply)
			_supply.present()
	_scroll.scroll_vertical = 0
	_update_tab_labels()
	call_deferred("_layout_frontier")
	_queue_layout()


func _queue_layout() -> void:
	if _layout_pending or not is_inside_tree():
		return
	_layout_pending = true
	_refresh_layout.call_deferred()


## Fit the shared shell/showcase; embedded Supply uses its own body scroll within this host.
func _refresh_layout() -> void:
	_layout_pending = false
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var width: float = minf(_bounds.size.x, MAX_CONTENT_WIDTH)
	_frame.offset_left = -width * 0.5
	_frame.offset_right = width * 0.5
	_fit_balance_text(width)
	if _active_category != Category.SUPPLY and is_instance_valid(_selector):
		var showcase: StoreShowcase = _list.get_node_or_null("Showcase") as StoreShowcase
		if showcase != null:
			showcase.fit_height(_scroll.size.y - _selector.get_combined_minimum_size().y
				- float(_list.get_theme_constant("separation")))
	_layout_frontier()


## Fit localized balances beside the centered title without moving either label.
func _fit_balance_text(width: float) -> void:
	var budget: float = maxf(0.0, (width - _title.get_combined_minimum_size().x) * 0.5
		- float(_frame.get_theme_constant("separation")))
	var font: Font = _coins.get_theme_font("font")
	var font_size: int = _balance_font_size
	while font_size > minimum_balance_font_size and font.get_string_size(_coins.text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > budget:
		font_size -= 1
	_coins.add_theme_font_size_override("font_size", font_size)


## Rebuild only after the current button/signal stack returns; never free an emitting control.
func _request_refresh(force: bool = false) -> void:
	if not force and _active_category == Category.SUPPLY and is_instance_valid(_supply):
		_coins.text = tr("HUD_CURRENCY_VALUE") % Economy.balance()
		_queue_layout()
		_supply.refresh()
		return
	if _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("_refresh")


func _build_characters() -> void:
	var index := _valid_focus(ContentCatalog.CHARACTERS.size())
	var character = ContentCatalog.CHARACTERS[index]
	var showcase: StoreShowcase = StoreShowcase.new()
	showcase.name = "Showcase"
	showcase.configure_loadout(StoreShowcase.Kind.CHARACTER, character.id, tr(character.display_name_key),
		tr(character.description_key), Economy.is_unlocked("character", character.id),
		Economy.selected_character() == character.id, Economy.can_afford(character.unlock_cost), character.unlock_cost,
		_effect_kind(character.id))
	_bind_showcase(showcase)
	for selector_index in ContentCatalog.CHARACTERS.size():
		var offer = ContentCatalog.CHARACTERS[selector_index]
		_add_selector(StoreOfferTile.Kind.CHARACTER, offer.id, selector_index, tr(offer.display_name_key),
			_effect_kind(offer.id))


func _build_arenas() -> void:
	var index := _valid_focus(ContentCatalog.ARENAS.size())
	var arena: ArenaData = ContentCatalog.ARENAS[index]
	var theme: ThemeData = arena.theme
	var showcase: StoreShowcase = StoreShowcase.new()
	showcase.name = "Showcase"
	showcase.configure_loadout(StoreShowcase.Kind.ARENA, arena.id, tr(arena.display_name_key),
		tr(arena.description_key), Economy.is_unlocked("arena", arena.id), Economy.selected_arena() == arena.id,
		Economy.can_afford(arena.unlock_cost), arena.unlock_cost, 0, Vector2i(arena.cols, arena.rows), theme.void_color,
		theme.border_color, theme.trail_color, theme.captured_base_color)
	_bind_showcase(showcase)
	for selector_index in ContentCatalog.ARENAS.size():
		var offer: ArenaData = ContentCatalog.ARENAS[selector_index]
		var offer_theme: ThemeData = offer.theme
		_add_selector(StoreOfferTile.Kind.ARENA, offer.id, selector_index, tr(offer.display_name_key), 0,
			Vector2i(offer.cols, offer.rows), offer_theme.void_color, offer_theme.border_color)


func _build_boosts() -> void:
	var index := _valid_focus(ContentCatalog.BOOSTS.size())
	var boost: BoostData = ContentCatalog.BOOSTS[index]
	var showcase: StoreShowcase = StoreShowcase.new()
	showcase.name = "Showcase"
	showcase.configure_boost(boost.id, boost, Economy.boost_count(boost.id), Economy.can_afford(boost.cost))
	_bind_showcase(showcase)
	for selector_index in ContentCatalog.BOOSTS.size():
		var offer: BoostData = ContentCatalog.BOOSTS[selector_index]
		_add_selector(StoreOfferTile.Kind.BOOST, offer.id, selector_index, tr(offer.display_name_key), offer.effect)


func _bind_showcase(showcase: StoreShowcase) -> void:
	showcase.select_requested.connect(_on_select)
	showcase.purchase_requested.connect(_on_buy)
	_list.add_child(showcase)
	var rail := HBoxContainer.new()
	rail.name = "Selector"
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 12)
	rail.minimum_size_changed.connect(_queue_layout)
	_list.add_child(rail)
	_selector = rail


func _add_selector(offer_kind: int, id: StringName, index: int, item_name: String, effect_kind: int,
		arena_size: Vector2i = Vector2i.ONE, void_color: Color = Color(), border_color: Color = Color()) -> void:
	var tile: StoreOfferTile = StoreOfferTile.new()
	tile.name = "Selector_%s" % id
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.configure_selector(offer_kind, id, index, item_name, index == focused_index(), effect_kind,
		arena_size, void_color, border_color)
	tile.focus_requested.connect(_on_focus_requested)
	_selector.add_child(tile)


func _on_focus_requested(index: int) -> void:
	_focused_indices[_active_category] = index
	_request_refresh()


func _valid_focus(count: int) -> int:
	var index := _focused_indices[_active_category]
	if index < 0 or index >= count:
		index = 0
		_focused_indices[_active_category] = index
	return index


func _update_tab_labels() -> void:
	var keys: Array[String] = ["STORE_CHARACTERS", "STORE_ARENAS", "STORE_BOOSTS", "SUPPLY_ENTRY"]
	for index in _tabs.size():
		var tab: Button = _tabs[index]
		tab.text = tr(keys[index])
		tab.add_theme_color_override("font_color", PALETTE.accent if index == _active_category else PALETTE.text_secondary)


func _layout_frontier() -> void:
	if _active_category >= _tabs.size():
		return
	var active: Button = _tabs[_active_category]
	_frontier.position = Vector2(active.position.x + FRONTIER_INSET, _strip.size.y - FRONTIER_BOTTOM)
	_frontier.size = Vector2(maxf(active.size.x - FRONTIER_INSET * 2.0, 20.0), FRONTIER_HEIGHT)


func _on_select(kind: String, id: StringName) -> void:
	if kind == "character":
		Economy.set_selected_character(id)
	else:
		Economy.set_selected_arena(id)
	_request_refresh()


func _on_buy(kind: String, id: StringName, cost: int) -> void:
	if kind == "boost":
		Economy.buy_boost(id, cost)
	else:
		Economy.purchase(kind, id, cost)


func _effect_kind(id: StringName) -> int:
	match String(id):
		"drag":
			return 1
		"halt":
			return 2
		_:
			return 0
