class_name LocaleUtil
extends RefCounted

## Pure language resolution for the localization system (no OS/IO — GUT-testable).
## The impure inputs (saved preference from settings.json, device locale from
## OS.get_locale_language()) are passed in by the caller (AudioManager, Step 22b).

## Languages shipped in this build. Step 26 extends this list (ES/PT-BR/DE/FR/RU/JA/KO/ZH).
const SUPPORTED: Array[String] = ["en", "tr"]
const DEFAULT: String = "en"


## Picks the active locale: an explicitly saved supported language wins; otherwise the
## device language if supported; otherwise English. "" (or any unknown value) = auto.
static func resolve(saved: String, device_language: String) -> String:
	if SUPPORTED.has(saved):
		return saved
	if SUPPORTED.has(device_language):
		return device_language
	return DEFAULT
