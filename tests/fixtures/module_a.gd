extends GdlrModule

const ModuleB = preload("res://tests/fixtures/module_b.gd")
const ModuleC = preload("res://tests/fixtures/module_c.gd")

static var IMPORTS = [ModuleB, ModuleC]


func register() -> void:
	GdlrTestEvents.register_order.append("A")


func enable() -> void:
	GdlrTestEvents.enable_order.append("A")
