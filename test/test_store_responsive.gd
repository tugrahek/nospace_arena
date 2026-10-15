extends GutTest

## Native Store bounds/state fixtures; purchase/equip intents are recorded without persistence.
const SCENE: PackedScene = preload("res://scenes/ui/Store.tscn")
const Store = preload("res://scripts/ui/store.gd")
const StoreShowcase = preload("res://scripts/ui/store_showcase.gd")
const FRAME: String = "SafeArea/Bounds/Frame"
const SIZES: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1440), Vector2i(720, 1560),
	Vector2i(720, 1600), Vector2i(720, 1680), Vector2i(960, 1280), Vector2i(640, 1280)]
var _original: Variant


class SimulatedSafeArea:
	extends SafeAreaMargin
	var platform_rect: Rect2


	func _get_display_safe_area() -> Rect2:
		return platform_rect


	func _get_local_to_display() -> Transform2D:
		return Transform2D.IDENTITY


class RecordingStore:
	extends "res://scripts/ui/store.gd"
	var purchases: Array[Dictionary] = []
	var selections: Array[Dictionary] = []


	func _on_buy(kind: String, id: StringName, cost: int) -> void:
		purchases.append({"kind": kind, "id": id, "cost": cost})


	func _on_select(kind: String, id: StringName) -> void:
		selections.append({"kind": kind, "id": id})


func before_each() -> void:
	_original = Economy._data
	_fixture(2)


func after_each() -> void:
	Economy._data = _original
	TranslationServer.set_locale("en")


func _fixture(state: int) -> void:
	var profile := SaveData.new_default()
	profile.currency = 0 if state == 3 else 5000
	if state == 1:
		profile.unlock("character", &"drag")
		profile.unlock("arena", &"ember")
		profile.add_boost(&"coin_bonus", 4)
	Economy._data = profile


func _mount(dimensions: Vector2i, insets: Vector4i, record: bool = false) -> Control:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var store: Control = SCENE.instantiate()
	if record:
		store.set_script(RecordingStore)
	var original: SafeAreaMargin = store.get_node("SafeArea")
	var safe := SimulatedSafeArea.new()
	safe.name = "ReplacementSafeArea"
	store.add_child(safe)
	safe.content_padding = original.content_padding
	safe.platform_rect = Rect2(Vector2(insets.x, insets.y),
		Vector2(dimensions) - Vector2(insets.x + insets.z, insets.y + insets.w))
	var bounds: Control = original.get_node("Bounds")
	bounds.owner = null
	original.remove_child(bounds)
	safe.add_child(bounds)
	store.remove_child(original)
	original.free()
	safe.name = "SafeArea"
	store.move_child(safe, 1)
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(store)
	await wait_process_frames(8)
	return store


func _safe_rect(store: Control) -> Rect2:
	var safe: SafeAreaMargin = store.get_node("SafeArea")
	var margin: Vector4i = safe.safe_insets() + safe.content_padding
	return Rect2(Vector2(margin.x, margin.y), store.size - Vector2(margin.x + margin.z, margin.y + margin.w))


func _inside(actual: Rect2, outer: Rect2, context: String) -> void:
	assert_true(actual.position.x >= outer.position.x - 0.1 and actual.position.y >= outer.position.y - 0.1
		and actual.end.x <= outer.end.x + 0.1 and actual.end.y <= outer.end.y + 0.1,
		"%s: %s within %s" % [context, actual, outer])


func test_all_ratios_locales_insets_and_three_categories() -> void:
	for dimensions: Vector2i in SIZES:
		for locale: String in ["en", "tr"]:
			TranslationServer.set_locale(locale)
			for insets: Vector4i in [Vector4i.ZERO, Vector4i(24, 96, 24, 48)]:
				var store: Control = await _mount(dimensions, insets)
				var profile: Dictionary = Economy._data.to_dict().duplicate(true)
				for category: int in [0, 1, 2]:
					store.set_category(category)
					await wait_process_frames(6)
					_check_shell(store)
					_check_content(store)
					for index: int in store.offer_count():
						store._on_focus_requested(index)
						await wait_process_frames(5)
						_check_content(store)
					assert_eq(Economy._data.to_dict(), profile, "category/item focus does not mutate profile")
				store.get_parent().free()


