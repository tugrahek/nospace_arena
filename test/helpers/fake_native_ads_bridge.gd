class_name FakeNativeAdsBridge
extends RefCounted

## Deterministic SDK boundary double; never invokes native APIs or writes storage.
var available: bool = true
var current_consent: Dictionary = {
	"allowed": false, "form_required": false, "form_available": false, "privacy_required": false,
}
var initializations: Array[Callable] = []
var loads: Array[Dictionary] = []
var shows: Array[Dictionary] = []
var destroyed: Array[Object] = []
var updates: Array[Dictionary] = []
var required_forms: Array[Dictionary] = []
var privacy_forms: Array[Callable] = []


## Reports whether this double represents an installed native SDK.
func is_native_available() -> bool:
	return available


## Records initialization without completing it automatically.
func initialize(completed: Callable) -> void:
	initializations.append(completed)


## Captures independent callbacks for each native load.
func load_rewarded(ad_unit_id: String, loaded: Callable, failed: Callable) -> void:
	loads.append({"id": ad_unit_id, "loaded": loaded, "failed": failed})


## Captures independent callbacks for each presentation.
func show_rewarded(ad: Object, rewarded: Callable, closed: Callable, failed: Callable) -> void:
	shows.append({"ad": ad, "rewarded": rewarded, "closed": closed, "failed": failed})


## Records native disposal for superseded/consumed ad checks.
func destroy_rewarded(ad: Object) -> void:
	destroyed.append(ad)


## Captures the one-per-session consent update.
func update_consent(updated: Callable, failed: Callable) -> void:
	updates.append({"updated": updated, "failed": failed})


## Returns current SDK state rather than a project-side preference.
func consent_state() -> Dictionary:
	return current_consent.duplicate()


## Captures required-form outcomes independently of the update callback.
func show_required_consent(completed: Callable, failed: Callable) -> void:
	required_forms.append({"completed": completed, "failed": failed})


## Captures privacy-options dismissal.
func show_privacy_options(completed: Callable) -> void:
	privacy_forms.append(completed)


## Releases callback references retained by the double after each fixture.
func release_callbacks() -> void:
	initializations.clear()
	loads.clear()
	shows.clear()
	updates.clear()
	required_forms.clear()
	privacy_forms.clear()
	destroyed.clear()
