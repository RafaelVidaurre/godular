@abstract class_name GdlrCommandTransportAdapter
extends Node

## Base class for command transports. Override `_send` and `_enable`.

## Emitted after `enable()` completes.
signal transport_enabled

## True after the transport is enabled. `send()` waits while this is false.
var enabled := false


## Sends a command envelope through the transport and returns its result.
func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult:
	if not enabled:
		await transport_enabled
	var result := await _send(envelope)
	var extractor: Callable = envelope.meta.route.route_config.get("retry_after_extractor", Callable())
	result.apply_payload_retry_after_extractor(extractor)
	return result


## Runs the transport setup and unblocks queued `send()` calls.
func enable() -> void:
	await _enable()
	enabled = true
	transport_enabled.emit()


@abstract func _send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult
@abstract func _enable() -> void
