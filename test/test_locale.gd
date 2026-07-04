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
	assert_eq(header.size(), 3, "columns: keys,en,tr")
	var seen: Dictionary = {}
	for row in rows_of(parsed):
		assert_eq(row.size(), 3, "row '%s' has exactly 3 cells (quote commas!)" % row[0])
		assert_false(seen.has(row[0]), "key '%s' is unique" % row[0])
		seen[row[0]] = true
		assert_true(row[1].strip_edges() != "", "EN cell of '%s' non-empty" % row[0])
		assert_true(row[2].strip_edges() != "", "TR cell of '%s' non-empty" % row[0])
	assert_gt(seen.size(), 100, "catalog has the full key set")


func rows_of(parsed: Array) -> Array:
	return parsed[1]


func test_locale_round_trip() -> void:
	TranslationServer.set_locale("tr")
	assert_eq(tr("MENU_PLAY"), "Oyna", "TR active -> Turkish text")
	assert_eq(tr("SETTINGS_BACK"), "Geri")
	TranslationServer.set_locale("en")
	assert_eq(tr("MENU_PLAY"), "Play", "back to EN")


func test_unknown_key_returns_key() -> void:
	# Missing keys must stay VISIBLE (the key itself), never blank.
	assert_eq(tr("NO_SUCH_KEY_XYZ"), "NO_SUCH_KEY_XYZ")


func test_resolver_chain() -> void:
	assert_eq(LocaleUtil.resolve("tr", "en"), "tr", "explicit choice wins")
	assert_eq(LocaleUtil.resolve("", "tr"), "tr", "auto -> device language when supported")
	assert_eq(LocaleUtil.resolve("", "ja"), "en", "unsupported device -> English")
	assert_eq(LocaleUtil.resolve("xx", "tr"), "tr", "garbage saved value -> device chain")
	assert_eq(LocaleUtil.resolve("", ""), "en", "nothing known -> English")


func test_comma_fields_not_truncated() -> void:
	# Pins the quoting fix: these EN values used to be cut at their first comma by the CSV import.
	assert_string_contains(tr("HOWTO_GOAL_BODY"), "close a loop")
	assert_string_contains(tr("LEVEL_C12_DESC"), "no boosts")
	assert_string_contains(tr("ARENA_EMBER_DESC"), "kinder target")
	var months: PackedStringArray = tr("MONTHS_SHORT").split(",")
	assert_eq(months.size(), 12, "12 short month names survive quoting")
