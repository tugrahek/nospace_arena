class_name MissionDef
extends Resource

## A mission definition (content, .tres): goal + reward. Progress/claimed are runtime
## state (Mission). description_key is a locale template formatted with goal_amount.

enum GoalType { REACH_SCORE, REACH_PERCENT, TOTAL_AREAS, WIN_RUNS }

@export var id: StringName
@export var description_key: String
@export_enum("ReachScore", "ReachPercent", "TotalAreas", "WinRuns") var goal_type: int = 0
@export var goal_amount: int = 100
@export var reward: int = 50
