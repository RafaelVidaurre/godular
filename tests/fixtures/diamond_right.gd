extends GdlrModule

const SlowProviderModule = preload("res://tests/fixtures/slow_provider_module.gd")

static var IMPORTS = [SlowProviderModule]
static var INJECT = [{"token": &"slow", "property": "slow"}]

var slow: String


func register() -> void:
	GdlrTestEvents.register_order.append("Right")
