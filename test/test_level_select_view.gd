extends GutTest

## Presentation-only coverage for the authored Campaign route and node hierarchy.

const SCENE: PackedScene = preload("res://scenes/ui/LevelSelect.tscn")
const SAVE_DATA = preload("res://scripts/meta/save_data.gd")


func before_each() -> void:
	TranslationServer.set_locale("en")


func after_each() -> void:
	TranslationServer.set_locale("en")


func _page() -> Control:
	var page: Control = SCENE.instantiate()
	page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	page.size = Vector2(720.0, 1280.0)
	add_child_autofree(page)
	await get_tree().process_frame
	return page


func test_route_keeps_catalog_order_and_compact_checkpoint_bounds() -> void:
	var page: Control = await _page()
	var nodes: Array = page.get("_nodes")
	var canvas: Control = page.get_node("Center/Scroll/PathCanvas")
	assert_eq(nodes.size(), ContentCatalog.LEVELS.size(), "one node per authored level")
	assert_gt(canvas.custom_minimum_size.y, page.get_node("Center/Scroll").size.y, "campaign remains scrollable")
	for index in nodes.size():
		var node: Button = nodes[index]
		assert_almost_eq(node.size.x, float(page.get("NODE_W")), 0.01, "checkpoint width %d" % index)
		assert_almost_eq(node.size.y, float(page.get("NODE_H")), 0.01, "checkpoint height %d" % index)
		assert_lt(node.size.x, 100.0, "checkpoint remains compact %d" % index)
		assert_true(Rect2(Vector2.ZERO, canvas.custom_minimum_size).encloses(node.get_rect()), "node inside route canvas %d" % index)
		if index > 0:
			var previous: Button = nodes[index - 1]
			assert_gt(node.position.y, previous.position.y, "authored order stays top-to-bottom %d" % index)
			assert_ne(node.position.x, previous.position.x, "route keeps winding zigzag %d" % index)
		var metadata: Label = page.get_node("Center/Scroll/PathCanvas").get_child(index * 2)
		assert_true(metadata.text.contains(str(index + 1)), "metadata includes level number %d" % index)
		assert_eq(metadata.get_theme_font_size("font_size"), 21, "metadata remains readable %d" % index)
		assert_false(metadata.clip_text, "metadata is never truncated %d" % index)
		if not node.disabled:
			assert_true(metadata.text.length() > 0, "unlocked metadata is present %d" % index)


func test_state_styles_keep_frontier_completed_and_lock_hierarchy() -> void:
	var original_profile = Economy.get("_data")
	var profile = SAVE_DATA.new()
	profile.set_campaign_star(&"c01", 2)
	Economy.set("_data", profile)
	var page: Control = await _page()
	var nodes: Array = page.get("_nodes")
	var completed: Button = nodes[0]
	var frontier: Button = nodes[1]
	var locked: Button = nodes[2]
	var completed_style: StyleBoxFlat = completed.get_theme_stylebox("normal")
	var frontier_style: StyleBoxFlat = frontier.get_theme_stylebox("normal")
	assert_eq(completed_style.border_width_left, 1, "completed keeps the quiet checkpoint border")
	assert_lt(completed_style.bg_color.a, frontier_style.bg_color.a, "completed uses a muted captured fill")
	assert_gt(completed_style.bg_color.a, 0.3, "completed fill remains visibly captured")
	assert_eq(frontier_style.border_width_left, 2, "frontier has a restrained cyan outline")
	assert_true(locked.disabled, "locked state remains muted")
	var locked_style: StyleBoxFlat = locked.get_theme_stylebox("disabled")
	assert_eq(locked_style.border_width_left, 1, "locked has no extra cyan emphasis")
	Economy.set("_data", original_profile)


func test_playable_and_locked_nodes_keep_campaign_wiring() -> void:
	var original_profile = Economy.get("_data")
	var profile = SAVE_DATA.new()
	profile.set_campaign_star(&"c01", 2)
	Economy.set("_data", profile)
	var page: Control = await _page()
	var nodes: Array = page.get("_nodes")
	var completed: Button = nodes[0]
	var frontier: Button = nodes[1]
	var locked: Button = nodes[2]
	assert_false(completed.disabled, "cleared level remains playable")
	assert_false(frontier.disabled, "next campaign level is playable")
	assert_true(locked.disabled, "later locked level cannot start")
	assert_gt(frontier.pressed.get_connections().size(), 0, "playable node remains wired")
	assert_eq(page.get("GAME_SCENE"), "res://scenes/main/Game.tscn", "playable destination unchanged")
	assert_eq(page.get("MODE_SELECT_SCENE"), "res://scenes/ui/ModeSelect.tscn", "back destination unchanged")
	Economy.set("_data", original_profile)


func test_path_mapping_and_localization_smoke() -> void:
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _page()
		var canvas: Control = page.get_node("Center/Scroll/PathCanvas")
		var points: PackedVector2Array = canvas.get("_points")
		assert_eq(points.size(), ContentCatalog.LEVELS.size(), "path point per level %s" % locale)
		var half_size: Vector2 = canvas.get("_node_half_size")
		assert_gt(half_size.x, 0.0, "path trims before nodes %s" % locale)
		assert_gt(half_size.y, 0.0, "path trims before nodes %s" % locale)
		assert_eq(page.get_node("Center/Title").text, tr("LEVELSELECT_TITLE"), "localized title %s" % locale)
		assert_eq(page.get_node("Center/BackButton").text, tr("SETTINGS_BACK"), "localized back %s" % locale)


func test_unlocked_metadata_keeps_each_localized_description_and_final_level_clear_of_back() -> void:
	var original_profile = Economy.get("_data")
	var profile = SAVE_DATA.new()
	for index in ContentCatalog.LEVELS.size() - 1:
		profile.set_campaign_star(ContentCatalog.LEVELS[index].id, 1)
	Economy.set("_data", profile)
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _page()
		var canvas: Control = page.get_node("Center/Scroll/PathCanvas")
		for index in ContentCatalog.LEVELS.size():
			var metadata: Label = canvas.get_child(index * 2)
			assert_true(metadata.text.contains(tr(ContentCatalog.LEVELS[index].description_key)), "full localized objective %d %s" % [index, locale])
		var last: Button = page.get("_nodes")[ContentCatalog.LEVELS.size() - 1]
		assert_lte(last.get_rect().end.y + float(page.get("BOTTOM_PADDING")), canvas.custom_minimum_size.y, "final checkpoint has scroll-safe bottom padding %s" % locale)
		assert_false(page.get_node("Center/Scroll").get_global_rect().intersects(page.get_node("Center/BackButton").get_global_rect()), "scroll viewport stays above fixed back %s" % locale)
		var scroll: ScrollContainer = page.get_node("Center/Scroll")
		scroll.scroll_vertical = 99999
		await get_tree().process_frame
		assert_lte(last.get_global_rect().end.y, page.get_node("Center/BackButton").get_global_rect().position.y, "final checkpoint can scroll fully above back %s" % locale)
	Economy.set("_data", original_profile)
