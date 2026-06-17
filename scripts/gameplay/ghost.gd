class_name Ghost
extends Node2D

## Visual-only playback of a recorded GhostTrack (the day's best run). Semi-transparent,
## non-interactive. Frame-indexed playback matches the physics-rate recording; hides when
## the track ends. Shown only in daily mode (same seed -> same arena, so the path is fair).

@export var color: Color = Color(1.0, 1.0, 1.0, 0.35)
@export var radius: float = 7.0

var _track  # GhostTrack
var _frame: int = 0
var _playing: bool = false


func play(track) -> void:
	_track = track
	_frame = 0
	_playing = track != null and not track.is_empty()
	visible = _playing
	if _playing:
		position = _track.position_at_frame(0)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not _playing or not GameState.is_playing():
		return
	position = _track.position_at_frame(_frame)
	_frame += 1
	if _frame >= _track.length_frames():
		_playing = false
		visible = false


func _draw() -> void:
	if _playing:
		draw_circle(Vector2.ZERO, radius, color)
