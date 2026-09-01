extends GdlrModule


func register() -> void:
	GdlrTestEvents.register_order.append("C")


func enable() -> void:
	GdlrTestEvents.enable_order.append("C")
