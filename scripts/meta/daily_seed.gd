class_name DailySeed
extends RefCounted

## Pure deterministic seed helpers for the daily challenge (no RNG, no Godot RNG).
## Everything is masked to 32 bits at each step so results are identical across
## platforms/versions (no overflow or sign ambiguity) — critical for a shared daily
## arena + leaderboard (Step 11). Same date -> same seed -> same arena/character/dirs.

const MASK: int = 0xFFFFFFFF


## Date -> seed. Stable, human-readable (YYYYMMDD).
static func seed_for_date(year: int, month: int, day: int) -> int:
	return year * 10000 + month * 100 + day


## Deterministic 32-bit integer hash of (seed, salt). Bias-mixing finalizer.
static func derive(seed: int, salt: int) -> int:
	var h: int = ((seed & MASK) ^ ((salt * 0x9E3779B1) & MASK)) & MASK
	h = (h ^ (h >> 16)) & MASK
	h = (h * 0x45D9F3B) & MASK
	h = (h ^ (h >> 16)) & MASK
	h = (h * 0x45D9F3B) & MASK
	h = (h ^ (h >> 16)) & MASK
	return h


## Deterministic index in [0, count) for a salted draw. count <= 0 -> 0.
static func to_index(seed: int, salt: int, count: int) -> int:
	if count <= 0:
		return 0
	return derive(seed, salt) % count


## Deterministic initial direction index (0..3) for enemy `enemy_index`.
static func dir_index(seed: int, enemy_index: int) -> int:
	return to_index(seed, 0x100 + enemy_index, 4)


## Human-readable date for a YYYYMMDD seed (e.g. 20260616 -> "2026-06-16"). Pure.
static func date_string(seed: int) -> String:
	var y: int = seed / 10000
	var m: int = (seed / 100) % 100
	var d: int = seed % 100
	return "%04d-%02d-%02d" % [y, m, d]
