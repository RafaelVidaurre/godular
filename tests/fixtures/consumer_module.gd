extends GdlrModule

const ProviderModule = preload("res://tests/fixtures/provider_module.gd")

static var IMPORTS = [ProviderModule]

static var PROVIDERS = {
	&"summary": {
		"inject": [GdlrTestCapability],
		"use": create_summary,
	},
}

static var TREE_EXPORTS = [&"summary"]


static func create_summary(service: GdlrTestCapability) -> String:
	return (service as GdlrTestService).value
