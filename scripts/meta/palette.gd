class_name PaletteData
extends Resource

## Central void-neon palette for CODE-drawn elements (arena/enemy/player/HUD draws) and
## for keeping the UI theme + clear color in sync. UI Controls get these via ui_theme.tres;
## this resource is the single source for everything drawn in code. No hard-coded colors.

@export var void_bg: Color = Color(0.035, 0.03, 0.085, 1.0)      # deep near-black, blue/violet tint
@export var panel: Color = Color(0.09, 0.08, 0.17, 0.88)          # glass panel fill
@export var border: Color = Color(0.2, 0.95, 1.0, 0.55)          # neon edge
@export var accent: Color = Color(0.2, 0.95, 1.0, 1.0)           # cyan (primary)
@export var accent_alt: Color = Color(0.95, 0.3, 0.95, 1.0)      # magenta/pink
@export var warm: Color = Color(1.0, 0.55, 0.35, 1.0)            # coral/sun (warm accent)
@export var text_primary: Color = Color(0.9, 0.92, 0.97, 1.0)
@export var text_secondary: Color = Color(0.62, 0.64, 0.74, 1.0)
@export var coin: Color = Color(1.0, 0.85, 0.35, 1.0)
@export var danger: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var success: Color = Color(0.4, 1.0, 0.55, 1.0)
