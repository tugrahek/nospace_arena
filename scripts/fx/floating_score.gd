extends Label

## "+N" capture popup: punches in, rises and fades, then frees itself. Spawned in world
## space at the capture point. All feel knobs are @export — tune in the editor.

@export var rise: float = 64.0        # px travelled upward
@export var duration: float = 0.7     # seconds to rise + fade
@export var punch_scale: float = 1.5  # initial scale before settling to 1.0


## Sets the text and color. Call right after instancing (before the first frame).
func show_value(value: int, color: Color) -> void:
	text = "+%d" % value
	add_theme_color_override("font_color", color)


func _ready() -> void:
	await get_tree().process_frame  # size is valid after one layout frame
	pivot_offset = size * 0.5
	position -= size * 0.5          # center the popup on the spawn point
	scale = Vector2.ONE * punch_scale
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", position.y - rise, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(queue_free)
