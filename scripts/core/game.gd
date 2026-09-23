extends Node2D

const BALANCE: BalanceConfig = preload("res://config/balance.tres")
const ENEMY_SCENE: PackedScene = preload("res://scenes/gameplay/Enemy.tscn")
const BURST_SCENE: PackedScene = preload("res://scenes/fx/CaptureBurst.tscn")
const FLOATING_SCORE_SCENE: PackedScene = preload("res://scenes/fx/FloatingScore.tscn")
const MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/ui/LevelSelect.tscn"
const PLAY_RECT: Rect2 = Rect2(40.0, 100.0, 640.0, 1100.0)  # fixed play area; HUD reserved above
const ARENA_SALT: int = 1   # daily seed salts (distinct draws)
const CHAR_SALT: int = 2
const LEADERBOARD_PATH: String = "user://leaderboard.json"
const MISSIONS_PATH: String = "user://missions.json"
const MISSION_COUNT: int = 3
const PROGRESSION: ProgressionConfig = preload("res://config/progression.tres")
const PALETTE: PaletteData = preload("res://config/palette.tres")
## Fix-pass #20 (B5): search radius for the nearest FREE cell when an enemy's own cell isn't
## walkable anymore -- both for correcting its danger seed before a capture and for evacuating it
## afterwards if it still ended up on a CAPTURED cell. Small and rare (only the affected enemy
## pays this), never a full-grid scan.
const STUCK_ENEMY_SEARCH_RADIUS: int = 12

@export var death_grace: float = 1.0  # invulnerability window after a life loss (no chain-kills)
## Start grace: the same i-frames at the start of a run (and after every respawn), HELD until the
## player's first step. The player rests on a frame corner, where a passing Sparx is lethal from
## frame one — nobody may lose a life before they have had a chance to react.
@export var start_grace_duration: float = 1.0

@onready var _arena: ArenaController = $Arena
@onready var _player: Player = $Player
@onready var _enemies_root: Node2D = $Enemies
@onready var _living_territory: LivingTerritory = $LivingTerritory
@onready var _dpad_view: Control = $UILayer/DpadView
@onready var _hud: HUD = $HUD
@onready var _pause_overlay: CanvasLayer = $PauseOverlay
@onready var _camera: CameraShake = $Camera2D
@onready var _hitstop: HitStop = $HitStop
@onready var _time_control: TimeControl = $TimeControl
@onready var _near_miss: NearMiss = $NearMiss
@onready var _overlay: JuiceOverlay = $JuiceOverlay

var _enemies: Array[Enemy] = []
var _arena_data: ArenaData
var _daily: bool = false
var _mode: int = SeedManager.Mode.FREE
var _level: LevelData = null  # active Campaign level (CAMPAIGN mode only)
var _daily_seed: int = 0
var _leaderboard: Leaderboard = null
var _recording: GhostTrack = null
var _ghost: Ghost = null
var _missions: Array[Mission] = []
var _mission_date: int = 0
var _areas_this_run: int = 0
var _last_percent: float = 0.0
var _won: bool = false
var _current_stage: int = 0
var _stage_target: float = 75.0
var _advancing: bool = false
var _exposed_time: float = 0.0  # seconds spent drawing in the open since last capture/fail
var _slow_start_timer: float = 0.0  # Slow Start boost: enemies slowed while > 0 (fixed-step)
var _slow_start_scale: float = 1.0
var _coin_multiplier: float = 1.0  # Coin Bonus boost: run-end coin reward x this (1.0 = none)
var _lives_lost: int = 0  # deaths this run (Campaign: 0 -> flawless star)
var _death_grace_timer: float = 0.0  # > 0 = invulnerable (ignore hits) right after a life loss
var _awaiting_first_move: bool = true  # start grace is frozen until the player actually steps
var _run_time: float = 0.0  # game-time seconds (fixed physics steps); combo clock — frozen by
                            # pause and unaffected by slow-mo/hit-stop (daily score fairness)


