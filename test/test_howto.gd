extends GutTest

## How-to-play carousel (4 visual pages, all control schemes, early-exit X) + data-driven
## content descriptions. Text/feel verified by Tuğra.

func test_pages_dots_nav_and_x() -> void:
	var v: Node = load("res://scenes/ui/HowToPlay.tscn").instantiate()
	add_child_autofree(v)
	await get_tree().process_frame
	assert_not_null(v.get_node("CloseButton"), "early-exit X present")
	assert_eq(v.get_node("Center/Dots").get_child_count(), 4, "4 page dots")
	assert_true(v.get_node("Center/GoalPage").visible, "page 0 visible")
	assert_false(v.get_node("Center/ControlsPage").visible)
	var prev: Button = v.get_node("Center/Nav/PrevButton")
	var next: Button = v.get_node("Center/Nav/NextButton")
	assert_false(prev.visible, "no Back on page 0")
	for i in 3:
		next.emit_signal("pressed")
	assert_eq(next.text, tr("HOWTO_DONE"), "last page -> Got it")
	assert_true(v.get_node("Center/LivesPage").visible, "last page is Lives")


func test_controls_page_lists_all_schemes() -> void:
	var v: Node = load("res://scenes/ui/HowToPlay.tscn").instantiate()
	add_child_autofree(v)
	await get_tree().process_frame
	var cp := v.get_node("Center/ControlsPage")
	assert_eq(cp.get_node("SwipeRow/Label").text, tr("HOWTO_CONTROLS_SWIPE"))
	assert_eq(cp.get_node("TapRow/Label").text, tr("HOWTO_CONTROLS_TAP"))
	assert_eq(cp.get_node("DpadRow/Label").text, tr("HOWTO_CONTROLS_DPAD"))


func test_content_descriptions_localized() -> void:
	for ch in ContentCatalog.CHARACTERS:
		assert_ne(ch.description_key, "", "char description_key set")
		assert_ne(tr(ch.description_key), ch.description_key, "char desc resolves")
	for ar in ContentCatalog.ARENAS:
		assert_ne(ar.description_key, "", "arena description_key set")
		assert_ne(tr(ar.description_key), ar.description_key, "arena desc resolves")


func test_howto_locale() -> void:
	assert_eq(tr("HOWTO_TITLE"), "How to Play")
	assert_eq(tr("CHAR_PULSE_DESC"), "Pushes enemies away from your territory")
