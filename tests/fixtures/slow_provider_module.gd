extends GdlrModule

static var PROVIDERS = {
	&"slow": {
		"use": create_slow,
	},
}

static var EXPORTS = [&"slow"]

static var INJECT = [{"token": &"slow", "property": "slow"}]

var slow: String


static func create_slow() -> GdbPromise:
	GdlrTestEvents.register_order.append("SlowProvider")
	return GdbPromise.new(func(resolve: Callable, _reject: Callable) -> void:
		await (Engine.get_main_loop() as SceneTree).process_frame
		resolve.call("slow")
	)


func register() -> void:
	GdlrTestEvents.register_order.append("SlowModule")
