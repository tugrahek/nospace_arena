extends CPUParticles2D

## Fire-and-forget particle burst: emits once when added to the tree, then frees itself.
## CPUParticles2D (not GPU) for gl_compatibility safety. Position/color are set by the
## spawner before add_child; the burst params live on the scene (editable in the inspector).


func _ready() -> void:
	finished.connect(queue_free)
	emitting = true