func _ready() -> void:
	# Safety: a hit-stop (or 16b slow-mo) may have reloaded the scene mid-freeze.
	# Reset before anything else so a retry never starts time-scaled.
	Engine.time_scale = 1.0
	# Daily: arena + character + enemy dirs all come from the shared seed (same for
	# everyone that day). Free-play: player's own indices (dev C/V cycle).
	_daily = SeedManager.is_daily
	_mode = SeedManager.mode
	_level = ContentCatalog.level_at(SeedManager.campaign_level) if _mode == SeedManager.Mode.CAMPAIGN else null
	_daily_seed = SeedManager.daily_seed
	var char_idx: int = DailySeed.to_index(_daily_seed, CHAR_SALT, ContentCatalog.CHARACTERS.size()) if _daily else ContentCatalog.character_index(Economy.selected_character())
	# Connect signals ONCE — nodes (arena/player/enemies-root/HUD) persist across stages;
	# only the arena config + enemy set change per stage.
	_arena.area_captured.connect(_on_area_captured)
	_player.control_scheme_changed.connect(_on_scheme_changed)
	_player.loop_closed.connect(_on_loop_closed)
	_player.self_hit.connect(_on_trail_failed)  # crossing own trail = life loss (same pipeline)
	GameState.life_lost.connect(_on_life_lost)
	GameState.game_over.connect(_on_game_over)
	GameState.run_won.connect(_on_run_won)
	_hud.retry_pressed.connect(_on_retry)
	_hud.menu_pressed.connect(_on_menu)
	_hud.next_pressed.connect(_on_next)
	_pause_overlay.restart_requested.connect(_on_retry)
	_pause_overlay.menu_requested.connect(_on_menu)
	_hitstop.time_control = _time_control
	_near_miss.near_miss.connect(_on_near_miss)
	_near_miss.danger_changed.connect(_overlay.set_danger)  # continuous proximity vignette
	# Pre-run boosts (consumables): policy-gated (off in Daily / boost-locked levels), consumed once.
	var boost_fx: Dictionary = _resolve_boosts()
	var base_lives: int = _level.lives if _level != null else BALANCE.start_lives
	var start_lives: int = base_lives + int(boost_fx["extra_lives"])
	_slow_start_scale = float(boost_fx["slow_scale"])
	_slow_start_timer = float(boost_fx["slow_duration"])
	_coin_multiplier = float(boost_fx["coin_multiplier"])
	GameState.start_run(start_lives, BALANCE.base_points, BALANCE.combo_window,
		BALANCE.exposed_points_per_sec, BALANCE.exposed_cap_sec, BALANCE.life_loss_penalty)
	_hud.setup(start_lives)
	_hud.set_daily(_daily, _daily_seed)
	_begin_grace(start_grace_duration)  # nobody dies before their first step
	_player.control_scheme = AudioManager.settings().control_scheme  # persisted choice (Settings)
	# Live-apply scheme changes from Pause → Settings (mid-run). Named method (not a lambda) so
	# _exit_tree can disconnect it — otherwise every scene reload piles a stale connection
	# onto the AudioManager autoload.
	AudioManager.control_scheme_changed.connect(_on_scheme_setting_changed)
	_start_stage(0)             # configures arena + player + enemies + living/near-miss refs
	_apply_character(char_idx)  # character is constant across stages (set after arena exists)
	_on_scheme_changed(int(_player.control_scheme))
	_setup_leaderboard_and_ghost()
	_setup_missions()
	AudioManager.stop_music()  # in-run is silent (no game-music track); menu music resumes on return
	if _daily and OS.is_debug_build():
		print("Daily mode: seed=%d" % _daily_seed)


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
		Economy.earn(int(round(reward * _coin_multiplier)))  # Coin Bonus boost (1.0 = no change)
	var progress: Dictionary = {}
	for m in _missions:
		progress[String(m.def.id)] = m.to_dict()
	MissionStore.save_progress(MISSIONS_PATH, _mission_date, progress)
	_hud.show_missions(_missions)


## Resolves this run's boosts from Economy via the pure resolver, consuming the armed charges that
## actually apply (policy-gated: Daily applies/consumes nothing). Returns the effect dictionary.
func _resolve_boosts() -> Dictionary:
	var armed: Dictionary = {}
	var counts: Dictionary = {}
	for b in ContentCatalog.BOOSTS:
		armed[String(b.id)] = Economy.is_boost_armed(b.id)
		counts[String(b.id)] = Economy.boost_count(b.id)
	var campaign_allows: bool = _level.boosts_allowed if _level != null else true
	var fx: Dictionary = BoostEffects.resolve(_mode, ContentCatalog.BOOSTS, armed, counts, campaign_allows)
	for id in fx["consume"]:
		Economy.consume_boost(id)
	return fx


