extends Node2D

const BALANCE: BalanceConfig = preload("res://config/balance.tres")
const ENEMY_SCENE: PackedScene = preload("res://scenes/gameplay/Enemy.tscn")
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
const PLAY_RECT: Rect2 = Rect2(40.0, 100.0, 640.0, 1100.0)  # fixed play area; HUD reserved above

@onready var _arena: ArenaController = $Arena
@onready var _player: Player = $Player
@onready var _enemies_root: Node2D = $Enemies
@onready var _living_territory: LivingTerritory = $LivingTerritory
@onready var _dpad_view: Control = $UILayer/DpadView
@onready var _hud: HUD = $HUD

var _enemies: Array[Enemy] = []
var _arena_data: ArenaData


func _ready() -> void:
	_apply_arena(GameState.selected_arena_index)
	_player.setup(_arena)
	_arena.area_captured.connect(_on_area_captured)
	_player.control_scheme_changed.connect(_on_scheme_changed)
	_player.loop_closed.connect(_on_loop_closed)
	GameState.life_lost.connect(_on_life_lost)
	GameState.game_over.connect(_on_game_over)
	GameState.run_won.connect(_on_run_won)
	_hud.retry_pressed.connect(_on_retry)
	_on_scheme_changed(int(_player.control_scheme))
	_spawn_enemies()
	_living_territory.setup(_arena, _enemies, _player)
	_apply_character(GameState.selected_character_index)
	GameState.start_run(BALANCE.start_lives, BALANCE.base_points, BALANCE.combo_window)
	_hud.setup(BALANCE.start_lives)


## Applies an arena (fit-to-rect grid + theme) deterministically via the catalog.
## Must run before Player.setup (player reads the grid). Difficulty is read on spawn.
func _apply_arena(index: int) -> void:
	var i: int = ArenaCatalog.select(ARENAS.size(), index)
	if i < 0:
		i = 0
	GameState.set_arena(i)
	_arena_data = ARENAS[i]
	_arena.configure(_arena_data, PLAY_RECT)
	print("Arena: %s" % tr(_arena_data.display_name_key))


## Applies a character: its territory effect drives the living territory, and its
## accent color tints the captured glow. Dev key `C` cycles for playtest (UI in Step 13).
func _apply_character(index: int) -> void:
	var i: int = index % CHARACTERS.size()
	var ch: CharacterData = CHARACTERS[i]
	GameState.set_character(i)
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
		enemy.setup(_arena, center, EnemyMotion.start_velocity(i, speed_px), type.behavior, speed_px)
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


func _on_game_over(_final_score: int) -> void:
	pass  # HUD handles display via GameState.game_over signal


func _on_run_won(_final_score: int) -> void:
	pass  # HUD handles display via GameState.run_won signal


func _on_area_captured(percent: float, cells: Array) -> void:
	_hud.update_percent(percent)
	var now: float = Time.get_ticks_msec() / 1000.0
	GameState.register_capture(cells.size(), now)
	if percent >= _arena_data.target_percent and GameState.is_playing():
		GameState.win_run()


func _on_scheme_changed(id: int) -> void:
	_dpad_view.set_active(id == Player.SchemeId.DPAD)


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_C:
			_apply_character(GameState.selected_character_index + 1)
		elif event.keycode == KEY_V:
			# Arena resize needs a full rebuild -> reload (index persists in GameState).
			GameState.set_arena(GameState.selected_arena_index + 1)
			get_tree().reload_current_scene()
