extends GutTest

const EpochDay = preload("res://scripts/meta/epoch_day.gd")


func test_epoch_anchor() -> void:
	assert_eq(EpochDay.from_date(1970, 1, 1), 0, "epoch günü 0")
	assert_eq(EpochDay.from_date(1970, 1, 2), 1)
	assert_eq(EpochDay.from_date(1970, 2, 1), 31, "Ocak 31 gün")


func test_consecutive_diff_is_one() -> void:
	assert_eq(EpochDay.from_date(2026, 6, 18) - EpochDay.from_date(2026, 6, 17), 1)


func test_month_boundary() -> void:
	# 31 Ocak -> 1 Şubat ardışık (YYYYMMDD aritmetiği burada YANLIŞ olurdu)
	assert_eq(EpochDay.from_date(2026, 2, 1) - EpochDay.from_date(2026, 1, 31), 1)


func test_year_boundary() -> void:
	assert_eq(EpochDay.from_date(2027, 1, 1) - EpochDay.from_date(2026, 12, 31), 1)


func test_leap_year_february() -> void:
	# 2024 artık yıl: 28 Şub -> 29 Şub -> 1 Mar, her adım +1
	assert_eq(EpochDay.from_date(2024, 2, 29) - EpochDay.from_date(2024, 2, 28), 1)
	assert_eq(EpochDay.from_date(2024, 3, 1) - EpochDay.from_date(2024, 2, 29), 1)


func test_non_leap_february() -> void:
	# 2026 artık yıl DEĞİL: 28 Şub -> 1 Mar doğrudan ardışık (29 Şub yok)
	assert_eq(EpochDay.from_date(2026, 3, 1) - EpochDay.from_date(2026, 2, 28), 1)


func test_deterministic() -> void:
	assert_eq(EpochDay.from_date(2026, 6, 17), EpochDay.from_date(2026, 6, 17))
