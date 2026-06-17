extends Node2D

const BALANCE: BalanceConfig = preload("res://config/balance.tres")
const ENEMY_SCENE: PackedScene = preload("res://scenes/gameplay/Enemy.tscn")
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const PLAY_RECT: Rect2 = Rect2(40.0, 100.0, 640.0, 1100.0)  # fixed play area; HUD reserved above
const ARENA_SALT: int = 1   # daily seed salts (distinct draws)
const CHAR_SALT: int = 2
const LEADERBOARD_PATH: String = "user://leaderboard.json"
const MISSIONS_PATH: String = "user://missions.json"
const MISSION_COUNT: int = 3

@onready var _arena: ArenaController = $Arena
@onready var _player: Player = $Player
@onready var _enemies_root: Node2D = $Enemies
@onready var _living_territory: LivingTerritory = $LivingTerritory
@onready var _dpad_view: Control = $UILayer/DpadView
@onready var _hud: HUD = $HUD
@onready var _pause_overlay: CanvasLayer = $PauseOverlay

var _enemies: Array[Enemy] = []
var _arena_data: ArenaData
var _daily: bool = false
var _daily_seed: int = 0
var _leaderboard: Leaderboard = null
var _recording: GhostTrack = null
var _ghost: Ghost = null
var _missions: Array[Mission] = []
var _mission_date: int = 0
var _areas_this_run: int = 0
var _last_percent: float = 0.0
var _won: bool = false


func _ready() -> void:
	# Daily: arena + character + enemy dirs all come from the shared seed (same for
	# everyone that day). Free-play: player's own indices (dev C/V cycle).
	_daily = SeedManager.is_daily
	_daily_seed = SeedManager.daily_seed
	# Daily: seed-derived. Free-play: the player's saved loadout (Economy/SaveData).
	var arena_idx: int = DailySeed.to_index(_daily_seed, ARENA_SALT, ContentCatalog.ARENAS.size()) if _daily else ContentCatalog.arena_index(Economy.selected_arena())
	var char_idx: int = DailySeed.to_index(_daily_seed, CHAR_SALT, ContentCatalog.CHARACTERS.size()) if _daily else ContentCatalog.character_index(Economy.selected_character())
	_apply_arena(arena_idx)
	_player.setup(_arena)
	_arena.area_captured.connect(_on_area_captured)
	_player.control_scheme_changed.connect(_on_scheme_changed)
	_player.loop_closed.connect(_on_loop_closed)
	GameState.life_lost.connect(_on_life_lost)
	GameState.game_over.connect(_on_game_over)
	GameState.run_won.connect(_on_run_won)
	_hud.retry_pressed.connect(_on_retry)
	_hud.menu_pressed.connect(_on_menu)
	_pause_overlay.restart_requested.connect(_on_retry)
	_pause_overlay.menu_requested.connect(_on_menu)
	_on_scheme_changed(int(_player.control_scheme))
	_spawn_enemies()
	_living_territory.setup(_arena, _enemies, _player)
	_apply_character(char_idx)
	GameState.start_run(BALANCE.start_lives, BALANCE.base_points, BALANCE.combo_window)
	_hud.setup(BALANCE.start_lives)
	_hud.set_daily(_daily, _daily_seed)
	_setup_leaderboard_and_ghost()
	_setup_missions()
	if _daily:
		print("Daily mode: seed=%d arena=%d char=%d" % [_daily_seed, arena_idx, char_idx])


## Daily only: load the leaderboard, show today's best, and play its ghost (recorded
## path of the best run). Also starts recording this run. Free-play: nothing.
func _setup_leaderboard_and_ghost() -> void:
	if not _daily:
		_hud.set_best(-1)
		return
	_leaderboard = LeaderboardStore.load_from(LEADERBOARD_PATH)
	_recording = GhostTrack.new()
	_hud.set_best(_leaderboard.best_score(_daily_seed))
	var best_track: GhostTrack = _leaderboard.best_track(_daily_seed)
	if best_track != null and not best_track.is_empty():
		_ghost = Ghost.new()
		add_child(_ghost)
		_ghost.play(best_track)


## Builds today's 3 missions (seed-derived, same for everyone) with saved progress.
## Today's date drives selection regardless of daily/free-play (missions count in any run).
func _setup_missions() -> void:
	_mission_date = SeedManager.compute_today()
	var saved: Dictionary = MissionStore.load_progress(MISSIONS_PATH, _mission_date)
	_missions = MissionService.build(ContentCatalog.MISSIONS, _mission_date, MISSION_COUNT, saved)
	_hud.show_missions(_missions)


## Evaluates missions against this run's stats, pays newly-completed rewards once, saves.
func _update_missions(score: int) -> void:
	var stats: Dictionary = {
		"score": score, "percent": _last_percent, "areas": _areas_this_run, "won": _won,
	}
	var reward: int = 0
	for m in _missions:
		m.advance(stats)
		reward += m.claim()  # 0 unless newly complete; idempotent (no double reward)
	if reward > 0:
		Economy.earn(reward)
	var progress: Dictionary = {}
	for m in _missions:
		progress[String(m.def.id)] = m.to_dict()
	MissionStore.save_progress(MISSIONS_PATH, _mission_date, progress)
	_hud.show_missions(_missions)


