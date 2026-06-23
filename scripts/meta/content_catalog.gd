class_name ContentCatalog
extends RefCounted

## Central registry of playable content (characters, arenas, mission pool), shared by
## game.gd, the store, and the menu so there is a single source of truth + id->index lookup.

const CHARACTERS: Array[CharacterData] = [
	preload("res://resources/characters/char_pulse.tres"),
	preload("res://resources/characters/char_drag.tres"),
	preload("res://resources/characters/char_halt.tres"),
]
const ARENAS: Array[ArenaData] = [
	preload("res://resources/arenas/arena_void.tres"),
	preload("res://resources/arenas/arena_ember.tres"),
	preload("res://resources/arenas/arena_frost.tres"),
]
const BOOSTS: Array[BoostData] = [
	preload("res://resources/boosts/extra_life.tres"),
	preload("res://resources/boosts/coin_bonus.tres"),
	preload("res://resources/boosts/slow_start.tres"),
]
const MISSIONS: Array[MissionDef] = [
	preload("res://resources/missions/m_score_800.tres"),
	preload("res://resources/missions/m_score_1000.tres"),
	preload("res://resources/missions/m_score_2500.tres"),
	preload("res://resources/missions/m_score_5000.tres"),
	preload("res://resources/missions/m_percent_50.tres"),
	preload("res://resources/missions/m_percent_80.tres"),
	preload("res://resources/missions/m_percent_95.tres"),
	preload("res://resources/missions/m_areas_8.tres"),
	preload("res://resources/missions/m_areas_12.tres"),
	preload("res://resources/missions/m_areas_30.tres"),
	preload("res://resources/missions/m_areas_50.tres"),
	preload("res://resources/missions/m_win_1.tres"),
	preload("res://resources/missions/m_win_2.tres"),
	preload("res://resources/missions/m_win_3.tres"),
]


## Index of the character with `id`, or 0 (default) if not found.
static func character_index(id: StringName) -> int:
	for i in CHARACTERS.size():
		if CHARACTERS[i].id == id:
			return i
	return 0


static func arena_index(id: StringName) -> int:
	for i in ARENAS.size():
		if ARENAS[i].id == id:
			return i
	return 0


## The BoostData with `id`, or null if not found.
static func boost_by_id(id: StringName) -> BoostData:
	for b in BOOSTS:
		if b.id == id:
			return b
	return null
