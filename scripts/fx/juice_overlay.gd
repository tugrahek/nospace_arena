class_name JuiceOverlay
extends CanvasLayer

## Full-screen feedback overlay: a single quick flash (life loss) and a red edge-vignette
## pulse (near-miss). Both settle back to invisible. @export for feel; no strobe.

@export var flash_color: Color = Color(1.0, 0.35, 0.35, 1.0)
@export var flash_alpha: float = 0.55
@export var flash_in: float = 0.04
@export var flash_out: float = 0.22
@export var vignette_max_intensity: float = 0.8  # darkest red at full danger
@export var vignette_smooth: float = 8.0          # lerp rate/sec toward the danger target

@onready var _flash: ColorRect = $Flash
@onready var _vignette: ColorRect = $Vignette

var _flash_tween: Tween = null
var _danger_target: float = 0.0   # 0..1 proximity level (set by near-miss each frame)
var _vig_current: float = 0.0     # smoothed intensity actually applied


func _ready() -> void:
	_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	_set_vignette(0.0)


## One short flash (in then out). Used on life loss.
func flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", flash_alpha, flash_in)
	_flash_tween.tween_property(_flash, "color:a", 0.0, flash_out)


## Sets the proximity danger level [0, 1] (driven continuously by near-miss). The vignette
## smoothly ramps toward it -> appears/darkens/fades without flicker; 0 while safe.
func set_danger(level: float) -> void:
	_danger_target = clampf(level, 0.0, 1.0)


func _process(delta: float) -> void:
	var target: float = _danger_target * vignette_max_intensity
	_vig_current = lerpf(_vig_current, target, clampf(vignette_smooth * delta, 0.0, 1.0))
	_set_vignette(_vig_current)


func _set_vignette(v: float) -> void:
	var mat := _vignette.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("intensity", v)
