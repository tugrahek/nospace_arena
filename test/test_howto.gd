extends GutTest

## Tutorial behavior, real container geometry and depicted gameplay semantics.

const SCENE: PackedScene = preload("res://scenes/ui/HowToPlay.tscn")
const BASE: String = "SafeMargin/MainVBox/"
const TITLES := [
	"HOWTO_GOAL_TITLE", "HOWTO_CONTROLS_TITLE", "HOWTO_ENEMIES_TITLE", "HOWTO_LIVES_TITLE",
]


func before_each() -> void:
	TranslationServer.set_locale("en")


func after_each() -> void:
	TranslationServer.set_locale("en")


func _make_tutorial() -> Control:
	var page: Control = SCENE.instantiate()
	page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	page.size = Vector2(720.0, 1280.0)
	add_child_autofree(page)
	await get_tree().process_frame
	await get_tree().process_frame
	return page


func test_four_page_order_back_next_and_final_action() -> void:
	var page: Control = await _make_tutorial()
	var title: Label = page.get_node(BASE + "PageTitle")
	var art: Control = page.get_node(BASE + "DemoCenter/PageArt")
	var progress: Control = page.get_node(BASE + "ProgressCenter/TutorialProgress")
	var back: Button = page.get_node(BASE + "NavigationRow/PrevButton")
	var next: Button = page.get_node(BASE + "NavigationRow/NextButton")
	assert_false(back.visible, "Back hidden on first page")
	for index in 4:
		assert_eq(title.text, tr(TITLES[index]), "page title %d" % index)
		assert_eq(art.page_mode, index, "art follows page %d" % index)
		assert_eq(progress.page_index, index, "indicator follows page %d" % index)
		assert_eq(next.text, tr("HOWTO_DONE") if index == 3 else tr("HOWTO_NEXT"))
		if index < 3:
			next.pressed.emit()
	assert_true(back.visible, "Back available on last page")
	back.pressed.emit()
	assert_eq(progress.page_index, 2, "Back returns to preceding page")
	assert_eq(title.text, tr("HOWTO_ENEMIES_TITLE"))
	assert_true(page.get_node("CloseButton").pressed.is_connected(Callable(page, "_exit")), "X stays wired")
	assert_true(next.pressed.is_connected(Callable(page, "_on_next")), "Next/Got it stays wired")


func test_all_four_pages_have_large_nonoverlapping_layout_at_720x1280() -> void:
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _make_tutorial()
		var art_positions: Array[float] = []
		var progress_positions: Array[float] = []
		var context: Control = page.get_node(BASE + "ContextLabel")
		var title: Control = page.get_node(BASE + "PageTitle")
		var art: Control = page.get_node(BASE + "DemoCenter/PageArt")
		var body: Control = page.get_node(BASE + "BodyCenter/BodyText")
		var progress: Control = page.get_node(BASE + "ProgressCenter/TutorialProgress")
		var nav: Control = page.get_node(BASE + "NavigationRow")
		for index in 4:
			page.call("_show", index)
			await get_tree().process_frame
			await get_tree().process_frame
			var label: String = "%s/%d" % [locale, index]
			assert_true(art.size.x >= 500.0 and art.size.y >= 300.0, "large art " + label)
			assert_true(art.visible and page.get_global_rect().encloses(art.get_global_rect()), "art inside screen " + label)
			art_positions.append(art.global_position.y)
			assert_true(art.get_arena_rect().size.x >= 450.0 and art.get_arena_rect().size.y >= 260.0, "large arena " + label)
			assert_true(progress.size.x >= 180.0, "progress width " + label)
			progress_positions.append(progress.global_position.y)
			assert_eq(progress.get_step_positions().size(), 4, "four track positions " + label)
			assert_true(progress.get_step_positions()[3].x - progress.get_step_positions()[0].x >= 170.0, "spread track " + label)
			assert_true(context.get_global_rect().end.y <= title.get_global_rect().position.y, "context before title " + label)
			assert_true(title.get_global_rect().end.y <= art.get_global_rect().position.y, "title before art " + label)
			assert_true(art.get_global_rect().end.y <= body.get_global_rect().position.y, "art before body " + label)
			assert_true(body.get_global_rect().end.y <= progress.get_global_rect().position.y, "body before progress " + label)
			assert_true(progress.get_global_rect().end.y <= nav.get_global_rect().position.y, "progress before nav " + label)
			assert_true(page.get_global_rect().encloses(nav.get_global_rect()), "nav inside screen " + label)
			assert_true(page.get_global_rect().encloses(body.get_global_rect()), "body inside screen " + label)
			assert_true(page.get_global_rect().encloses(page.get_node("CloseButton").get_global_rect()), "close inside screen " + label)
		assert_true(art_positions.max() - art_positions.min() < 35.0, "arena stays vertically stable " + locale)
		assert_true(progress_positions.max() - progress_positions.min() < 35.0, "progress stays vertically stable " + locale)