## Records the player path at the physics rate (daily only) for the ghost.
## Pause freezes _physics_process -> no samples while paused -> ghost stays deterministic.
func _physics_process(delta: float) -> void:
	# Game-time clock (combo window source): advances only on live physics steps, so pausing
	# freezes it and slow-mo/hit-stop don't shrink the window in game terms.
	if GameState.is_playing():
		_run_time += delta
	# Start grace holds at full value until the player takes their first step (run start and every
	# respawn): a still player on a corner cell can be reached by a patrolling Sparx, and an
	# unavoidable death is never fair. Deterministic (fixed duration + input, no RNG).
	if _awaiting_first_move and GameState.is_playing():
		if _player.has_moved():
			_awaiting_first_move = false
		else:
			_death_grace_timer = maxf(_death_grace_timer, start_grace_duration)
	# Post-death invulnerability: count down + blink the player so the grace reads clearly.
	if _death_grace_timer > 0.0:
		_death_grace_timer -= delta
		if _death_grace_timer <= 0.0:
			_player.modulate.a = 1.0
		else:
			_player.modulate.a = 0.35 + 0.65 * absf(sin(_death_grace_timer * 20.0))
	# Slow Start boost: enemies run at run_speed_scale until the timer expires, then back to normal.
	if _slow_start_timer > 0.0:
		_slow_start_timer -= delta
		if _slow_start_timer <= 0.0:
			for e in _enemies:
				e.run_speed_scale = 1.0
	# Risk reward: accrue exposed time only while drawing in the open (safe/wall == not exposed -> 0).
	if GameState.is_playing() and _player.is_exposed():
		_exposed_time += delta
	# Skip sampling while ANY time effect is active (hit-stop or near-miss slow-mo): time_scale
	# is reduced there, so samples would cluster and bloat the ghost. Determinism unaffected.
	if _daily and _recording != null and GameState.is_playing() and not _time_control.is_active():
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
	if OS.is_debug_build():
		print("Arena: %s" % tr(_arena_data.display_name_key))


## Applies a character: its territory effect drives the living territory, and its
## accent color tints the captured glow. Selection persistence is Economy (Store/menu).
func _apply_character(index: int) -> void:
	var i: int = index % ContentCatalog.CHARACTERS.size()
	var ch: CharacterData = ContentCatalog.CHARACTERS[i]
	_living_territory.effect = ch.effect
	_arena.captured_color = ch.accent_color
	_arena.queue_redraw()
	if OS.is_debug_build():
		print("Karakter: %s" % tr(ch.display_name_key))


## Builds (or rebuilds) a stage: arena (fresh grid) + player reset + scaled enemies, then
## re-points the living-territory and near-miss refs. Lives + score (GameState) are untouched
## — they carry across stages. Capture/seed/grid algorithms are not modified; this only
## orchestrates which arena/enemies are active.
func _start_stage(stage: int) -> void:
	_advancing = false
	_current_stage = stage
	if _mode == SeedManager.Mode.CAMPAIGN and _level != null:
		_apply_campaign_level()
		return
	var base_arena: int = 0 if _daily else ContentCatalog.arena_index(Economy.selected_arena())
	var spec: Dictionary = StagePlan.compute(
		_daily, _daily_seed, base_arena, stage, ContentCatalog.ARENAS.size(),
		PROGRESSION.speed_ramp_per_stage, PROGRESSION.speed_cap,
		PROGRESSION.enemy_add_every, PROGRESSION.enemy_cap_bonus,
		PROGRESSION.target_ramp_per_stage
	)
	_apply_arena(int(spec["arena_index"]))
	_player.setup(_arena)
	_spawn_stage_enemies(spec)
	_living_territory.setup(_arena, _enemies, _player)
	_living_territory.set_hunt_nearest(_hunts_nearest(stage))
	_near_miss.setup(_player, _enemies)
	_stage_target = minf(_arena_data.target_percent + float(spec["target_bonus"]), PROGRESSION.target_cap)
	_hud.set_target(_stage_target)
	_hud.update_percent(0.0)
	if OS.is_debug_build():
		print("Stage %d: arena=%d target=%.0f%% speed=x%.2f enemies=%d" % [
			stage + 1, int(spec["arena_index"]), _stage_target, float(spec["speed_scale"]), _enemies.size()])


