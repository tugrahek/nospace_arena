extends Node2D

const BALANCE: BalanceConfig = preload("res://config/balance.tres")
const ENEMY_SCENE: PackedScene = preload("res://scenes/gameplay/Enemy.tscn")

@onready var _arena: ArenaController = $Arena
@onready var _player: Player = $Player
@onready var _enemies_root: Node2D = $Enemies
@onready var _dpad_view: Control = $UILayer/DpadView
@onready var _game_over_label: Label = $UILayer/GameOverLabel

var _enemies: Array[Enemy] = []


func _ready() -> void:
	_player.setup(_arena)
	_arena.area_captured.connect(_on_area_captured)
	_player.control_scheme_changed.connect(_on_scheme_changed)
	_player.loop_closed.connect(_on_loop_closed)
	GameState.life_lost.connect(_on_life_lost)
	GameState.game_over.connect(_on_game_over)
	_game_over_label.visible = false
	_on_scheme_changed(int(_player.control_scheme))
	_spawn_enemies()
	GameState.start_run(BALANCE.start_lives)


func _spawn_enemies() -> void:
	var center: Vector2 = _arena.get_rect().get_center()
	for i in BALANCE.enemy_count:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		_enemies_root.add_child(enemy)
		enemy.setup(_arena, center, EnemyMotion.start_velocity(i, BALANCE.enemy_speed))
		enemy.hit_trail.connect(_on_enemy_hit_trail)
		_enemies.append(enemy)


## Player closed a loop: capture using the live enemy cells as danger seeds, so
## the region containing an enemy stays free and the sealed-off region is taken.
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


func _on_life_lost(remaining: int) -> void:
	print("Can kaybı! Kalan: %d" % remaining)


func _on_game_over(_final_score: int) -> void:
	_game_over_label.visible = true
	print("OYUN BİTTİ")


func _on_area_captured(percent: float, _cells: Array) -> void:
	print("Ele geçirilen: %.1f%%" % percent)


func _on_scheme_changed(id: int) -> void:
	_dpad_view.set_active(id == Player.SchemeId.DPAD)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()
