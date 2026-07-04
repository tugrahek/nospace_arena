extends GutHookScript

## Pins the test run to English. With the TR translation registered (Step 22), Godot would
## otherwise pick the OS locale at startup — and every test asserting English UI text would
## fail on a Turkish machine. Tests that exercise other locales set (and restore) their own.


func run() -> void:
	TranslationServer.set_locale("en")