## Adaptive chaser (#19) for this stage/level: late Campaign levels (LevelData flag) and late
## Level-Endless stages (ProgressionConfig threshold). Free/Daily always off — Daily keeps its
## leaderboard fair and Free stays predictable. Resolved ONCE here, handed to LivingTerritory;
## the shared behavior resources never carry it.
func _hunts_nearest(stage: int) -> bool:
	var level_flag: bool = _level != null and _level.chaser_hunts_nearest
	return ChaserPolicy.hunts_nearest(_mode, level_flag, stage, PROGRESSION.chaser_hunts_nearest_stage)


## Campaign: a single authored level -- arena/theme + explicit enemy composition + target/pace from
## LevelData (no ramp, no auto-advance). Reuses the same spawn + capture machinery as stages.
func _apply_campaign_level() -> void:
	_arena_data = _level.arena
	_arena.configure(_arena_data, PLAY_RECT)
	_player.setup(_arena)
	_spawn_stage_enemies({"speed_scale": _level.speed_mult, "enemy_bonus": 0, "stage_seed": 0}, _level.enemies)
	_living_territory.setup(_arena, _enemies, _player)
	_living_territory.set_hunt_nearest(_hunts_nearest(_current_stage))
	_near_miss.setup(_player, _enemies)
	_stage_target = _level.target_percent
	_hud.set_target(_stage_target)
	_hud.update_percent(0.0)
	if OS.is_debug_build():
		print("Campaign level %s: arena=%s target=%.0f%% enemies=%d boosts=%s" % [
			_level.id, _arena_data.id, _stage_target, _level.enemies.size(), str(_level.boosts_allowed)])


## Spawns the stage's enemies: count = arena composition + seed/stage bonus (capped). Speed is
## the grid-relative type base × arena modifier × stage speed scale × fitted cell_size. Daily
## directions derive from the (deterministic) stage seed; free-play uses the index pattern.
func _spawn_stage_enemies(spec: Dictionary, override_types: Array = []) -> void:
	for e in _enemies:
		e.queue_free()
	_enemies.clear()
	# Campaign passes an explicit composition; stages use the arena's default roster.
	var types: Array[EnemyType] = _arena_data.enemies
	if not override_types.is_empty():
		types = []
		for t in override_types:
			types.append(t)
	if types.is_empty():
		return
	var count: int = types.size() + int(spec["enemy_bonus"])
	var center: Vector2 = _arena.get_rect().get_center()
	var stage_seed: int = int(spec["stage_seed"])
	var speed_scale: float = float(spec["speed_scale"])
	# Per-type totals keyed by the ACTUAL type (not position) so same-type enemies get distinct
	# even-spread variations ([-1,1]) -> approach from different angles, never stack. Keying by type
	# also fixes Campaign, whose explicit composition lists duplicates ([chaser, chaser]).
	var type_total: Dictionary = {}
	for i in count:
		var tt: EnemyType = types[i % types.size()]
		type_total[tt] = int(type_total.get(tt, 0)) + 1
	var type_seen: Dictionary = {}
	for i in count:
		var type: EnemyType = types[i % types.size()]
		var k: int = int(type_seen.get(type, 0))
		type_seen[type] = k + 1
		var variation: float = EnemyMotion.even_spread(k, int(type_total[type]))
		var speed_px: float = type.base_speed_cells * _arena_data.speed_mult * speed_scale * _arena.cell_size
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		_enemies_root.add_child(enemy)
		if _arena_data.theme != null:
			enemy.color = _arena_data.theme.enemy_color
		enemy.shape = type.shape
		if type.edge_follow:
			# Sparx: deterministic perimeter spawn on the left border (col 1, wall on the right of a
			# DOWN heading). Spread the start rows ACROSS the arena height by per-type index so
			# multiple sparx patrol far apart on the loop instead of trailing 1 cell apart (stacked).
			var max_row: int = maxi(_arena.grid.rows - 2, 1)
			var start_row: int = EnemyMotion.edge_start_row(k, int(type_total[type]), max_row)
			var start_cell := Vector2i(1, start_row)
			enemy.setup(_arena, _arena.cell_to_world(start_cell), Vector2.ZERO, type.behavior,
				speed_px, variation, true, start_cell, Vector2i.DOWN)
		else:
			var vel: Vector2 = EnemyMotion.start_velocity_seeded(DailySeed.dir_index(stage_seed, i), speed_px) \
				if _daily else EnemyMotion.start_velocity(i, speed_px)
			# Spread spawn positions off-center by index so multiple enemies don't stack (2 -> opposite
			# sides). Deterministic (index/count only) -> daily/ghost reproduce.
			var spawn_pos: Vector2 = center + EnemyMotion.spawn_offset(i, count, _arena.cell_size * 3.0)
			enemy.setup(_arena, spawn_pos, vel, type.behavior, speed_px, variation)
		enemy.run_speed_scale = _slow_start_scale if _slow_start_timer > 0.0 else 1.0  # Slow Start boost
		enemy.hit_trail.connect(_on_trail_failed)
		_enemies.append(enemy)


