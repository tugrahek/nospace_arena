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
	assert_eq(s.control_scheme, 1)  # default swipe


func test_language_sanitize_and_round_trip() -> void:
	var s := AudioSettings.new()
	assert_eq(s.language, "", "default = auto (device)")
	s.set_language("tr")
	assert_eq(s.language, "tr", "supported code sticks")
	s.set_language("xx")
	assert_eq(s.language, "", "unknown code normalizes to auto")
	s.set_language("en")
	var back := AudioSettings.from_dict(s.to_dict())
	assert_eq(back.language, "en", "language survives the dict round-trip")
	var legacy := AudioSettings.from_dict({"master": 0.5})
	assert_eq(legacy.language, "", "old settings.json without language -> auto")


func test_control_scheme_clamp_and_round_trip() -> void:
	var s := AudioSettings.new()
	s.set_control_scheme(2)
	assert_eq(s.control_scheme, 2)
	s.set_control_scheme(99)
	assert_eq(s.control_scheme, AudioSettings.SCHEME_MAX)
	s.set_control_scheme(-5)
	assert_eq(s.control_scheme, AudioSettings.SCHEME_MIN)
	s.set_control_scheme(0)
	assert_eq(AudioSettings.from_dict(s.to_dict()).control_scheme, 0)


func test_locale_preference_normalizes_and_preserves_legacy_settings() -> void:
	var settings := AudioSettings.from_dict({"language": "tr-TR", "master": 0.4, "control_scheme": 2})
	assert_eq(settings.language, "tr")
	var restored := AudioSettings.from_dict(settings.to_dict())
	assert_eq(restored.language, "tr")
	assert_almost_eq(restored.master, 0.4, 0.0001)
	assert_eq(restored.control_scheme, 2)
	settings.set_language("en_US")
	assert_eq(settings.language, "en")
	for unsupported: String in ["pt_PT", "zh_Hans", "zh_Hant", "invalid", ""]:
		settings.set_language(unsupported)
		assert_eq(settings.language, "", "unshipped preference remains auto")


func test_locale_preference_json_persistence() -> void:
	var path: String = "user://test_locale_phase_0a_settings.json"
	assert_false(FileAccess.file_exists(path), "test owns a fresh temporary file")
	if FileAccess.file_exists(path):
		return
	var settings := AudioSettings.new()
	for preference: String in LocaleUtil.SUPPORTED + [""]:
		settings.set_language(preference)
		SettingsStore.save_to(path, settings)
		assert_eq(SettingsStore.load_from(path).language, preference, "disk round-trip")
	assert_eq(DirAccess.remove_absolute(path), OK, "remove only the test-created file")
