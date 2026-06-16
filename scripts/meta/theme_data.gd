class_name ThemeData
extends Resource

## Palette for an arena (color data only; sprites/shaders are Step 14). Composes with
## the active character: the theme sets the void/border/trail/enemy ambiance, the
## character's accent_color is the captured-territory glow that rides on top.

@export var id: StringName
@export var void_color: Color = Color(0.03, 0.02, 0.08, 1.0)
@export var border_color: Color = Color(0.25, 0.65, 1.0, 1.0)
@export var trail_color: Color = Color(0.2, 0.95, 1.0, 0.95)
@export var enemy_color: Color = Color(1.0, 0.25, 0.2, 1.0)
@export var captured_base_color: Color = Color(0.12, 0.5, 0.95, 0.55)  # fallback; character accent wins
@export var border_width: float = 3.0


## Perceived-luminance contrast (0..1) between two colors, alpha ignored. Pure —
## used by readability tests so enemy/trail/glow stay visible on every theme's void.
static func color_contrast(a: Color, b: Color) -> float:
	return absf(_luminance(a) - _luminance(b))


static func _luminance(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