## Stage cleared (target reached): advance to the next, harder stage. Level-Endless only —
## Daily/Free are single-arena and win at target (18a redirect). Deferred from
## _on_area_captured so the arena isn't rebuilt inside the capture signal. Lives + score carry over.
func _advance_stage() -> void:
	if not GameState.is_playing():
		return
	var next: int = _current_stage + 1
	_stage_flourish(next + 1)  # display is 1-based
	_start_stage(next)


## Stage-clear celebration (Level-Endless): "Stage N" banner + an extra particle burst, a
## stronger camera punch, and the stage-clear SFX. Purely visual (no seed/capture effect).
func _stage_flourish(display_number: int) -> void:
	_hud.show_stage_banner(display_number)
	AudioManager.play_sfx("stage_clear")
	_camera.add_trauma(_camera.trauma_capture * 1.4)
	var burst: CPUParticles2D = BURST_SCENE.instantiate()
	burst.position = _arena.get_rect().get_center()
	burst.color = _arena.trail_color
	burst.amount = burst.amount * 2
	add_child(burst)


## Player closed a loop: capture using the live enemy cells as danger seeds.
func _on_loop_closed() -> void:
	_arena.close_capture(_enemy_cells())


func _enemy_cells() -> Array:
	var cells: Array = []
	for e in _enemies:
		if e.is_contained():
			continue  # invisible/inert contained Sparx must not block capturing its pocket
		var cell: Vector2i = _arena.world_to_cell(e.position)
		if _arena.cell_state(cell) != CaptureGrid.Cell.FREE:
			# The enemy's own cell isn't walkable (e.g. a grace-ignored hit left it bounced right
			# up against a trail wall, or the player's line was drawn under/through it) -- seed
			# from the nearest FREE cell instead, so its region still doesn't get swallowed with
			# it (fix-pass #20, B5 safety net; close_and_capture's own algorithm is untouched).
			var nearest: Vector2i = _arena.nearest_free_cell(cell, STUCK_ENEMY_SEARCH_RADIUS)
			if nearest.x >= 0:
				cell = nearest
		cells.append(cell)
	return cells


## Safety net (fix-pass #20, B5): after ANY capture, no active non-edge-follow enemy may be left
## standing in CAPTURED territory -- it would sit visibly inside the player's own area (device
## finding). Deterministic nearest-FREE-cell teleport, debug-logged. Sparx is excluded: it already
## self-heals an engulfed cell on its own next PATROL tick (top-of-_patrol engulf check), and a
## blind position teleport here would desync its internal _grid_cell/_step_from/_step_to state.
func _evacuate_enemies_from_captured_cells() -> void:
	for e in _enemies:
		if e.is_contained() or e.is_edge_follow():
			continue
		var cell: Vector2i = _arena.world_to_cell(e.position)
		if _arena.cell_state(cell) != CaptureGrid.Cell.CAPTURED:
			continue
		var free_cell: Vector2i = _arena.nearest_free_cell(cell, STUCK_ENEMY_SEARCH_RADIUS)
		if free_cell.x < 0:
			continue  # no FREE cell within range (board ~fully captured) -> nothing to do
		e.position = _arena.cell_to_world(free_cell)
		if OS.is_debug_build():
			print("[Enemy] evacuated from captured cell ", cell, " -> ", free_cell)


