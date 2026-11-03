class_name CharacterData
extends Resource

## A playable character: visual identity + its living-territory effect.
## Balanced sidegrade — characters change HOW you control enemies, not raw power.
## Defines localized identity, territory effect and soft-currency unlock cost.

@export var id: StringName
@export var display_name_key: String  # locale key (player-facing name)
@export var description_key: String  # locale key (one-line effect description)
@export var accent_color: Color = Color(0.12, 0.5, 0.95, 0.55)  # territory glow tint
@export var effect: TerritoryEffect
@export var unlock_cost: int = 0  # 0 = free (default character)
