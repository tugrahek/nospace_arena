extends GutTest

## Pure audio-settings logic (the actual sound/mix is verified by Tuğra once assets land).

const AudioSettings = preload("res://scripts/meta/audio_settings.gd")


func test_setters_clamp_to_unit_range() -> void:
	var s := AudioSettings.new()
	s.set_master(2.0)
	s.set_sfx(-1.0)
	s.set_music(0.5)
	assert_eq(s.master, 1.0)
	assert_eq(s.sfx, 0.0)
	assert_eq(s.music, 0.5)


func test_to_db_full_is_zero() -> void:
	assert_almost_eq(AudioSettings.to_db(1.0), 0.0, 0.0001)


func test_to_db_zero_is_silence_floor() -> void:
	assert_eq(AudioSettings.to_db(0.0), AudioSettings.SILENCE_DB)


func test_to_db_half_is_negative() -> void:
	# linear_to_db(0.5) ≈ -6.0206 dB
	assert_almost_eq(AudioSettings.to_db(0.5), -6.0206, 0.001)


func test_defaults_full_unmuted() -> void:
	var s := AudioSettings.new()
	assert_eq(s.master, 1.0)
	assert_false(s.muted)


func test_dict_round_trip() -> void:
	var s := AudioSettings.new()
	s.set_master(0.7)
	s.set_sfx(0.3)
	s.set_music(0.9)
	s.set_muted(true)
	var back := AudioSettings.from_dict(s.to_dict())
	assert_almost_eq(back.master, 0.7, 0.0001)
	assert_almost_eq(back.sfx, 0.3, 0.0001)
	assert_almost_eq(back.music, 0.9, 0.0001)
	assert_true(back.muted)


func test_from_dict_defaults_on_missing_keys() -> void:
	var s := AudioSettings.from_dict({})
	assert_eq(s.master, 1.0)
	assert_eq(s.sfx, 1.0)
	assert_eq(s.music, 1.0)
	assert_false(s.muted)
