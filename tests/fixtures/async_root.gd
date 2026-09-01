extends GdlrModule

const AsyncDependency = preload("res://tests/fixtures/async_dependency.gd")

static var IMPORTS = [AsyncDependency]


func enable() -> void:
	GdlrTestEvents.enable_order.append("AsyncRoot")
