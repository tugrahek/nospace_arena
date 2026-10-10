extends GutTest

## Focused E5 coverage: exported notice integrity, same-instance Settings return, and scrolling.
const SETTINGS: PackedScene = preload("res://scenes/ui/Settings.tscn")
const NOTICES: LegalNotices = preload("res://config/legal_notices.tres")


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_bundled_notices_preserve_full_source_license_texts() -> void:
	for folder: String in ["dynapuff", "rubik", "nunitosans"]:
		var source: String = FileAccess.get_file_as_string("res://assets/fonts/%s/OFL.txt" % folder)
		assert_true(NOTICES.font_notices.contains(source), "%s OFL remains verbatim" % folder)
	var text: String = NOTICES.build_text()
	assert_true(text.contains(Engine.get_license_text()), "Godot MIT text is sourced verbatim from the engine")
	assert_true(text.contains(FileAccess.get_file_as_string("res://addons/gut/LICENSE.md")), "shipped GUT keeps its MIT notice")
	assert_true(text.length() > NOTICES.font_notices.length(), "engine third-party notices are included")


func test_settings_legal_footer_localizes_and_returns_to_same_instance() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	add_child_autofree(viewport)
	var settings: Control = SETTINGS.instantiate() as Control
	settings.embedded = true
	viewport.add_child(settings)
	for locale: String in ["en", "tr"]:
		TranslationServer.set_locale(locale)
		settings._apply_texts()
		await get_tree().process_frame
		var copyright: String = "© 2026 Tuğra Hekimoğlu. All rights reserved." if locale == "en" else "© 2026 Tuğra Hekimoğlu. Tüm hakları saklıdır."
		assert_eq(settings.get_node("SafeArea/Bounds/Bottom/LegalFooter/Copyright").text, copyright)
		var entry: Button = settings.get_node("SafeArea/Bounds/Bottom/LegalFooter/LicensesButton") as Button
		assert_eq(entry.text, "Open-source licenses" if locale == "en" else "Açık kaynak lisansları")
		entry.pressed.emit()
		await get_tree().process_frame
		var legal: Control = settings.get("_legal_view") as Control
		assert_not_null(legal)
		assert_eq(legal.get_node("SafeArea/Bounds/Layout/Title").text, tr("LEGAL_TITLE"))
		var reader: RichTextLabel = legal.get_node("SafeArea/Bounds/Layout/Notices") as RichTextLabel
		assert_true(reader.scroll_active)
		assert_gt(reader.get_v_scroll_bar().max_value, reader.get_v_scroll_bar().page, "full notices naturally scroll")
		legal.get_node("SafeArea/Bounds/Layout/BackButton").pressed.emit()
		await get_tree().process_frame
		assert_null(settings.get("_legal_view"))
		assert_true(is_instance_valid(settings), "legal Back preserves embedded Settings")
	settings._open_legal()
	await get_tree().process_frame
	settings.close()
	await get_tree().process_frame
	assert_true(is_instance_valid(settings), "owner Back closes legal before closing embedded Settings")
