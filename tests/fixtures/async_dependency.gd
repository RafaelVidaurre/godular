extends GdlrModule


func enable() -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(0.01).timeout
	GdlrTestEvents.enable_order.append("AsyncDependency")
