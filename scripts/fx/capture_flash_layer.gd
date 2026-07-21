extends Node2D

## Paint-only capture-flash wave layer (perf-pass). Lives as a child of ArenaController so the
## EXPENSIVE base fill never re-scans during the wave — only this tiny layer redraws per frame.
## Pulse starts are quantized and merged into per-row runs at play() time, so a huge capture
## draws hundreds of rects instead of thousands. State never lags: the base captured fill under
## this layer is complete from frame one; this is pure brightness on top.

var _runs: Array = []       # each element: [start_delay: float, rect: Rect2], SORTED by start
var _lo: int = 0            # active-window start: runs before it have fully faded (skipped forever)
var _elapsed: float = 0.0
var _total: float = 0.0
var _duration: float = 0.25
var _color: Color = Color(1.0, 1.0, 1.0, 0.85)


## Queues a wave. `delays` are per-cell pulse offsets (seconds); they are shifted onto this
## layer's running clock, quantized to `quantize` buckets and merged into row runs.
func play(cells: Array, delays: PackedFloat32Array, duration: float, color: Color,
		cell_size: float, origin: Vector2, quantize: float) -> void:
	_duration = maxf(duration, 0.001)
	_color = color
	var q: float = maxf(quantize, 0.001)
	var buckets: Dictionary = {}  # Vector2i(bucket, row) -> Array[int] of x columns
	for i in cells.size():
		var c: Vector2i = cells[i]
		var key := Vector2i(int(roundf((_elapsed + delays[i]) / q)), c.y)
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(c.x)
	for key in buckets:
		var xs: Array = buckets[key]
		xs.sort()
		var start: float = key.x * q
		var run_x: int = xs[0]
		var prev: int = xs[0]
		for j in range(1, xs.size() + 1):
			if j < xs.size() and xs[j] == prev + 1:
				prev = xs[j]
				continue
			_runs.append([start, Rect2(origin.x + run_x * cell_size, origin.y + key.y * cell_size,
				(prev - run_x + 1) * cell_size, cell_size)])
			if j < xs.size():
				run_x = xs[j]
				prev = xs[j]
		_total = maxf(_total, start + _duration)
	# Active-window bookkeeping (mobile perf): runs sorted by pulse start so each frame only
	# touches the currently-fading wedge — completed runs fall behind _lo, pending ones sit
	# past the first future start. Same rects, same look; just no full-list rescan per frame.
	_runs.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	_lo = 0  # re-fast-forwards next frame (a merged-in later capture may interleave starts)
	set_process(true)
	queue_redraw()


## Number of merged pulse rects queued (diagnostics/tests).
func run_count() -> int:
	return _runs.size()


func clear_wave() -> void:
	_runs.clear()
	_lo = 0
	_elapsed = 0.0
	_total = 0.0
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _total:
		clear_wave()
		return
	# Slide the window start past fully-faded runs (monotonic — they never come back).
	while _lo < _runs.size() and _runs[_lo][0] + _duration <= _elapsed:
		_lo += 1
	queue_redraw()


func _draw() -> void:
	# Only the active wedge: from the first still-fading run up to the first not-yet-started
	# one (list is sorted by start). Completed and pending runs cost nothing per frame.
	for i in range(_lo, _runs.size()):
		var r: Array = _runs[i]
		if r[0] > _elapsed:
			break  # everything after is pending (sorted)
		var local: float = _elapsed - r[0]
		if local >= _duration:
			continue  # rare straggler inside the window (interleaved merge)
		var col: Color = _color
		col.a = _color.a * (1.0 - local / _duration)
		draw_rect(r[1], col)
