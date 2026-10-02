extends GutTest

## View-only regressions for real score ordering, podium binding and today's marker.

const SCENE: PackedScene = preload("res://scenes/ui/Leaderboard.tscn")
const VIEW = preload("res://scripts/ui/leaderboard_view.gd")
const BOARD = preload("res://scripts/meta/leaderboard.gd")
const TRACK = preload("res://scripts/meta/ghost_track.gd")
const TODAY: int = 20261003


func before_each() -> void:
	TranslationServer.set_locale("en")


func after_each() -> void:
	TranslationServer.set_locale("en")


func _board() -> Leaderboard:
	var board: Leaderboard = BOARD.new()
	var track: GhostTrack = TRACK.new()
	board.submit(20260929, 270, track)
	board.submit(20261001, 820, track)
	board.submit(TODAY, 710, track)
	board.submit(20260930, 410, track)
	board.submit(20261002, 820, track)
	return board


func _page() -> Control:
	var page: Control = SCENE.instantiate()
	page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	page.size = Vector2(720.0, 1280.0)
	add_child_autofree(page)
	await get_tree().process_frame
	page.call("_render_leaderboard", _board(), TODAY)
	await get_tree().process_frame
	return page


func _label(entry: Control, name: String) -> Label:
	return entry.find_child(name, true, false) as Label


func test_real_order_top_three_and_score_date_binding() -> void:
	var page: Control = await _page()
	var list: VBoxContainer = page.get_node("Layout/Scroll/Content/List")
	assert_eq(list.get_child_count(), 5, "one view row per real daily score")
	var expected_scores: Array[int] = [820, 820, 710, 410, 270]
	var expected_dates: Array[int] = [20261002, 20261001, TODAY, 20260930, 20260929]
	for index in expected_scores.size():
		var entry: Control = list.get_child(index)
		assert_eq(entry.name, "Entry%d" % (index + 1))
		assert_eq(_label(entry, "Rank").text, "#%d" % (index + 1))
		assert_eq(_label(entry, "Date").text, VIEW.format_date(expected_dates[index]))
		assert_eq(_label(entry, "Score").text, str(expected_scores[index]))
	assert_true(list.get_child(0) is PanelContainer, "first place owns the single podium surface")
	for index in range(1, 5):
		assert_true(list.get_child(index) is HBoxContainer, "other rows stay flat")
	assert_true(_label(list.get_child(0), "Score").get_theme_font_size("font_size") > _label(list.get_child(3), "Score").get_theme_font_size("font_size"))
	assert_eq(page.get_node("Layout/Scroll/Content/AllBest").text, tr("LEADERBOARD_ALLBEST") % 820)


func test_today_marker_only_follows_actual_today_entry() -> void:
	var page: Control = await _page()
	var list: VBoxContainer = page.get_node("Layout/Scroll/Content/List")
	for index in 5:
		var marker: Node = list.get_child(index).find_child("TodayMarker", true, false)
		if index == 2:
			assert_not_null(marker, "third-place date is actually today")
		else:
			assert_null(marker, "no invented today marker")
	page.call("_render_leaderboard", _board(), 20261004)
	for entry: Node in list.get_children():
		assert_null(entry.find_child("TodayMarker", true, false), "no marker when today has no saved score")


func test_empty_board_does_not_invent_scores_or_record() -> void:
	var page: Control = await _page()
	page.call("_render_leaderboard", BOARD.new(), TODAY)
	assert_eq(page.get_node("Layout/Scroll/Content/List").get_child_count(), 0)
	assert_false(page.get_node("Layout/Scroll/Content/AllBest").visible)
	assert_true(page.get_node("EmptyLabel").visible)
	assert_eq(page.get_node("EmptyLabel").text, tr("LEADERBOARD_EMPTY"))


func test_english_turkish_binding_and_back_wiring() -> void:
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _page()
		var today_entry: Control = page.get_node("Layout/Scroll/Content/List/Entry3")
		assert_eq(page.get_node("Layout/Title").text, tr("LEADERBOARD_TITLE"))
		assert_eq(_label(today_entry, "Date").text, "Oct 3, 2026" if locale == "en" else "3 Eki 2026")
		assert_eq(page.get_node("Layout/Scroll/Content/AllBest").text, tr("LEADERBOARD_ALLBEST") % 820)
		var back: Button = page.get_node("Layout/BackButton")
		assert_eq(back.text, tr("SETTINGS_BACK"))
		assert_gt(back.pressed.get_connections().size(), 0, "Back remains connected")


func test_english_turkish_rows_fit_at_720x1280() -> void:
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _page()
		var scroll: ScrollContainer = page.get_node("Layout/Scroll")
		var list: VBoxContainer = page.get_node("Layout/Scroll/Content/List")
		var record: Label = page.get_node("Layout/Scroll/Content/AllBest")
		var back: Button = page.get_node("Layout/BackButton")
		assert_true(page.get_global_rect().encloses(back.get_global_rect()), "back inside %s" % locale)
		assert_true(scroll.get_global_rect().encloses(record.get_global_rect()), "record inside %s" % locale)
		for index in list.get_child_count():
			var entry: Control = list.get_child(index)
			var date_label: Label = _label(entry, "Date")
			var score_label: Label = _label(entry, "Score")
			assert_true(scroll.get_global_rect().encloses(entry.get_global_rect()), "row inside %s/%d" % [locale, index])
			assert_true(date_label.get_global_rect().end.x < score_label.get_global_rect().position.x, "date and score separate %s/%d" % [locale, index])
			if index > 0:
				assert_true(list.get_child(index - 1).get_global_rect().end.y <= entry.get_global_rect().position.y, "rows do not overlap %s/%d" % [locale, index])


func test_full_year_date_columns_fit_at_720x1280() -> void:
	for locale in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		var page: Control = await _page()
		var board: Leaderboard = BOARD.new()
		var track: GhostTrack = TRACK.new()
		board.submit(20270622, 7400, track)
		board.submit(20260622, 6400, track)
		page.call("_render_leaderboard", board, 20271003)
		await get_tree().process_frame
		for index in 2:
			var entry: Control = page.get_node("Layout/Scroll/Content/List/Entry%d" % (index + 1))
			var date_label: Label = _label(entry, "Date")
			var score_label: Label = _label(entry, "Score")
			var year: int = 2027 if index == 0 else 2026
			assert_eq(date_label.text, "Jun 22, %d" % year if locale == "en" else "22 Haz %d" % year)
			assert_true(date_label.size.x >= date_label.get_combined_minimum_size().x, "full date fits %s/%d" % [locale, index])
			assert_true(date_label.get_global_rect().end.x < score_label.get_global_rect().position.x, "date and score remain separate %s/%d" % [locale, index])
			assert_true(page.get_global_rect().encloses(score_label.get_global_rect()), "score stays on screen %s/%d" % [locale, index])
