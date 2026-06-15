extends Node2D

@onready var _arena: ArenaController = $Arena
@onready var _player: Player = $Player
@onready var _dpad_view: Control = $UILayer/DpadView


func _ready() -> void:
	_player.setup(_arena)
	_arena.area_captured.connect(_on_area_captured)
	_arena.capture_failed.connect(_on_capture_failed)
	_player.control_scheme_changed.connect(_on_scheme_changed)
	_on_scheme_changed(int(_player.control_scheme))


func _on_area_captured(percent: float, _cells: Array) -> void:
	print("Ele geçirilen: %.1f%%" % percent)


func _on_capture_failed() -> void:
	print("Çizgi başarısız (kendine değdi)")


func _on_scheme_changed(id: int) -> void:
	_dpad_view.set_active(id == Player.SchemeId.DPAD)
