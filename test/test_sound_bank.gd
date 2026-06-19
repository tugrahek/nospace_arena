extends GutTest

## SoundBank asset binding: every event key resolves to a stream, unknown keys stay null,
## and the menu track is set to loop (else it would play once and stop).

const BANK_PATH := "res://config/sound_bank.tres"


func test_sfx_keys_bound() -> void:
	var bank: Resource = load(BANK_PATH)
	assert_not_null(bank.sfx("capture"), "capture")
	assert_not_null(bank.sfx("life_loss"), "life_loss")
	assert_not_null(bank.sfx("near_miss"), "near_miss")
	assert_not_null(bank.sfx("ui_tap"), "ui_tap")


func test_music_key_bound() -> void:
	assert_not_null(load(BANK_PATH).music("menu"), "menu music")


func test_unknown_key_is_null() -> void:
	var bank: Resource = load(BANK_PATH)
	assert_null(bank.sfx("nope"))
	assert_null(bank.music("nope"))


func test_menu_music_loops_after_play() -> void:
	# AudioManager enforces looping when it starts the music (import flag isn't reliable
	# headless/exported). After play_music, the (shared) menu stream loops forward over a
	# valid range (loop_end == 0 + FORWARD would play silence — the bug this guards).
	AudioManager.play_music("menu")
	var stream: AudioStream = load(BANK_PATH).music("menu")
	assert_true(stream is AudioStreamWAV, "menu music is a WAV")
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "menu music must loop forward")
	assert_gt(stream.loop_end, stream.loop_begin, "loop range must be non-empty")
