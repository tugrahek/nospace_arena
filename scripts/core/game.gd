extends Node2D

@onready var _arena: ArenaController = $Arena
@onready var _player: Player = $Player


func _ready() -> void:
	_player.setup(_arena.get_rect())
