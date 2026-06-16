class_name StasisEffect
extends "res://scripts/core/territory_effect.gd"

## Contact-triggered freeze: the moment an enemy bounces off player-captured
## territory it freezes in place for freeze_duration, then a freeze_cooldown blocks
## immediate re-freeze (so boundary jitter can't perma-lock it). No proximity field,
## no dwell — freezing happens ON CONTACT. Third axis: Push=heading, Drag=speed, Halt=time.
## Deterministic: the enemy's freeze timer counts down on the fixed physics step (no RNG).

@export var freeze_duration: float = 0.3
@export var freeze_cooldown: float = 0.5


func contact_freeze_duration() -> float:
	return freeze_duration


func contact_freeze_cooldown() -> float:
	return freeze_cooldown
