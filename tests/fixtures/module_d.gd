extends GdlrModule


func register() -> void:
	GdlrTestEvents.register_order.append("D")


func enable() -> void:
	GdlrTestEvents.enable_order.append("D")
