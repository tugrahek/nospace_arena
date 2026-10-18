class_name LocaleUtil
extends RefCounted

## Locale resolution without OS/IO. AudioManager supplies the saved preference and
## OS.get_locale(); Godot supplies canonical locale codes and script defaults.

## Only translated languages ship. Future script/region locales belong here once ready.
const SUPPORTED: Array[String] = ["en", "tr", "de", "fr", "es", "pt_BR", "it"]
const DEFAULT: String = "en"


## Saved preference wins over the full device locale, then English. The optional catalog
## allows testing future variants without registering or exposing untranslated languages.
static func resolve(saved: String, device_locale: String,
		available: Array[String] = SUPPORTED) -> String:
	var preference: String = supported_locale(saved, available)
	if not preference.is_empty():
		return preference
	var device: String = supported_locale(device_locale, available)
	if not device.is_empty():
		return device
	return DEFAULT


## Standardizes separators/casing without dropping an explicit script or region.
static func normalize(locale: String) -> String:
	var value: String = locale.strip_edges()
	return "" if value.is_empty() else TranslationServer.standardize_locale(value)


## Returns a shipped locale or "" (auto). Exact locale wins; script/region reductions
## never select an unrelated regional variant, e.g. pt_PT must not select pt_BR.
static func supported_locale(locale: String, available: Array[String] = SUPPORTED) -> String:
	var canonical: String = normalize(locale)
	if canonical.is_empty():
		return ""
	if available.has(canonical):
		return canonical
	var parts: PackedStringArray = canonical.split("_")
	var language: String = parts[0]
	# Godot infers Hans/Hant from Chinese regions while honoring an explicit script.
	var expanded: PackedStringArray = TranslationServer.standardize_locale(canonical, true).split("_")
	for part: String in expanded:
		if part.length() == 4 and available.has(language + "_" + part):
			return language + "_" + part
	for part: String in parts:
		if part.length() == 2 and part == part.to_upper() and available.has(language + "_" + part):
			return language + "_" + part
	return language if available.has(language) else ""
