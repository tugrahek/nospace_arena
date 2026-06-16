extends Node

## Manages global game session state: active run, lives, score, combo, and game mode.
## No class_name (autoload singleton; Godot 4 forbids matching the singleton name).

const ScoreKeeperScript = preload("res://scripts/meta/score_keeper.gd")

signal game_started
signal game_over(final_score: int)
signal life_lost(lives_remaining: int)
signal run_won(final_score: int)
signal score_changed(score: int, combo: int)

enum Status { IDLE, PLAYING, GAME_OVER, WON }

var lives: int = 0
var status: int = Status.IDLE
var selected_character_index: int = 0  # survives scene reload; persistence is Step 11
var selected_arena_index: int = 0  # survives scene reload; Step 09 seed will drive this

var _scorer: ScoreKeeperScript = null


## Sets the active character index (clamped >= 0). Persists across runs/reload.
func set_character(index: int) -> void:
	selected_character_index = maxi(index, 0)


## Sets the active arena index (clamped >= 0). Persists across runs/reload.
func set_arena(index: int) -> void:
	selected_arena_index = maxi(index, 0)


## Starts a new run. Resets lives, score, and combo. Passes balance knobs to scorer.
func start_run(start_lives: int, base_points: int = 10, combo_window: float = 2.0) -> void:
	lives = maxi(start_lives, 0)
	status = Status.PLAYING
	_scorer = ScoreKeeperScript.new()
	_scorer.base_points = base_points
	_scorer.combo_window = combo_window
	game_started.emit()


## Records a capture. No-op unless PLAYING. Emits score_changed. Returns earned points.
func register_capture(cell_count: int, now: float) -> int:
	if status != Status.PLAYING:
		return 0
	var earned: int = _scorer.register_capture(cell_count, now)
	score_changed.emit(_scorer.score, _scorer.combo)
	return earned


## Transitions to WON state and emits run_won. No-op unless PLAYING.
func win_run() -> void:
	if status != Status.PLAYING:
		return
	status = Status.WON
	run_won.emit(_scorer.score if _scorer != null else 0)


## Decrements one life. Emits life_lost, and game_over when it reaches 0.
## No-op unless currently PLAYING. Returns the remaining lives.
func lose_life() -> int:
	if status != Status.PLAYING:
		return lives
	lives = maxi(lives - 1, 0)
	life_lost.emit(lives)
	if lives == 0:
		status = Status.GAME_OVER
		game_over.emit(_scorer.score if _scorer != null else 0)
	return lives


func get_score() -> int:
	return _scorer.score if _scorer != null else 0


func get_combo() -> int:
	return _scorer.combo if _scorer != null else 0


func is_playing() -> bool:
	return status == Status.PLAYING


func reset() -> void:
	lives = 0
	status = Status.IDLE
	_scorer = null