func test_page_art_depicts_all_required_mechanics() -> void:
	var page: Control = await _make_tutorial()
	var art: Control = page.get_node(BASE + "DemoCenter/PageArt")
	art.set_page_mode(0)
	var capture: Dictionary = art.get_composition()
	assert_true(capture["captured"].size() >= 2, "safe and captured territory")
	var new_region: Rect2 = capture["newly_captured"]
	assert_true(new_region.has_area() and capture["arena"].encloses(new_region), "new capture visibly fills an enclosed interior")
	assert_true(is_equal_approx(new_region.end.y, capture["captured"][0].position.y), "new capture reconnects to existing safe area")
	assert_true(capture["trail"].size() >= 4, "bending active trail")
	assert_eq(capture["reconnect"].size(), 2, "reconnection cue")
	assert_true(capture["arena"].has_point(capture["player"]), "player remains inside arena")
	art.set_page_mode(1)
	var movement: Dictionary = art.get_composition()
	assert_eq(movement["directions"].size(), 4, "four steering directions")
	assert_true(movement["trail"].size() >= 2, "movement path")
	art.set_page_mode(2)
	var threat: Dictionary = art.get_composition()
	var types: Array[StringName] = []
	for enemy: Dictionary in threat["enemies"]:
		types.append(enemy["type"])
	assert_eq(types, [&"bouncer", &"chaser", &"sparx"], "production enemy shapes")
	for first in threat["enemies"].size():
		var first_enemy: Dictionary = threat["enemies"][first]
		assert_true(threat["arena"].has_point(first_enemy["position"]), "enemy stays inside arena")
		for second in range(first + 1, threat["enemies"].size()):
			var second_enemy: Dictionary = threat["enemies"][second]
			assert_true(first_enemy["position"].distance_to(second_enemy["position"]) > 70.0, "enemy silhouettes do not overlap")
	assert_true(threat["captured"].size() > 0 and threat["trail"].size() > 0)
	art.set_page_mode(3)
	var lives: Dictionary = art.get_composition()
	assert_eq(lives["hearts"], 3, "life indicator")
	assert_eq(lives["enemies"].size(), 1, "enemy near vulnerable trail")
	assert_true(lives["captured"].size() > 0 and lives["trail"].size() > 0)


func test_turkish_and_english_content_resolve_in_shared_page() -> void:
	for locale in ["tr", "en"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _make_tutorial()
		var context: Label = page.get_node(BASE + "ContextLabel")
		var title: Label = page.get_node(BASE + "PageTitle")
		var body: Label = page.get_node(BASE + "BodyCenter/BodyText")
		assert_eq(context.text, tr("HOWTO_TITLE"), "context %s" % locale)
		for index in 4:
			page.call("_show", index)
			assert_eq(title.text, tr(TITLES[index]), "title %s/%d" % [locale, index])
			assert_ne(body.text, "", "body %s/%d" % [locale, index])
		page.call("_show", 1)
		for key in ["HOWTO_CONTROLS_SWIPE", "HOWTO_CONTROLS_TAP", "HOWTO_CONTROLS_DPAD", "HOWTO_CONTROLS_HINT"]:
			assert_string_contains(body.text, tr(key), "supported control %s" % locale)
		page.queue_free()
		await get_tree().process_frame


func test_content_descriptions_localized() -> void:
	for character in ContentCatalog.CHARACTERS:
		assert_ne(character.description_key, "")
		assert_ne(tr(character.description_key), character.description_key)
	for arena in ContentCatalog.ARENAS:
		assert_ne(arena.description_key, "")
		assert_ne(tr(arena.description_key), arena.description_key)
