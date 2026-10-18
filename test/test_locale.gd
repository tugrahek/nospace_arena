extends GutTest

## Step 22a: localization infrastructure. Catalog completeness (EN + TR columns full — the
## string-sweep watchdog), locale round-trip, visible missing-key fallback, the pure language
## resolver, and pins for the CSV comma-truncation fixes.

const LocaleUtil = preload("res://scripts/meta/locale_util.gd")
const CSV_PATH: String = "res://locale/translations.csv"


func after_each() -> void:
	TranslationServer.set_locale("en")  # never leak a locale change into other tests


## Parses the locale CSV with the engine's own quote/multiline-aware reader.
## Returns [header: PackedStringArray, rows: Array[PackedStringArray]].
func _read_csv() -> Array:
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(f, "locale CSV opens")
	var header: PackedStringArray = f.get_csv_line()
	var rows: Array = []
	while not f.eof_reached():
		var line: PackedStringArray = f.get_csv_line()
		if line.size() >= 1 and line[0].strip_edges() != "":
			rows.append(line)
	return [header, rows]


func test_catalog_en_and_tr_full() -> void:
	# Every key has BOTH an English and a Turkish cell (TR is complete, not a skeleton), and
	# every row has exactly the header's column count (no unquoted-comma truncation).
	var parsed: Array = _read_csv()
	var header: PackedStringArray = parsed[0]
	assert_eq(header.slice(1), PackedStringArray(LocaleUtil.SUPPORTED), "catalog matches shipped locales")
	var seen: Dictionary = {}
	for row in rows_of(parsed):
		assert_eq(row.size(), header.size(), "row '%s' has all locale cells (quote commas!)" % row[0])
		assert_false(seen.has(row[0]), "key '%s' is unique" % row[0])
		seen[row[0]] = true
		assert_true(row[1].strip_edges() != "", "EN cell of '%s' non-empty" % row[0])
		assert_true(row[2].strip_edges() != "", "TR cell of '%s' non-empty" % row[0])
		for column in range(3, header.size()):
			assert_false(row[column].strip_edges().is_empty(), "%s/%s is translated" % [row[0], header[column]])
	assert_gt(seen.size(), 100, "catalog has the full key set")


func rows_of(parsed: Array) -> Array:
	return parsed[1]


func test_locale_round_trip() -> void:
	TranslationServer.set_locale("tr")
	assert_eq(tr("MENU_PLAY"), "Oyna", "TR active -> Turkish text")
	assert_eq(tr("MENU_STORE"), "Mağaza", "TR Store title")
	assert_eq(tr("SETTINGS_BACK"), "Geri")
	TranslationServer.set_locale("en")
	assert_eq(tr("MENU_PLAY"), "Play", "back to EN")
	assert_eq(tr("MENU_STORE"), "Store", "EN Store title")


func test_unknown_key_returns_key() -> void:
	# Missing keys must stay VISIBLE (the key itself), never blank.
	assert_eq(tr("NO_SUCH_KEY_XYZ"), "NO_SUCH_KEY_XYZ")


func test_resolver_chain() -> void:
	assert_eq(LocaleUtil.resolve("tr", "en"), "tr", "explicit choice wins")
	assert_eq(LocaleUtil.resolve("", "tr"), "tr", "auto -> device language when supported")
	assert_eq(LocaleUtil.resolve("", "ar"), "en", "unsupported device -> English")
	assert_eq(LocaleUtil.resolve("xx", "tr"), "tr", "garbage saved value -> device chain")
	assert_eq(LocaleUtil.resolve("", ""), "en", "nothing known -> English")


func test_comma_fields_not_truncated() -> void:
	# Pins the quoting fix: these EN values used to be cut at their first comma by the CSV import.
	assert_string_contains(tr("HOWTO_GOAL_BODY"), "close a loop")
	assert_string_contains(tr("LEVEL_C12_DESC"), "no boosts")
	assert_string_contains(tr("ARENA_EMBER_DESC"), "kinder target")
	var months: PackedStringArray = tr("MONTHS_SHORT").split(",")
	assert_eq(months.size(), 12, "12 short month names survive quoting")