## Arms the invulnerability window and re-holds it until the player's next step (respawn and run
## start both leave the player parked and defenceless). Single owner of i-frames: every lethal
## path — Sparx catch, enemy on the trail, self-hit — goes through _on_trail_failed.
func _begin_grace(duration: float) -> void:
	_death_grace_timer = duration
	_awaiting_first_move = true


## Shared life-loss pipeline: an enemy touched the active trail, OR the player crossed its own
## trail (self_hit). Same feedback + fail_trail + respawn + lose_life for both.
func _on_trail_failed() -> void:
	if not GameState.is_playing():
		return
	if _death_grace_timer > 0.0:
		return  # invulnerable right after a death -> a single event costs exactly one life
	_begin_grace(death_grace)  # i-frames: blocks simultaneous/chain hits, re-held until the next step
	_lives_lost += 1  # tracked for the Campaign flawless star
	# Life-loss impact: a single screen flash + heavy shake (no strobe) + a local burst AT the
	# death spot (the respawn teleport otherwise leaves the moment unreadable). Visual only.
	var death_burst: CPUParticles2D = BURST_SCENE.instantiate()
	death_burst.position = _player.position
	death_burst.color = PALETTE.danger
	add_child(death_burst)
	_overlay.flash()
	_camera.add_trauma(_camera.trauma_life_loss)
	AudioManager.play_sfx("life_loss")
	AudioManager.haptic_life_loss()
	_exposed_time = 0.0  # risky time is forfeit on a failed trail
	_arena.fail_trail()
	_player.respawn()
	GameState.lose_life()


## Near-miss: a brief slow-mo (via the time arbiter). The red vignette is driven separately
## and continuously by proximity (see _near_miss.danger_changed -> _overlay.set_danger).
func _on_near_miss() -> void:
	_time_control.request("nearmiss", _near_miss.slow_scale, _near_miss.slow_duration)
	AudioManager.play_sfx("near_miss")


func _on_life_lost(_remaining: int) -> void:
	pass  # HUD handles display via GameState.life_lost signal


func _on_game_over(final_score: int) -> void:
	_on_run_ended(final_score)  # HUD result panel handled via GameState signal


func _on_run_won(final_score: int) -> void:
	_won = true
	_on_run_ended(final_score)  # HUD result panel handled via GameState signal


## Run end: daily leaderboard submit + mission evaluation (missions are the currency source).
## Campaign win also records stars (best kept -> unlocks the next level) + shows them on the result.
func _on_run_ended(score: int) -> void:
	_submit_run(score)
	_update_missions(score)
	if _mode == SeedManager.Mode.CAMPAIGN and _level != null and _won:
		var stars: int = CampaignStars.star_for(true, score, _lives_lost, _level)
		var improved: bool = stars > Economy.campaign_star(_level.id)
		Economy.record_campaign_result(_level.id, stars)  # records max -> may unlock the next level
		var next_i: int = SeedManager.campaign_level + 1
		var has_next: bool = next_i < ContentCatalog.LEVELS.size() and Economy.is_level_unlocked(next_i)
		_hud.show_campaign_stars(stars, improved, has_next)