func _check_shell(store: Control) -> void:
	var title: Label = store.get_node(FRAME + "/Header/Title")
	assert_almost_eq(title.get_global_rect().get_center().x, _safe_rect(store).get_center().x, 0.5, "Store title stays centered independently of balance within pixel rounding")
	assert_lte(title.get_minimum_size().x, title.size.x + 0.1, "Store title fits beside balance")
	assert_false(title.get_global_rect().intersects(store._coins.get_global_rect()), "header labels do not overlap")
	for path: String in ["Header", "Header/Title", "Header/Coins", "CategoryStrip", "Scroll", "BackButton"]:
		_inside(store.get_node(FRAME + "/" + path).get_global_rect(), _safe_rect(store), path)
	for tab: Button in store._tabs:
		_inside(tab.get_global_rect(), _safe_rect(store), "tab")
		assert_gte(tab.size.x * 320.0 / 720.0, 48.0)
		assert_gte(tab.size.y * 320.0 / 720.0, 48.0)
		assert_lte(tab.get_minimum_size().x, tab.size.x + 0.1)
	_inside(store._frontier.get_global_rect(), store._strip.get_global_rect(), "frontier")
	assert_lte(store._frame.size.x, 800.0)
	assert_false(store._scroll.get_global_rect().intersects(store._back.get_global_rect()))
	assert_eq(store.get_node("Background").size, store.size)


func _check_content(store: Control) -> void:
	var list: VBoxContainer = store._list
	var showcase: StoreShowcase = list.get_node("Showcase")
	var outer := Rect2(list.global_position, list.size)
	_inside(showcase.get_global_rect(), outer, "showcase")
	for path: String in ["Name", "Description"]:
		var label: Label = showcase.get_node(path)
		_inside(label.get_global_rect(), showcase.get_global_rect(), path)
		assert_lte(label.get_minimum_size().y, label.size.y + 0.1)
	if showcase._action != null:
		_inside(showcase._action.get_global_rect(), showcase.get_global_rect(), "action")
		assert_gte(showcase._action.size.y * 320.0 / 720.0, 48.0)
	if showcase.kind == StoreShowcase.Kind.BOOST:
		_inside(showcase.get_node("Actions/Price").get_global_rect(), showcase.get_global_rect(), "boost price")
	for tile: StoreOfferTile in store._selector.get_children():
		_inside(tile.get_global_rect(), outer, "selector tile")
		var label: Label = tile.get_node("Content/Label")
		_inside(label.get_global_rect(), tile.get_global_rect(), "selector label")
		assert_lte(label.get_minimum_size().y, label.size.y + 0.1)
		assert_gte(tile.size.x * 320.0 / 720.0, 48.0)
		assert_eq(tile.get_node("HitTarget").size, tile.size)


func test_states_purchase_and_equip_dispatch_without_inventory_mutation() -> void:
	for category: int in [0, 1, 2]:
		for state: int in [0, 1, 2, 3]:
			_fixture(state)
			var store: RecordingStore = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48), true)
			store.set_category(category)
			store._focused_indices[category] = 0 if state == 0 else 1
			await wait_process_frames(6)
			_check_shell(store)
			_check_content(store)
			var profile: Dictionary = Economy._data.to_dict().duplicate(true)
			var showcase: StoreShowcase = store._list.get_node("Showcase")
			if category == 2:
				assert_true(showcase.get_node("Actions/Price").text.contains(str(ContentCatalog.BOOSTS[store.focused_index()].cost)))
			if category != 2 and state == 0:
				assert_eq(showcase.state_label(), tr("STORE_SELECTED"))
				assert_null(showcase._action)
			else:
				assert_eq(showcase.action_disabled(), state == 3)
				if state != 3:
					showcase._action.pressed.emit()
					if category != 2 and state == 1:
						assert_eq(store.selections.size(), 1)
					else:
						assert_eq(store.purchases.size(), 1)
						var cost: int = ContentCatalog.BOOSTS[store.focused_index()].cost if category == 2 else \
							ContentCatalog.CHARACTERS[store.focused_index()].unlock_cost if category == 0 else \
							ContentCatalog.ARENAS[store.focused_index()].unlock_cost
						assert_eq(store.purchases[0]["cost"], cost)
			assert_eq(Economy._data.to_dict(), profile)
			store.get_parent().free()


func test_final_selector_and_action_can_scroll_above_back_on_all_ratios() -> void:
	for dimensions: Vector2i in SIZES:
		var store: Control = await _mount(dimensions, Vector4i(24, 96, 24, 48))
		for category: int in [0, 1, 2]:
			store.set_category(category)
			store._focused_indices[category] = 2
			await wait_process_frames(6)
			var showcase: StoreShowcase = store._list.get_node("Showcase")
			store._scroll.ensure_control_visible(showcase._action)
			await wait_process_frames(2)
			_inside(showcase._action.get_global_rect(), store._scroll.get_global_rect(), "last offer action")
			var last: StoreOfferTile = store._selector.get_child(2)
			store._scroll.ensure_control_visible(last)
			await wait_process_frames(2)
			_inside(last.get_global_rect(), store._scroll.get_global_rect(), "final selector")
		store.get_parent().free()


