extends GutTest

## Full-year leaderboard dates (stored key remains ISO YYYYMMDD).

const LV = preload("res://scripts/ui/leaderboard_view.gd")


func before_each() -> void:
	TranslationServer.set_locale("en")


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_english_today_and_yesterday_keep_full_dates() -> void:
	assert_eq(LV.format_date(20260621), "Jun 21, 2026")
	assert_eq(LV.format_date(20260620), "Jun 20, 2026")


func test_english_same_and_previous_year() -> void:
	assert_eq(LV.format_date(20270622), "Jun 22, 2027")
	assert_eq(LV.format_date(20260622), "Jun 22, 2026")


func test_turkish_same_and_previous_year() -> void:
	TranslationServer.set_locale("tr")
	assert_eq(LV.format_date(20270622), "22 Haz 2027")
	assert_eq(LV.format_date(20260622), "22 Haz 2026")


func test_december_january_boundary_keeps_full_dates() -> void:
	assert_eq(LV.format_date(20261231), "Dec 31, 2026")
	assert_eq(LV.format_date(20270101), "Jan 1, 2027")
	TranslationServer.set_locale("tr")
	assert_eq(LV.format_date(20261231), "31 Ara 2026")
	assert_eq(LV.format_date(20270101), "1 Oca 2027")


func test_latin_display_templates_leave_canonical_date_and_seed_unchanged() -> void:
	var seed: int = DailySeed.seed_for_date(2026, 6, 22)
	var canonical: String = DailySeed.date_string(seed)
	for pair: Array in [["de", "22. Juni 2026"], ["fr", "22 juin 2026"], ["es", "22 jun 2026"], ["pt_BR", "22 jun. 2026"], ["it", "22 giu 2026"]]:
		TranslationServer.set_locale(pair[0])
		assert_eq(LV.format_date(20260622), pair[1])
		assert_eq(DailySeed.seed_for_date(2026, 6, 22), seed)
		assert_eq(DailySeed.date_string(seed), canonical)


func test_cjk_dates_keep_canonical_seed_and_date_keys() -> void:
	var seed: int = DailySeed.seed_for_date(2026, 6, 22)
	var canonical: String = DailySeed.date_string(seed)
	for pair: Array in [["ja", "2026年6月22日"], ["ko", "2026년 6월 22일"],
			["zh_Hans", "2026年6月22日"], ["zh_Hant", "2026年6月22日"]]:
		TranslationServer.set_locale(pair[0])
		assert_eq(LV.format_date(20260622), pair[1])
		assert_eq(DailySeed.seed_for_date(2026, 6, 22), seed)
		assert_eq(DailySeed.date_string(seed), canonical)


func test_b1_dates_keep_canonical_seed_and_date_keys() -> void:
	var seed: int = DailySeed.seed_for_date(2026, 6, 22)
	var canonical: String = DailySeed.date_string(seed)
	for pair: Array in [["ru", "22 июн. 2026"], ["id", "22 Jun 2026"],
			["vi", "22 thg 6, 2026"], ["pl", "22 cze 2026"]]:
		TranslationServer.set_locale(pair[0])
		assert_eq(LV.format_date(20260622), pair[1])
		assert_eq(DailySeed.seed_for_date(2026, 6, 22), seed)
		assert_eq(DailySeed.date_string(seed), canonical)
