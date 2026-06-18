class_name JuicyButton
extends Button

## Drop-in juicy button: a quick scale "pop" on press + a short haptic tick on mobile.
## Attach as a Button's script. @export feel knobs (16c will roll this out widely, tuned).

@export var pop_scale: float = 1.12
@export var haptic_ms: int = 20


func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	button_down.connect(_on_down)


func _on_down() -> void:
	if haptic_ms > 0:
		Input.vibrate_handheld(haptic_ms)
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector2.ONE * pop_scale, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