func test_long_balance_and_long_selector_text_reflow() -> void:
	Economy._data.currency = 999999999
	for locale: String in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var store: Control = await _mount(Vector2i(720, 1280), Vector4i(24, 96, 24, 48))
		_check_shell(store)
		assert_true(store._coins.text.contains("999999999"))
		var showcase: StoreShowcase = store._list.get_node("Showcase")
		showcase.get_node("Name").text = "A deliberately long localized showcase item name"
		showcase.get_node("Description").text = "A longer localized item description with several words and complete readable details. ".repeat(4)
		var tile: StoreOfferTile = store._selector.get_child(2)
		tile.get_node("Content/Label").text = "A deliberately long localized item name with several words"
		await wait_process_frames(8)
		_check_content(store)
		assert_lte(tile.get_node("Content/Label").get_minimum_size().y, tile.get_node("Content/Label").size.y)
		store.get_parent().free()


func test_supply_tab_routes_to_existing_embedded_view_and_returns() -> void:
	var store: Control = await _mount(Vector2i(720, 1280), Vector4i.ZERO)
	store._tabs[3].pressed.emit()
	await wait_process_frames(6)
	assert_eq(store.active_category(), 3)
	assert_true(store._supply.embedded)
	assert_true(store._supply.visible)
	store._tabs[0].pressed.emit()
	await wait_process_frames(6)
	assert_eq(store.offer_count(), 3)
	assert_eq(store.MENU_SCENE, "res://scenes/main/MainMenu.tscn")
	assert_eq(store._back.pressed.get_connections().size(), 1)


func test_three_category_selectors_share_bottom_position() -> void:
	for dimensions: Vector2i in [Vector2i(720, 1280), Vector2i(720, 1600)]:
		for locale: String in ["tr", "en"]:
			TranslationServer.set_locale(locale)
			var store: Control = await _mount(dimensions, Vector4i(24, 96, 24, 48))
			var positions: Array[float] = []
			var hero_positions: Array[float] = []
			for category: int in 3:
				store.set_category(category)
				await wait_process_frames(8)
				positions.append(store._selector.global_position.y)
				_inside(store._selector.get_global_rect(), store._scroll.get_global_rect(), "selector accessible")
				assert_almost_eq(store._selector.get_global_rect().end.y,
					store._scroll.get_global_rect().end.y, 0.5)
				var showcase: StoreShowcase = store._list.get_node("Showcase")
				if category == Store.Category.BOOSTS:
					assert_almost_eq(showcase._preview.optical_offset_y, -15.0, 0.01,
						"Boost showcase icon receives the optical drawing offset")
					assert_almost_eq(showcase._preview.visual_scale, 1.08, 0.01,
						"Boost showcase icon draws slightly larger without changing its layout box")
				hero_positions.append(showcase._visual.global_position.y)
				assert_almost_eq(store._selector.global_position.y - showcase.get_global_rect().end.y,
					float(store._list.get_theme_constant("separation")), 0.5,
					"showcase and selector retain one consistent container gap")
			assert_almost_eq(positions.max(), positions.min(), 0.5, "all category rails align")
			assert_almost_eq(hero_positions[Store.Category.BOOSTS], hero_positions[Store.Category.CHARACTERS],
				0.5, "Boost hero aligns with Character hero")
			assert_almost_eq(hero_positions[Store.Category.ARENAS], hero_positions[Store.Category.CHARACTERS],
				4.0, "Arena hero retains its existing near-aligned hero position")
			store.get_parent().free()


func test_embedded_supply_uses_one_scroll_and_keeps_footer_actions_reachable() -> void:
	for dimensions: Vector2i in [Vector2i(720, 960), Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(640, 1280), Vector2i(960, 1280)]:
		for locale: String in ["tr", "en"]:
			TranslationServer.set_locale(locale)
			var store: Control = await _mount(dimensions, Vector4i(24, 96, 24, 48))
			var profile: Dictionary = Economy._data.to_dict().duplicate(true)
			store.set_category(3)
			await wait_process_frames(8)
			_check_shell(store)
			assert_eq(store._scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
			_inside(store._supply.get_global_rect(), store._scroll.get_global_rect(), "Supply fits Store host")
			var popup: SupplyPopup = store._supply
			var inner: ScrollContainer = popup.get_node("SafeArea/Bounds/Frame/Surface/Scroll")
			inner.ensure_control_visible(popup._coin)
			await wait_process_frames(2)
			_inside(popup._coin.get_global_rect(), inner.get_global_rect(), "coin action reachable")
			_inside(popup._odds.get_global_rect(), store._scroll.get_global_rect(), "odds footer")
			popup.show_odds()
			await wait_process_frames(3)
			_inside(popup.get_node("SafeArea/Bounds/Frame/OddsView/Footer").get_global_rect(), store._scroll.get_global_rect(), "odds Back footer")
			popup.state = SupplyPopup.State.REVEAL
			popup.refresh()
			await wait_process_frames(3)
			_inside(popup._continue.get_global_rect(), store._scroll.get_global_rect(), "reveal Continue footer")
			assert_eq(Economy._data.to_dict(), profile)
			store.set_category(0)
			await wait_process_frames(3)
			assert_eq(store._scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO)
			store.get_parent().free()
