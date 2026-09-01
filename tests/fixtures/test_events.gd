class_name GdlrTestEvents
extends RefCounted

static var register_order: Array[String] = []
static var enable_order: Array[String] = []
static var injected_service: Variant
static var injected_consumer_service: Variant


static func reset() -> void:
	register_order.clear()
	enable_order.clear()
	injected_service = null
	injected_consumer_service = null
