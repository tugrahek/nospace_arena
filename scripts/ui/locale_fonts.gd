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


## Configures bundled fallbacks on startup/live switching; import order and saves stay independent.
static func apply(locale: String) -> void:
	var first: String = REGIONS.get(LocaleUtil.supported_locale(locale), "jp")
	var fallbacks: Array[Font] = [_regional_font(first)]
	for region: String in REGIONS.values():
		if region != first:
			fallbacks.append(_regional_font(region))
	var display_fallbacks: Array[Font] = [load("res://assets/fonts/uiextended/nospace-ui-extended.ttf")]
	display_fallbacks.append_array(fallbacks)
	for path: String in LATIN_PATHS:
		var font: FontFile = load(path)
		# Match heading metrics while supplying missing Cyrillic/Vietnamese glyphs.
		var chain: Array[Font] = fallbacks if path == LATIN_PATHS[0] else display_fallbacks
		if font.fallbacks != chain:
			font.fallbacks = chain


## Endonyms use their own region even when the surrounding UI uses a different language.
static func endonym_font(locale: String) -> Font:
	var font: FontFile = load(LATIN_PATHS[0]).duplicate()
	font.fallbacks = [_regional_font(REGIONS[locale])]
	return font


static func _regional_font(region: String) -> FontFile:
	return load("res://assets/fonts/cjk/nospace-cjk-%s.otf" % region)
