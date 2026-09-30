extends GutTest

const STORE_SCENE: PackedScene = preload("res://scenes/ui/Store.tscn")
const StoreShowcase = preload("res://scripts/ui/store_showcase.gd")
const StoreOfferTile = preload("res://scripts/ui/store_offer_tile.gd")


func after_each() -> void:
	TranslationServer.set_locale("en")


func _store() -> Control:
	var store: Control = STORE_SCENE.instantiate()
	add_child_autofree(store)
	return store


func _refresh_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func test_default_category_builds_one_showcase_and_three_focus_selectors() -> void:
	var store := _store()
	await _refresh_frame()
	assert_eq(store.active_category(), store.Category.CHARACTERS)
	assert_eq(store.offer_count(), ContentCatalog.CHARACTERS.size())
	assert_eq(store.get_node("Scroll/List").get_child_count(), 2)
	assert_not_null(store.get_node_or_null("Scroll/List/Showcase"))
	assert_eq(store.get_node("Scroll/List/Selector").get_child_count(), 3)


func test_category_switch_keeps_three_items_and_valid_category_local_focus() -> void:
	var store := _store()
	await _refresh_frame()
	store.set_category(store.Category.ARENAS)
	await _refresh_frame()
	assert_eq(store.offer_count(), ContentCatalog.ARENAS.size())
	assert_eq(store.focused_index(), 0)
	assert_eq(store.get_node("Scroll/List/Selector").get_child_count(), 3)
	store.set_category(store.Category.BOOSTS)
	await _refresh_frame()
	assert_eq(store.offer_count(), ContentCatalog.BOOSTS.size())
	assert_eq(store.focused_index(), 0)
	assert_eq(store.get_node("Scroll/List").get_child_count(), 2)


func test_focus_only_changes_view_local_showcase_not_economy_state() -> void:
	var selected_character := Economy.selected_character()
	var selected_arena := Economy.selected_arena()
	var balance := Economy.balance()
	var store := _store()
	await _refresh_frame()
	store._on_focus_requested(2)
	await _refresh_frame()
	assert_eq(store.focused_index(), 2)
	assert_eq(store.get_node("Scroll/List/Selector").get_child_count(), 3)
	assert_eq(Economy.selected_character(), selected_character)
	assert_eq(Economy.selected_arena(), selected_arena)
	assert_eq(Economy.balance(), balance)


func test_selector_visual_and_label_share_one_full_cell_hit_target() -> void:
	var store := _store()
	await _refresh_frame()
	for category in [store.Category.CHARACTERS, store.Category.ARENAS, store.Category.BOOSTS]:
		store.set_category(category)
		await _refresh_frame()
		var selector: StoreOfferTile = store.get_node("Scroll/List/Selector").get_child(1)
		var visual: Control = selector.get_node("Visual")
		var label: Label = selector.get_node("Label")
		var target: Button = selector.get_node("HitTarget")
		assert_eq(visual.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(label.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(target.size, selector.size)
		target.pressed.emit()
		await _refresh_frame()
		assert_eq(store.focused_index(), 1)


func test_character_selector_previews_keep_common_diamond_with_distinct_effect_modes() -> void:
	var store := _store()
	await _refresh_frame()
	var rail: HBoxContainer = store.get_node("Scroll/List/Selector")
	var modes: Array[int] = []
	for item in rail.get_children():
		var tile: StoreOfferTile = item
		var preview = tile.get_node("Visual").get_child(0)
		modes.append(preview.effect_kind)
	assert_eq(modes, [0, 1, 2])


func test_arena_showcase_preserves_real_source_aspects() -> void:
	var store := _store()
	await _refresh_frame()
	store.set_category(store.Category.ARENAS)
	await _refresh_frame()
	for index in ContentCatalog.ARENAS.size():
		store._on_focus_requested(index)
		await _refresh_frame()
		var arena: ArenaData = ContentCatalog.ARENAS[index]
		var showcase: StoreShowcase = store.get_node("Scroll/List/Showcase")
		var expected := float(arena.cols) / float(arena.rows)
		assert_almost_eq(showcase.preview_source_aspect(), expected, 0.001)
		assert_almost_eq(showcase.preview_displayed_aspect(), expected, 0.001)


func test_loadout_showcase_keeps_selected_owned_and_locked_action_grammar() -> void:
	var selected := StoreShowcase.new()
	selected.configure_loadout(StoreShowcase.Kind.CHARACTER, &"pulse", "Pulse", "desc", true, true, true, 0)
	assert_eq(selected.state_label(), tr("STORE_SELECTED"))
	assert_eq(selected.action_text(), "")
	var owned := StoreShowcase.new()
	owned.configure_loadout(StoreShowcase.Kind.CHARACTER, &"drag", "Drag", "desc", true, false, true, 300)
	assert_eq(owned.action_text(), tr("STORE_SELECT"))
	assert_false(owned.action_disabled())
	var locked := StoreShowcase.new()
	locked.configure_loadout(StoreShowcase.Kind.ARENA, &"frost", "Frost", "desc", false, false, false, 700)
	assert_eq(locked.action_text(), tr("STORE_BUY"))
	assert_true(locked.action_disabled())
	selected.free()
	owned.free()
	locked.free()


func test_boost_showcase_uses_owned_count_without_equipped_state() -> void:
	var boost: BoostData = ContentCatalog.BOOSTS[0]
	var showcase := StoreShowcase.new()
	showcase.configure_boost(boost.id, boost, 2, false)
	assert_eq(showcase.state_label(), tr("STORE_OWNED") % 2)
	assert_eq(showcase.action_text(), tr("STORE_BUY"))
	assert_true(showcase.action_disabled())
	showcase.free()


func test_purchase_signal_refresh_waits_until_emitting_button_stack_returns() -> void:
	var store := _store()
	await _refresh_frame()
	store.set_category(store.Category.BOOSTS)
	await _refresh_frame()
	var showcase: Control = store.get_node("Scroll/List/Showcase")
	var emitting_button := Button.new()
	showcase.add_child(emitting_button)
	emitting_button.pressed.connect(func() -> void: Economy.currency_changed.emit(Economy.balance()))
	emitting_button.pressed.emit()
	assert_true(store._refresh_pending)
	await _refresh_frame()
	assert_false(store._refresh_pending)
	assert_not_null(store.get_node_or_null("Scroll/List/Showcase"))
	assert_eq(store.get_node("Scroll/List").get_child_count(), 2)
	assert_eq(store.get_node("Scroll/List/Selector").get_child_count(), 3)


func test_store_tabs_keep_existing_tr_and_en_localization() -> void:
	var store := _store()
	await _refresh_frame()
	TranslationServer.set_locale("tr")
	store.set_category(store.Category.CHARACTERS)
	await _refresh_frame()
	assert_eq(store.get_node("CategoryStrip/Tabs/Characters").text, "Karakterler")
	assert_eq(store.get_node("CategoryStrip/Tabs/Arenas").text, "Arenalar")
	assert_eq(store.get_node("CategoryStrip/Tabs/Boosts").text, "Boost'lar")
	TranslationServer.set_locale("en")
	store.set_category(store.Category.CHARACTERS)
	await _refresh_frame()
	assert_eq(store.get_node("CategoryStrip/Tabs/Characters").text, "Characters")
