class_name EpochDay
extends RefCounted

## Pure date -> day-count since the Unix epoch (1970-01-01 = 0), proleptic Gregorian.
## Used for STREAK math where "consecutive day" must be correct across month/year/leap
## boundaries (YYYYMMDD arithmetic would be wrong). Deterministic, GUT-testable.
## (DailySeed's YYYYMMDD is for selection; this is a separate concern for adjacency.)


## Days from 1970-01-01 (Howard Hinnant's days_from_civil). Valid for modern dates.
static func from_date(year: int, month: int, day: int) -> int:
	var y: int = year - (1 if month <= 2 else 0)
	var era: int = (y if y >= 0 else y - 399) / 400
	var yoe: int = y - era * 400  # [0, 399]
	var doy: int = (153 * (month + (-3 if month > 2 else 9)) + 2) / 5 + day - 1  # [0, 365]
	var doe: int = yoe * 365 + yoe / 4 - yoe / 100 + doy  # [0, 146096]
	return era * 146097 + doe - 719468
