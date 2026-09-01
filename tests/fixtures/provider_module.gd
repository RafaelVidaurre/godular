extends GdlrModule

static var PROVIDERS = {
	GdlrTestCapability: {
		"use": GdlrTestService,
	},
}

static var EXPORTS = [GdlrTestCapability]
static var TREE_EXPORTS = [GdlrTestCapability]

var service: GdlrTestCapability


func register() -> void:
	GdlrTestEvents.injected_service = service
	var consumer := GdlrTestConsumer.new()
	inject_dependencies(consumer)
	GdlrTestEvents.injected_consumer_service = consumer.service
