@abstract class_name GdlrCommandTransportAdapter
extends Node

signal transport_enabled

var enabled := false


func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult:
	if not enabled:
		await transport_enabled
	var result := await _send(envelope)
	var extractor: Callable = envelope.meta.route.route_config.get("retry_after_extractor", Callable())
	result.apply_payload_retry_after_extractor(extractor)
	return result


func enable() -> void:
	await _enable()
	enabled = true
	transport_enabled.emit()


@abstract func _send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult
@abstract func _enable() -> void