## Records the player path at the physics rate (daily only) for the ghost.
## Pause freezes _physics_process -> no samples while paused -> ghost stays deterministic.
func _physics_process(_delta: float) -> void:
	if _daily and _recording != null and GameState.is_playing():
		_recording.add_sample(_player.position)


## Ghost recording length (frames) — used to verify pause stops sampling.
func recording_frame_count() -> int:
	return _recording.length_frames() if _recording != null else 0


## Submits this run's score to the daily leaderboard; persists + updates BEST if new best.
func _submit_run(score: int) -> void:
	if not _daily or _leaderboard == null or _recording == null:
		return
	if _leaderboard.submit(_daily_seed, score, _recording):
		LeaderboardStore.save_to(LEADERBOARD_PATH, _leaderboard)
		_hud.set_best(_leaderboard.best_score(_daily_seed))


## Applies an arena (fit-to-rect grid + theme) deterministically via the catalog.
## Must run before Player.setup (player reads the grid). Difficulty is read on spawn.
func _apply_arena(index: int) -> void:
	var i: int = ArenaCatalog.select(ContentCatalog.ARENAS.size(), index)
	if i < 0:
		i = 0
	_arena_data = ContentCatalog.ARENAS[i]
	_arena.configure(_arena_data, PLAY_RECT)
	print("Arena: %s" % tr(_arena_data.display_name_key))


## Applies a character: its territory effect drives the living territory, and its
## accent color tints the captured glow. Selection persistence is Economy (Store/menu).
func _apply_character(index: int) -> void:
	var i: int = index % ContentCatalog.CHARACTERS.size()
	var ch: CharacterData = ContentCatalog.CHARACTERS[i]
	_living_territory.effect = ch.effect
	_arena.captured_color = ch.accent_color
	_arena.queue_redraw()
	print("Karakter: %s" % tr(ch.display_name_key))


func _spawn_enemies() -> void:
	var center: Vector2 = _arena.get_rect().get_center()
	var i: int = 0
	for type in _arena_data.enemies:
		# Grid-relative speed: type base (cells/s) × arena modifier × fitted cell_size.
		var speed_px: float = type.base_speed_cells * _arena_data.speed_mult * _arena.cell_size
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		_enemies_root.add_child(enemy)
		if _arena_data.theme != null:
			enemy.color = _arena_data.theme.enemy_color
		enemy.shape = type.shape
		var vel: Vector2 = EnemyMotion.start_velocity_seeded(DailySeed.dir_index(_daily_seed, i), speed_px) \
			if _daily else EnemyMotion.start_velocity(i, speed_px)
		enemy.setup(_arena, center, vel, type.behavior, speed_px)
		enemy.hit_trail.connect(_on_enemy_hit_trail)
		_enemies.append(enemy)
		i += 1


## Player closed a loop: capture using the live enemy cells as danger seeds.
func _on_loop_closed() -> void:
	_arena.close_capture(_enemy_cells())


func _enemy_cells() -> Array:
	var cells: Array = []
	for e in _enemies:
		cells.append(_arena.world_to_cell(e.position))
	return cells


func _on_enemy_hit_trail() -> void:
	if not GameState.is_playing():
		return
	_arena.fail_trail()
	_player.respawn()
	GameState.lose_life()


func _on_life_lost(_remaining: int) -> void:
	pass  # HUD handles display via GameState.life_lost signal


func _on_game_over(final_score: int) -> void:
	_on_run_ended(final_score)  # HUD result panel handled via GameState signal


func _on_run_won(final_score: int) -> void:
	_won = true
	_on_run_ended(final_score)  # HUD result panel handled via GameState signal


## Run end: daily leaderboard submit + mission evaluation (missions are the currency source).
func _on_run_ended(score: int) -> void:
	_submit_run(score)
	_update_missions(score)


func _on_area_captured(percent: float, cells: Array) -> void:
	_hud.update_percent(percent)
	_areas_this_run += 1
	_last_percent = percent
	var now: float = Time.get_ticks_msec() / 1000.0
	GameState.register_capture(cells.size(), now)
	if percent >= _arena_data.target_percent and GameState.is_playing():
		GameState.win_run()


func _on_scheme_changed(id: int) -> void:
	_dpad_view.set_active(id == Player.SchemeId.DPAD)


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


## DEV shortcuts — debug/editor only; auto-disabled in release export (no cheats shipped).
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_G:
			SeedManager.toggle_daily()
			get_tree().reload_current_scene()
		elif event.keycode == KEY_H and SeedManager.is_daily:
			SeedManager.advance_day()  # preview next day's challenge
			get_tree().reload_current_scene()
		elif event.keycode == KEY_C and not SeedManager.is_daily:
			# Cycle the persisted character selection, then rebuild.
			var ci: int = (ContentCatalog.character_index(Economy.selected_character()) + 1) % ContentCatalog.CHARACTERS.size()
			Economy.set_selected_character(ContentCatalog.CHARACTERS[ci].id)
			get_tree().reload_current_scene()
		elif event.keycode == KEY_V and not SeedManager.is_daily:
			var ai: int = (ContentCatalog.arena_index(Economy.selected_arena()) + 1) % ContentCatalog.ARENAS.size()
			Economy.set_selected_arena(ContentCatalog.ARENAS[ai].id)
			get_tree().reload_current_scene()
