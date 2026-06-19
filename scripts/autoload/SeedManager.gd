extends Node

## Holds the daily deterministic seed for arena / character / enemy layout selection.
## The seed is derived from today's date (the only impure call); all derivation from it
## is pure (DailySeed). No class_name (autoload singleton).

const DailySeed = preload("res://scripts/meta/daily_seed.gd")
const EpochDay = preload("res://scripts/meta/epoch_day.gd")

signal daily_seed_ready(seed_value: int)

## Play modes. Stage progression (Step 18) belongs ONLY to LEVEL_ENDLESS; DAILY and FREE are
## single-arena. `is_daily` stays as a convenience mirror of (mode == DAILY).
enum Mode { DAILY, FREE, LEVEL_ENDLESS }

var daily_seed: int = 0
var is_daily: bool = false
var mode: int = Mode.FREE
var day_offset: int = 0  # DEV ONLY: preview other days' challenges (0 = real today)


## Computes the active day's seed (system date + dev day_offset). Impure point
## (system clock); the seed derivation from it stays pure (DailySeed).
func compute_today() -> int:
	var base: Dictionary = Time.get_date_dict_from_system()
	var unix: int = int(Time.get_unix_time_from_datetime_dict(base)) + day_offset * 86400
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return DailySeed.seed_for_date(d.year, d.month, d.day)


## Today's epoch-day (days since 1970-01-01), honoring the dev day_offset. Used by the
## login-streak so "consecutive day" math is correct (and dev-previewable via H).
func today_epoch() -> int:
	var base: Dictionary = Time.get_date_dict_from_system()
	var unix: int = int(Time.get_unix_time_from_datetime_dict(base)) + day_offset * 86400
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return EpochDay.from_date(d.year, d.month, d.day)


## DEV: advance to the next day's challenge (re-derives the seed). Real today = offset 0.
func advance_day() -> void:
	day_offset += 1
	daily_seed = compute_today()
	daily_seed_ready.emit(daily_seed)


func enter_daily() -> void:
	is_daily = true
	mode = Mode.DAILY
	daily_seed = compute_today()
	daily_seed_ready.emit(daily_seed)


func exit_daily() -> void:
	enter_free()


## Free play: single arena, player loadout, casual. No ghost/leaderboard.
func enter_free() -> void:
	is_daily = false
	mode = Mode.FREE


## Level-Endless: arenas cycle and escalate until death (Step 18). Personal score, no ghost.
func enter_level_endless() -> void:
	is_daily = false
	mode = Mode.LEVEL_ENDLESS


func toggle_daily() -> void:
	if is_daily:
		enter_free()
	else:
		enter_daily()
