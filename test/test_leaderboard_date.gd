extends GutTest

## Friendly date formatting for the leaderboard (display only; stored key stays ISO YYYYMMDD).

const LV = preload("res://scripts/ui/leaderboard_view.gd")


func test_today() -> void:
	assert_eq(LV.format_date(20260621, 20260621), "Today")


func test_yesterday() -> void:
	assert_eq(LV.format_date(20260620, 20260621), "Yesterday")


func test_yesterday_across_month_boundary() -> void:
	assert_eq(LV.format_date(20260531, 20260601), "Yesterday")


func test_same_year_short() -> void:
	assert_eq(LV.format_date(20260619, 20260621), "Jun 19")


func test_other_year_includes_year() -> void:
	assert_eq(LV.format_date(20250619, 20260621), "Jun 19, 2025")


func test_january_month_name() -> void:
	assert_eq(LV.format_date(20260103, 20260621), "Jan 3")
