extends Node

## Manages global game session state: active run, lives, score, and game mode.
## Populated in Step 05 (score/combo/game loop).

signal game_started
signal game_over(final_score: int)
signal life_lost(lives_remaining: int)
