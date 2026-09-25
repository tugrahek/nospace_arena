class_name FreeCompletionPolicy
extends RefCounted

## Applies Free's explicit near-total goal without changing the shared ArenaData target
## used by Daily. Callers retain their own Campaign and Level-Endless target ownership.


static func target_for(mode: int, arena_target: float, free_completion_percent: float) -> float:
	return free_completion_percent if mode == SeedManager.Mode.FREE else arena_target


static func is_reached(raw_captured_percent: float, target: float) -> bool:
	return raw_captured_percent >= target
