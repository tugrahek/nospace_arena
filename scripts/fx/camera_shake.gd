class_name CameraShake
extends Camera2D

## Trauma-based screen shake. Trauma in [0, 1] is added by events and decays each frame;
## offset/roll scale with trauma squared (see JuiceMath) so small taps barely move the
## camera and big moments punch. All feel knobs are @export — tune in the editor.

@export var max_offset: float = 14.0       # px of shake at full trauma
@export var max_roll: float = 0.035        # radians of roll at full trauma
@export var decay: float = 1.6             # trauma units lost per second
@export var trauma_capture: float = 0.5    # trauma added on an area capture
@export var trauma_life_loss: float = 0.9  # trauma added on losing a life (16b)

var _trauma: float = 0.0
var _base_offset: Vector2


func _ready() -> void:
	_base_offset = offset


## Adds trauma (clamped to 1.0). Called by the game on juicy events.
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		if offset != _base_offset or rotation != 0.0:
			offset = _base_offset
			rotation = 0.0
		return
	_trauma = JuiceMath.decay_trauma(_trauma, decay, delta)
	var amount: float = JuiceMath.shake_amount(_trauma)
	offset = _base_offset + Vector2(
		randf_range(-1.0, 1.0) * max_offset * amount,
		randf_range(-1.0, 1.0) * max_offset * amount
	)
	rotation = randf_range(-1.0, 1.0) * max_roll * amount