func test_full_device_locale_and_saved_preference() -> void:
	assert_eq(LocaleUtil.resolve("", "tr_TR"), "tr")
	assert_eq(LocaleUtil.resolve("", "en-GB"), "en")
	assert_eq(LocaleUtil.resolve("en", "tr_TR"), "en", "saved choice wins")
	assert_eq(LocaleUtil.resolve("tr", "ja_JP"), "tr")
	assert_eq(LocaleUtil.resolve("invalid", "tr_CY"), "tr")
	for unsupported: String in ["pt_PT", "ar", "hi_IN", "xx_YY", ""]:
		assert_eq(LocaleUtil.resolve("", unsupported), "en", "safe fallback: " + unsupported)
	assert_eq(LocaleUtil.SUPPORTED, ["en", "tr", "de", "fr", "es", "pt_BR", "it", "ja", "ko", "zh_Hans", "zh_Hant", "ru", "id", "vi", "pl"], "only translated locales ship")


func test_canonical_codes_preserve_script_and_region() -> void:
	assert_eq(LocaleUtil.normalize("pt-BR"), "pt_BR")
	assert_eq(LocaleUtil.normalize("zh-Hans"), "zh_Hans")
	assert_eq(LocaleUtil.normalize("zh-Hant-TW"), "zh_Hant_TW")
	assert_eq(LocaleUtil.normalize(" tr-TR "), "tr_TR")
	assert_eq(LocaleUtil.normalize(""), "")


func test_latin_device_variants_and_preference_priority() -> void:
	for pair: Array in [["de_DE", "de"], ["fr_CA", "fr"], ["es_MX", "es"], ["it_IT", "it"], ["pt-BR", "pt_BR"]]:
		assert_eq(LocaleUtil.resolve("", pair[0]), pair[1])
		assert_eq(LocaleUtil.resolve(pair[1], "tr_TR"), pair[1])
	assert_eq(LocaleUtil.resolve("", "pt_PT"), "en", "regional variants never cross")
	assert_eq(LocaleUtil.resolve("", "pt"), "en", "no unspecified Portuguese variant is selected")


func test_all_catalog_placeholders_and_imported_resources_match() -> void:
	var parsed: Array = _read_csv()
	var header: PackedStringArray = parsed[0]
	var pattern := RegEx.new()
	pattern.compile("%(?:%|[ds])")
	for row: PackedStringArray in parsed[1]:
		var reference: Array[String] = []
		for token: RegExMatch in pattern.search_all(row[1]):
			reference.append(token.get_string())
		for column in range(1, header.size()):
			var placeholders: Array[String] = []
			for token: RegExMatch in pattern.search_all(row[column]):
				placeholders.append(token.get_string())
			assert_eq(placeholders, reference, "%s/%s placeholder signature" % [row[0], header[column]])
			for field: String in ["{day}", "{month}", "{year}"]:
				assert_eq(row[column].count(field), row[1].count(field), "%s/%s named field %s" % [row[0], header[column], field])
	for column in range(1, header.size()):
		TranslationServer.set_locale(header[column])
		for row: PackedStringArray in parsed[1]:
			assert_eq(tr(row[0]), row[column].replace("\\n", "\n"), "%s/%s imported translation" % [row[0], header[column]])
		assert_eq(tr("MONTHS_SHORT").split(",").size(), 12)


func test_latin_catalog_glyphs_exist_in_all_game_fonts() -> void:
	var parsed: Array = _read_csv()
	var glyphs: Dictionary = {}
	for row: PackedStringArray in parsed[1]:
		for column in range(1, row.size()):
			if LocaleFonts.REGIONS.has(parsed[0][column]):
				continue
			for character: String in row[column]:
				if character.unicode_at(0) >= 32:
					glyphs[character] = true
	for path: String in ["res://assets/fonts/dynapuff/dynapuff-variable.ttf", "res://assets/fonts/rubik/rubik-variable.ttf", "res://assets/fonts/nunitosans/nunitosans-variable.ttf"]:
		var font: FontFile = load(path)
		for character: String in glyphs:
			assert_true(font.has_char(character.unicode_at(0)), "%s contains %s" % [path, character])


func test_future_catalog_variants_without_enabling_translations() -> void:
	var available: Array[String] = ["en", "tr", "pt_BR", "zh_Hans", "zh_Hant"]
	assert_eq(LocaleUtil.resolve("", "pt-BR", available), "pt_BR")
	assert_eq(LocaleUtil.resolve("", "pt_PT", available), "en", "no arbitrary regional match")
	assert_eq(LocaleUtil.resolve("", "zh_CN", available), "zh_Hans")
	assert_eq(LocaleUtil.resolve("", "zh_TW", available), "zh_Hant")
	assert_eq(LocaleUtil.resolve("", "zh_HK", available), "zh_Hant")
	assert_eq(LocaleUtil.resolve("", "zh_Hans_TW", available), "zh_Hans", "explicit script wins")
	assert_eq(LocaleUtil.resolve("zh_Hant", "zh_CN", available), "zh_Hant")
	assert_eq(LocaleUtil.resolve("pt_BR", "tr_TR", available), "pt_BR")
	assert_eq(LocaleUtil.resolve("", "zh_Hant_TW", ["en", "zh_Hans"]), "en", "no script crossover")


