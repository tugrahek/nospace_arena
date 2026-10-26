extends SceneTree

## Captures normal Free gameplay through keyboard input, with no state/score/grid fixtures.
## Run with a real renderer and isolated APPDATA; output is a native 1080x1920 viewport.
const OUTPUT: String = "res://docs/play-store/screenshots"
var _viewport: SubViewport
var _captures: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1080, 1920)
	_viewport.size_2d_override = Vector2i(720, 1280)
	_viewport.size_2d_override_stretch = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	var modes_only: bool = "--modes-only" in OS.get_cmdline_user_args()
	if modes_only:
		var previous: Array = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT.path_join("capture-provenance.json")))
		for item: Dictionary in previous:
			if str(item.file).ends_with("-01.png") or str(item.file).ends_with("-02.png"):
				_captures.append(item)
	for locale: String in ["en", "tr"]:
		root.get_node("AudioManager").set_language(locale)
		if not modes_only:
			await _capture_gameplay(locale)
		await _capture_modes(locale)
	var log: FileAccess = FileAccess.open(OUTPUT.path_join("capture-provenance.json"), FileAccess.WRITE)
	log.store_string(JSON.stringify(_captures, "\t"))
	quit()


func _capture_gameplay(locale: String) -> void:
	root.get_node("SeedManager").enter_free()
	var game: Node = load("res://scenes/main/Game.tscn").instantiate()
	_viewport.add_child(game)
	await create_timer(0.5).timeout
	await _hold(KEY_RIGHT, 1.25)
	await _hold(KEY_DOWN, 2.0)
	await _save(locale, 1)
	await _hold(KEY_DOWN, 3.2)
	await _save(locale, 2)
	game.queue_free()
	await process_frame


func _capture_modes(locale: String) -> void:
	var picker: Control = load("res://scenes/ui/ModeSelect.tscn").instantiate()
	_viewport.add_child(picker)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var image: Image = _viewport.get_texture().get_image()
	assert(image.get_size() == Vector2i(1080, 1920))
	image.convert(Image.FORMAT_RGB8)
	var filename: String = "mode-select-%s.png" % locale
	assert(image.save_png(OUTPUT.path_join(filename)) == OK)
	_captures.append({"file": filename, "width": 1080, "height": 1920,
		"renderer": RenderingServer.get_current_rendering_method(), "platform": OS.get_name(),
		"locale": locale, "screen": "ModeSelect", "upscaled_bitmap": false,
		"source": "unmodified ModeSelect scene with default isolated save"})
	picker.queue_free()
	await process_frame


func _hold(key: Key, seconds: float) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(seconds).timeout
	event = InputEventKey.new()
	event.keycode = key
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _save(locale: String, index: int) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = _viewport.get_texture().get_image()
	assert(image.get_size() == Vector2i(1080, 1920))
	image.convert(Image.FORMAT_RGB8)
	var filename: String = "gameplay-%s-%02d.png" % [locale, index]
	assert(image.save_png(OUTPUT.path_join(filename)) == OK)
	var state: Node = root.get_node("GameState")
	_captures.append({"file": filename, "width": 1080, "height": 1920,
		"renderer": RenderingServer.get_current_rendering_method(), "platform": OS.get_name(),
		"locale": locale, "score": state.get_score(), "lives": state.lives,
		"state": state.status, "upscaled_bitmap": false, "source": "normal Free run + keyboard input"})
	print("STORE_CAPTURE ", filename, " score=", state.get_score(), " lives=", state.lives)
