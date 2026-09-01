extends GdlrModule

const ModuleD = preload("res://tests/fixtures/module_d.gd")

static var IMPORTS = [ModuleD]


func register() -> void:
	GdlrTestEvents.register_order.append("B")


func enable() -> void:
	GdlrTestEvents.enable_order.append("B")
