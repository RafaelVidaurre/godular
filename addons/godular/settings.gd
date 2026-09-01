@tool
extends Object

const EDITOR_ROOT_MODULE_PATH_KEY := "godular/editor_root_module_path"

static var editor_root_module_path: String:
	get:
		return ProjectSettings.get_setting(EDITOR_ROOT_MODULE_PATH_KEY, "")


static func _static_init() -> void:
	if not ProjectSettings.has_setting(EDITOR_ROOT_MODULE_PATH_KEY):
		ProjectSettings.set_setting(EDITOR_ROOT_MODULE_PATH_KEY, "")
	ProjectSettings.add_property_info({
		"name": EDITOR_ROOT_MODULE_PATH_KEY,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.gd",
	})
