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
