extends Node

## Manages global game session state: active run, lives, score, and game mode.
## Score/combo arrives in Step 05; Step 04 adds lives + game-over handling.
## No class_name (autoload singleton; Godot 4 forbids matching the singleton name).

signal game_started
signal game_over(final_score: int)
signal life_lost(lives_remaining: int)

enum Status { IDLE, PLAYING, GAME_OVER }

var lives: int = 0
var status: int = Status.IDLE


func start_run(start_lives: int) -> void:
	lives = maxi(start_lives, 0)
	status = Status.PLAYING
	game_started.emit()


## Decrements one life. Emits life_lost, and game_over when it reaches 0.
## No-op unless currently playing. Returns the remaining lives.
func lose_life() -> int:
	if status != Status.PLAYING:
		return lives
	lives = maxi(lives - 1, 0)
	life_lost.emit(lives)
	if lives == 0:
		status = Status.GAME_OVER
		game_over.emit(0)
	return lives


func is_playing() -> bool:
	return status == Status.PLAYING


func reset() -> void:
	lives = 0
	status = Status.IDLE