func test_cjk_device_variants_and_saved_preferences() -> void:
	for pair: Array in [["ja_JP", "ja"], ["ko_KR", "ko"], ["zh_CN", "zh_Hans"],
			["zh_SG", "zh_Hans"], ["zh_TW", "zh_Hant"], ["zh_HK", "zh_Hant"],
			["zh_MO", "zh_Hant"], ["zh_Hans_TW", "zh_Hans"], ["zh_Hant_CN", "zh_Hant"]]:
		assert_eq(LocaleUtil.resolve("", pair[0]), pair[1])
		assert_eq(LocaleUtil.resolve(pair[1], "en_US"), pair[1], "saved preference wins")
		var restored := AudioSettings.from_dict({"language": pair[0]})
		assert_eq(AudioSettings.from_dict(restored.to_dict()).language, pair[1])


func test_b1_device_variants_and_saved_preferences() -> void:
	for pair: Array in [["ru_RU", "ru"], ["ru_UA", "ru"], ["id_ID", "id"],
			["vi_VN", "vi"], ["pl_PL", "pl"]]:
		assert_eq(LocaleUtil.resolve("", pair[0]), pair[1])
		assert_eq(LocaleUtil.resolve(pair[1], "tr_TR"), pair[1], "saved preference wins")
		var restored := AudioSettings.from_dict({"language": pair[0]})
		assert_eq(AudioSettings.from_dict(restored.to_dict()).language, pair[1])


func test_b1_catalog_shapes_without_system_fonts() -> void:
	var parsed: Array = _read_csv()
	for locale: String in ["ru", "id", "vi", "pl"]:
		TranslationServer.set_locale(locale)
		await get_tree().process_frame
		var column: int = parsed[0].find(locale)
		for path: String in LocaleFonts.LATIN_PATHS:
			var font: Font = load(path)
			for row: PackedStringArray in parsed[1]:
				_assert_bundled_text(row[column].replace("\\n", "\n"), font, locale, row[0])
			_assert_bundled_text("0123456789 ◆◇ ×…−→★☆♥♡ %+-:.,/()", font, locale, "runtime symbols")


func test_cjk_catalog_uses_bundled_glyphs_and_correct_regional_faces() -> void:
	var parsed: Array = _read_csv()
	var server: TextServer = TextServerManager.get_primary_interface()
	for locale: String in LocaleFonts.REGIONS:
		var column: int = parsed[0].find(locale)
		TranslationServer.set_locale(locale)
		await get_tree().process_frame
		var expected: String = "NoSpace CJK %s Subset" % LocaleFonts.REGIONS[locale].to_upper()
		for path: String in LocaleFonts.LATIN_PATHS:
			var font: FontFile = load(path)
			var sample := TextLine.new()
			sample.add_string("語", font, 26, locale)
			var glyphs: Array[Dictionary] = server.shaped_text_get_glyphs(sample.get_rid())
			assert_eq(server.font_get_name(glyphs[0].font_rid), expected, "regional face: " + locale)
			_assert_bundled_text("0123456789 ◆◇ ×…−→★☆♥♡ %+-:.,/()", font, locale, "runtime symbols")
			for row: PackedStringArray in parsed[1]:
				_assert_bundled_text(row[column].replace("\\n", "\n"), font, locale, row[0])


func _assert_bundled_text(value: String, font: Font, locale: String, key: String) -> void:
	var text := TextLine.new()
	text.add_string(value, font, 26, locale)
	var server: TextServer = TextServerManager.get_primary_interface()
	var allowed: Array[RID] = font.get_rids()
	for glyph: Dictionary in server.shaped_text_get_glyphs(text.get_rid()):
		if value.unicode_at(glyph.start) > 32:
			assert_gt(int(glyph.index), 0, "%s/%s has a glyph" % [locale, key])
			assert_has(allowed, glyph.font_rid, "%s/%s needs no system font" % [locale, key])
