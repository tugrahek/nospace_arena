class_name LocaleFonts
extends RefCounted

## Shared Latin faces keep their typography; the active locale selects CJK outlines.
## Godot's font-language matching reduces zh_Hans/zh_Hant to zh, so ordering is explicit.
const REGIONS: Dictionary[String, String] = {
	"ja": "jp", "ko": "kr", "zh_Hans": "sc", "zh_Hant": "tc",
}
const LATIN_PATHS: Array[String] = [
	"res://assets/fonts/nunitosans/nunitosans-variable.ttf",
	"res://assets/fonts/rubik/rubik-variable.ttf",
	"res://assets/fonts/dynapuff/dynapuff-variable.ttf",
]
const SCRIPT_FONTS: Dictionary[String, String] = {
	"hi": "res://assets/fonts/notosansdevanagari/font.ttf",
	"th": "res://assets/fonts/notosansthai/font.ttf",
	"ar": "res://assets/fonts/notosansarabic/font.ttf",
}
# Retain faces configured before their first scene loads; ResourceLoader's cache is weak.
static var _faces: Array[FontFile] = []


## Configures bundled fallbacks on startup/live switching; import order and saves stay independent.
static func apply(locale: String) -> void:
	if _faces.is_empty():
		for path: String in LATIN_PATHS:
			_faces.append(load(path))
	var first: String = REGIONS.get(LocaleUtil.supported_locale(locale), "jp")
	var fallbacks: Array[Font] = [_regional_font(first)]
	for region: String in REGIONS.values():
		if region != first:
			fallbacks.append(_regional_font(region))
	for path: String in SCRIPT_FONTS.values():
		fallbacks.append(load(path))
	var display_fallbacks: Array[Font] = [load("res://assets/fonts/uiextended/nospace-ui-extended.ttf")]
	display_fallbacks.append_array(fallbacks)
	for index: int in _faces.size():
		var font: FontFile = _faces[index]
		# Match heading metrics while supplying missing Cyrillic/Vietnamese glyphs.
		var chain: Array[Font] = fallbacks if index == 0 else display_fallbacks
		if font.fallbacks != chain:
			font.fallbacks = chain


## Endonyms use their own region even when the surrounding UI uses a different language.
static func endonym_font(locale: String) -> Font:
	var font: FontFile = load(LATIN_PATHS[0]).duplicate()
	font.fallbacks = [load(SCRIPT_FONTS[locale])] if SCRIPT_FONTS.has(locale) else [_regional_font(REGIONS[locale])]
	return font


static func _regional_font(region: String) -> FontFile:
	return load("res://assets/fonts/cjk/nospace-cjk-%s.otf" % region)
