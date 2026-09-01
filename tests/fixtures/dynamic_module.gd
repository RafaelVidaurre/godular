extends GdlrModule

static var PROVIDERS = {
	&"setting": {
		"use": "static",
	},
}

static var TREE_EXPORTS = [&"setting"]


static func for_root(value: String) -> GdlrModuleDefinition:
	var definition := GdlrModuleDefinition.new()
	definition.ModuleScript = load("res://tests/fixtures/dynamic_module.gd")
	definition.providers({
		&"setting": {
			"use": value,
		},
	})
	return definition
