class_name LegalNotices
extends Resource

## Bundles exact third-party notices as an exported resource, including non-resource OFL files.
@export_multiline var font_notices: String
@export_multiline var gut_notices: String
@export_multiline var admob_notices: String


## Sources Godot's own and third-party license data from the running engine binary.
func build_text() -> String:
	var sections: PackedStringArray = PackedStringArray([Engine.get_license_text(), font_notices])
	if ResourceLoader.exists("res://addons/gut/gut.gd"):
		sections.append(gut_notices)
	if ResourceLoader.exists("res://addons/admob/gdscript/src/api/MobileAds.gd"):
		sections.append(admob_notices)
	for component: Dictionary in Engine.get_copyright_info():
		var notice: String = str(component["name"])
		for part: Dictionary in component["parts"]:
			notice += "\n" + "\n".join(part["copyright"])
			notice += "\n" + str(part["license"])
		sections.append(notice)
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: String in licenses:
		sections.append(license_name + "\n" + str(licenses[license_name]))
	return "\n\n".join(sections)