func _on_area_captured(percent: float, cells: Array) -> void:
	_evacuate_enemies_from_captured_cells()  # fix-pass #20 (B5) -- belt-and-braces, runs every capture
	_hud.update_percent(percent)
	_last_percent = percent
	# Empty capture (e.g. a pocket fill that found nothing to take): state only — no area,
	# no score, no juice popping on the player for zero cells.
	var earned: int = 0
	if not cells.is_empty():
		_areas_this_run += 1
		# Combo clock = accumulated game time (not wall clock): pause/slow-mo can't eat the window.
		earned = GameState.register_capture(cells.size(), _run_time, _exposed_time)
		_exposed_time = 0.0  # consumed by this capture
	var newly_contained: bool = false
	# Perf-pass: the main-region seed (a full-grid flood) is computed ONCE and shared by every
	# patrolling edge-walker — and skipped entirely when none exists (bouncer-only arenas).
	var any_walker: bool = false
	for e in _enemies:
		if e.wants_capture_events():
			any_walker = true
			break
	if any_walker:
		var main_seed: Vector2i = _arena.grid._largest_free_component_seed()
		for e in _enemies:  # edge-walkers (Sparx) self-contain when sealed off from the main region
			if e.on_capture_event(main_seed):
				newly_contained = true
	if not cells.is_empty():
		_play_capture_juice(cells, earned)
	# Trap reward (fix-pass #10): a newly contained Sparx leaves its pocket seedless (contained
	# Sparx is excluded from danger seeds), so one more close_capture fills that pocket through
	# the NORMAL pipeline — %, score, combo, missions, juice and win/advance all flow from its
	# own area_captured emission. SYNC inside this signal is safe: the player just closed a
	# loop, so no live trail exists to be converted. A pocket still holding an ACTIVE enemy
	# stays FREE (that enemy seeds it) — a visible enemy keeps holding its ground.
	if newly_contained and GameState.is_playing():
		_arena.close_capture(_enemy_cells())
	# Target reached. Level-Endless advances to a harder stage (deferred so the arena isn't
	# rebuilt mid capture-signal); Daily/Free are single-arena and simply win.
	if percent >= _stage_target and GameState.is_playing():
		if _mode == SeedManager.Mode.LEVEL_ENDLESS:
			if not _advancing:
				_advancing = true
				call_deferred("_advance_stage")
		else:
			GameState.win_run()


## Capture feedback (visual only — no effect on capture logic or determinism):
## screen shake, a brief hit-stop, a particle burst and a "+N" popup at the closure point.
func _play_capture_juice(cells: Array, earned: int) -> void:
	_camera.add_trauma(_camera.trauma_capture)
	_hitstop.stop()
	AudioManager.play_sfx("capture")
	AudioManager.haptic_capture()
	var point: Vector2 = _capture_centroid(cells)
	_spawn_burst(point)
	if earned > 0:
		_spawn_floating_score(point, earned)


## World-space center of the newly captured cells (the closure point), or the player's
## position when no cells are reported.
func _capture_centroid(cells: Array) -> Vector2:
	if cells.is_empty():
		return _player.position
	var sum: Vector2 = Vector2.ZERO
	for c in cells:
		sum += _arena.cell_to_world(c)
	return sum / float(cells.size())


func _spawn_burst(point: Vector2) -> void:
	var burst: CPUParticles2D = BURST_SCENE.instantiate()
	burst.position = point
	burst.color = _arena.captured_color
	add_child(burst)


func _spawn_floating_score(point: Vector2, value: int) -> void:
	var popup: Label = FLOATING_SCORE_SCENE.instantiate()
	popup.position = point
	add_child(popup)
	popup.show_value(value, _arena.trail_color, GameState.get_combo() + 1)  # combo escalation (feel P1-12)


func _on_scheme_changed(id: int) -> void:
	_dpad_view.set_active(id == Player.SchemeId.DPAD)


## Settings changed the persisted control scheme (Pause → Settings mid-run) -> apply live.
func _on_scheme_setting_changed(id: int) -> void:
	_player.set_scheme(id)


func _exit_tree() -> void:
	# Drop the autoload connection: Game reloads on every retry/next, and stale connections
	# from freed scenes must not accumulate on AudioManager.
	if AudioManager.control_scheme_changed.is_connected(_on_scheme_setting_changed):
		AudioManager.control_scheme_changed.disconnect(_on_scheme_setting_changed)


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_menu() -> void:
	# Campaign returns to the level map (tight pick-next loop); other modes go home.
	var dest: String = LEVEL_SELECT_SCENE if _mode == SeedManager.Mode.CAMPAIGN else MENU_SCENE
	get_tree().change_scene_to_file(dest)


## Campaign win -> advance to the next level (already validated unlocked before the button showed).
func _on_next() -> void:
	SeedManager.enter_campaign(SeedManager.campaign_level + 1)
	get_tree().reload_current_scene()  # re-runs _ready with the new campaign_level


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
