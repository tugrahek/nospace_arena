class_name HUD
extends CanvasLayer

## Heads-up display: lives, score, capture %, and combo during play.
## ResultPanel (win / lose) appears at run end with a retry button.

signal retry_pressed()

@onready var _lives_label: Label = $TopBar/LivesLabel
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _percent_label: Label = $TopBar/PercentLabel
@onready var _combo_label: Label = $ComboLabel
@onready var _daily_label: Label = $DailyLabel
@onready var _best_label: Label = $BestLabel
@onready var _currency_label: Label = $CurrencyLabel
@onready var _result_panel: Control = $ResultPanel
@onready var _result_title: Label = $ResultPanel/VBox/TitleLabel
@onready var _result_score: Label = $ResultPanel/VBox/ResultScore
@onready var _retry_button: Button = $ResultPanel/VBox/RetryButton


func _ready() -> void:
	GameState.game_started.connect(_on_game_started)
	GameState.life_lost.connect(_on_life_lost)
	GameState.score_changed.connect(_on_score_changed)
	GameState.game_over.connect(_on_game_over)
	GameState.run_won.connect(_on_run_won)
	Economy.currency_changed.connect(_on_currency_changed)
	_on_currency_changed(Economy.balance())  # DEV indicator (real currency UI Step 13/14)
	_result_panel.visible = false
	_combo_label.visible = false
	_daily_label.visible = false
	_best_label.visible = false
	_retry_button.pressed.connect(func() -> void: retry_pressed.emit())


## Shows/hides the daily-mode badge. Full daily UI (countdown etc.) is Step 14.
func set_daily(active: bool, seed: int) -> void:
	if active:
		_daily_label.text = tr("HUD_DAILY") + " • " + DailySeed.date_string(seed)
	_daily_label.visible = active


## Shows today's best score (daily only). score < 0 hides it.
func set_best(score: int) -> void:
	if score >= 0:
		_best_label.text = tr("HUD_BEST") + ": " + str(score)
		_best_label.visible = true
	else:
		_best_label.visible = false


## Called by game.gd after start_run to seed the initial display.
func setup(lives: int) -> void:
	_lives_label.text = tr("HUD_LIVES") + ": " + str(lives)
	_score_label.text = tr("HUD_SCORE") + ": 0"
	_percent_label.text = "0%"
	_combo_label.visible = false
	_result_panel.visible = false


func update_percent(percent: float) -> void:
	_percent_label.text = "%.0f%%" % percent


func _on_game_started() -> void:
	_result_panel.visible = false
	_combo_label.visible = false


func _on_life_lost(remaining: int) -> void:
	_lives_label.text = tr("HUD_LIVES") + ": " + str(remaining)


func _on_score_changed(score: int, combo: int) -> void:
	_score_label.text = tr("HUD_SCORE") + ": " + str(score)
	if combo > 0:
		_combo_label.text = tr("HUD_COMBO") + " x" + str(combo + 1)
		_combo_label.visible = true
	else:
		_combo_label.visible = false


func _on_game_over(final_score: int) -> void:
	_result_title.text = tr("RESULT_LOSE")
	_result_score.text = tr("HUD_SCORE") + ": " + str(final_score)
	_result_panel.visible = true


func _on_run_won(final_score: int) -> void:
	_result_title.text = tr("RESULT_WIN")
	_result_score.text = tr("HUD_SCORE") + ": " + str(final_score)
	_result_panel.visible = true


## DEV currency indicator (Step 13/14 replace with real currency UI).
func _on_currency_changed(balance: int) -> void:
	_currency_label.text = tr("HUD_CURRENCY") + ": " + str(balance)
