class_name HUD
extends CanvasLayer

## Heads-up display: lives, score, capture %, and combo during play.
## ResultPanel (win / lose) appears at run end with a retry button.

signal retry_pressed()
signal menu_pressed()
signal next_pressed()  # Campaign: advance to the next level from the win screen

## Scale the score label punches to on each capture, then settles back to 1.0 (@export feel).
@export var score_punch: float = 1.3
# Feel-pass knobs (visual only):
@export var near_target_ratio: float = 0.9   # percent label turns accent + pulses past this share of the target
@export var result_pop_time: float = 0.2     # result panel scale-in duration
@export var star_stagger: float = 0.15       # delay between campaign star reveals
@export var star_punch: float = 1.5          # stars label scale punch per revealed star
# Combo escalation (feel P1-12, visual only): bigger chains punch harder and warm accent -> gold.
@export var combo_punch_base: float = 1.25   # combo label punch at x2
@export var combo_punch_step: float = 0.12   # extra punch per multiplier above x2
@export var combo_punch_max: float = 1.8     # punch ceiling
@export var combo_heat_start: int = 3        # multiplier where the gold shift begins
@export var combo_heat_full: int = 5         # multiplier that is fully gold

const PALETTE: PaletteData = preload("res://config/palette.tres")

var _score_tween: Tween = null
var _target: float = 75.0                    # stage/level capture target (display only)
var _percent_tween: Tween = null
var _near_target_hot: bool = false
var _combo_tween: Tween = null
var _last_combo: int = 0                     # punch only when the chain actually grows

@onready var _hearts: HeartsHud = $TopBar/Hearts
@onready var _stage_banner: Label = $StageBanner
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _percent_label: Label = $TopBar/PercentLabel
@onready var _combo_label: Label = $ComboLabel
@onready var _daily_label: Label = $DailyLabel
@onready var _best_label: Label = $BestLabel
@onready var _currency_label: Label = $CurrencyLabel
@onready var _mission_label: Label = $MissionLabel
@onready var _result_panel: Control = $ResultPanel
@onready var _result_title: Label = $ResultPanel/VBox/TitleLabel
@onready var _result_score: Label = $ResultPanel/VBox/ResultScore
@onready var _stars_label: Label = $ResultPanel/VBox/StarsLabel
@onready var _new_best_label: Label = $ResultPanel/VBox/NewBestLabel
@onready var _next_button: Button = $ResultPanel/VBox/NextButton
@onready var _retry_button: Button = $ResultPanel/VBox/ButtonRow/RetryButton
@onready var _menu_button: Button = $ResultPanel/VBox/ButtonRow/MenuButton


func _ready() -> void:
	GameState.game_started.connect(_on_game_started)
	GameState.life_lost.connect(_on_life_lost)
	GameState.score_changed.connect(_on_score_changed)
	GameState.game_over.connect(_on_game_over)
	GameState.run_won.connect(_on_run_won)
	Economy.currency_changed.connect(_on_currency_changed)
	_on_currency_changed(Economy.balance())  # seed the coins readout
	_result_panel.visible = false
	_combo_label.visible = false
	_daily_label.visible = false
	_best_label.visible = false
	_retry_button.text = tr("RESULT_RETRY")
	_menu_button.text = tr("RESULT_MENU")
	_next_button.text = tr("RESULT_NEXT")
	_new_best_label.text = tr("RESULT_NEW_BEST")
	_retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	_menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	_next_button.pressed.connect(func() -> void: next_pressed.emit())


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
	_hearts.set_max(lives)
	_score_label.text = tr("HUD_SCORE") + ": 0"
	_percent_label.text = "0%"
	_combo_label.visible = false
	_result_panel.visible = false
	_stars_label.visible = false
	_new_best_label.visible = false
	_next_button.visible = false
	_stage_banner.visible = false


## The capture target for the current stage/level — shown next to the live percent so the
## goal is always on screen ("62 / 75%"). Called by game.gd whenever a stage/level starts.
func set_target(target: float) -> void:
	_target = target
	_near_target_hot = false
	_percent_label.remove_theme_color_override("font_color")


