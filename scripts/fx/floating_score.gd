extends Label

## "+N" capture popup: punches in, rises and fades, then frees itself. Spawned in world
## space at the capture point. All feel knobs are @export — tune in the editor.
## Combo escalation (feel P1-12): higher multipliers punch harder and warm toward gold;
## x1 is exactly the original look.

const PALETTE: PaletteData = preload("res://config/palette.tres")

@export var rise: float = 64.0        # px travelled upward
@export var duration: float = 0.7     # seconds to rise + fade
@export var punch_scale: float = 1.5  # initial scale before settling to 1.0 (x1)
@export var combo_punch_step: float = 0.15  # extra punch per multiplier above x1
@export var combo_punch_max: float = 2.2    # punch ceiling for long chains
@export var combo_heat_start: int = 3       # multiplier where the gold shift begins
@export var combo_heat_full: int = 5        # multiplier that is fully gold

var _mult: int = 1


## Sets the text, color and combo multiplier. Call right after instancing (before the first frame).
func show_value(value: int, color: Color, mult: int = 1) -> void:
	text = "+%d" % value
	_mult = maxi(mult, 1)
	var heat: float = JuiceMath.combo_heat(_mult, combo_heat_start, combo_heat_full)
	add_theme_color_override("font_color", color.lerp(PALETTE.coin, heat))


## Start scale for this popup: punch_scale at x1, growing per multiplier, clamped.
func start_scale() -> float:
	return minf(punch_scale + combo_punch_step * float(_mult - 1), maxf(combo_punch_max, punch_scale))


func _ready() -> void:
	await get_tree().process_frame  # size is valid after one layout frame
	pivot_offset = size * 0.5
	position -= size * 0.5          # center the popup on the spawn point
	scale = Vector2.ONE * start_scale()
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", position.y - rise, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(queue_free)