func update_percent(percent: float) -> void:
	_percent_label.text = "%.0f / %.0f%%" % [percent, _target]
	# Closing in on the goal: accent color + a small pulse per update (tension cue).
	var hot: bool = _target > 0.0 and percent >= _target * near_target_ratio
	if hot:
		_percent_label.add_theme_color_override("font_color", PALETTE.accent)
		if _percent_tween != null and _percent_tween.is_running():
			_percent_tween.kill()
		_percent_label.pivot_offset = _percent_label.size * 0.5
		_percent_label.scale = Vector2.ONE * 1.15
		_percent_tween = _percent_label.create_tween()
		_percent_tween.tween_property(_percent_label, "scale", Vector2.ONE, 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif _near_target_hot:
		_percent_label.remove_theme_color_override("font_color")
	_near_target_hot = hot


## Stage-clear flourish (Level-Endless): "Stage N" banner scales in, holds, then fades out.
func show_stage_banner(stage_number: int) -> void:
	_stage_banner.text = tr("HUD_STAGE") % stage_number
	_stage_banner.visible = true
	_stage_banner.pivot_offset = _stage_banner.size * 0.5
	_stage_banner.scale = Vector2(0.6, 0.6)
	_stage_banner.modulate.a = 0.0
	var t: Tween = create_tween()
	t.tween_property(_stage_banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_stage_banner, "modulate:a", 1.0, 0.18)
	t.tween_interval(0.45)
	t.tween_property(_stage_banner, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: _stage_banner.visible = false)


func _on_game_started() -> void:
	_result_panel.visible = false
	_combo_label.visible = false


func _on_life_lost(remaining: int) -> void:
	_hearts.set_current(remaining)  # lost heart fades to a dim slot (+ punch)


func _on_score_changed(score: int, combo: int) -> void:
	_score_label.text = tr("HUD_SCORE") + ": " + str(score)
	_punch_score()
	if combo > 0:
		_combo_label.text = tr("HUD_COMBO") + " x" + str(combo + 1)
		_combo_label.visible = true
		if combo > _last_combo:
			_punch_combo(combo + 1)
	else:
		_combo_label.visible = false
	_last_combo = combo


## Combo escalation: punch grows with the multiplier and the label warms accent -> gold from
## combo_heat_start. Visual only (the multiplier itself comes from ScoreKeeper).
func _punch_combo(mult: int) -> void:
	var heat: float = JuiceMath.combo_heat(mult, combo_heat_start, combo_heat_full)
	_combo_label.add_theme_color_override("font_color", PALETTE.accent.lerp(PALETTE.coin, heat))
	if _combo_tween != null and _combo_tween.is_running():
		_combo_tween.kill()
	_combo_label.pivot_offset = _combo_label.size * 0.5
	_combo_label.scale = Vector2.ONE * JuiceMath.combo_punch(mult, combo_punch_base, combo_punch_step, combo_punch_max)
	_combo_tween = _combo_label.create_tween()
	_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A quick scale punch on the score label (settles back to 1.0). Pivot is re-centered each
## time because the label resizes as the score grows.
func _punch_score() -> void:
	if _score_tween != null and _score_tween.is_running():
		_score_tween.kill()
	_score_label.pivot_offset = _score_label.size * 0.5
	_score_label.scale = Vector2.ONE * score_punch
	_score_tween = _score_label.create_tween()
	_score_tween.tween_property(_score_label, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_game_over(final_score: int) -> void:
	_result_title.text = tr("RESULT_LOSE")
	_result_title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))  # danger (soft)
	_result_score.text = tr("HUD_SCORE") + ": " + str(final_score)
	_show_result_panel()


func _on_run_won(final_score: int) -> void:
	_result_title.text = tr("RESULT_WIN")
	_result_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55, 1.0))  # success
	_result_score.text = tr("HUD_SCORE") + ": " + str(final_score)
	_show_result_panel()


## Result entrance: quick scale-in + fade instead of popping into existence.
func _show_result_panel() -> void:
	_result_panel.visible = true
	_result_panel.pivot_offset = _result_panel.size * 0.5
	_result_panel.scale = Vector2.ONE * 0.9
	_result_panel.modulate.a = 0.0
	var t: Tween = _result_panel.create_tween().set_parallel(true)
	t.tween_property(_result_panel, "scale", Vector2.ONE, result_pop_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_result_panel, "modulate:a", 1.0, result_pop_time * 0.75)


## Campaign win: reveal the earned stars ONE BY ONE (staggered punch + sfx hook), then pop the
## "new best" tag last. Called by game.gd after recording the result. Visual only.
func show_campaign_stars(stars: int, improved: bool, has_next: bool) -> void:
	var s: int = clampi(stars, 0, 3)
	_stars_label.visible = true
	_stars_label.text = ""
	_new_best_label.visible = false
	_next_button.visible = has_next
	var t: Tween = _stars_label.create_tween()
	for i in 3:
		t.tween_interval(star_stagger)
		t.tween_callback(_reveal_star.bind(i, s))
	if improved:
		t.tween_interval(star_stagger)
		t.tween_callback(_pop_new_best)


func _reveal_star(index: int, filled: int) -> void:
	var shown: int = index + 1
	_stars_label.text = "★".repeat(mini(shown, filled)) + "☆".repeat(maxi(shown - filled, 0))
	if index < filled:
		AudioManager.play_sfx("star")  # hook — silent until an asset is bound
		_stars_label.pivot_offset = _stars_label.size * 0.5
		_stars_label.scale = Vector2.ONE * star_punch
		var t: Tween = _stars_label.create_tween()
		t.tween_property(_stars_label, "scale", Vector2.ONE, 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pop_new_best() -> void:
	_new_best_label.visible = true
	_new_best_label.pivot_offset = _new_best_label.size * 0.5
	_new_best_label.scale = Vector2.ONE * 1.3
	var t: Tween = _new_best_label.create_tween()
	t.tween_property(_new_best_label, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## In-run coins readout (full economy UI lives in the menu/store screens).
func _on_currency_changed(balance: int) -> void:
	_currency_label.text = tr("HUD_CURRENCY") + ": " + str(balance)


## Compact today's-missions list on the HUD (the full panel is the Missions screen).
func show_missions(missions: Array) -> void:
	var lines: Array[String] = []
	for m in missions:
		var desc: String = tr(m.def.description_key) % m.def.goal_amount
		var mark: String = " ✓" if m.is_complete() else ""
		lines.append("%s  %d/%d%s" % [desc, m.progress, m.def.goal_amount, mark])
	_mission_label.text = "\n".join(lines)
