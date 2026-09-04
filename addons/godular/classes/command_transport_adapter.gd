@abstract class_name GdlrCommandTransportAdapter
extends Node
## Base class for command transports.
##
## A transport adapter sends command envelopes to a remote target, for
## example an HTTP or WebSocket server. Override [method _enable] and
## [method _send]. A [CapGdlrCommandTransport] service selects the adapter
## for the [member CapGdlrCommandBus.CommandRoute.target] of a command.
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html

## Emitted after [method enable] completes.
signal transport_enabled

## True after [method enable] completes. [method send] waits while this is
## false.
var enabled := false


## Sends [param envelope] through the transport and returns its result.
## The method waits for [signal transport_enabled] when the transport is not
## enabled yet. When the route configuration of the envelope has a
## [code]retry_after_extractor[/code] callable, the method applies it to the
## result. See [method CapGdlrCommandBus.CommandResult.apply_payload_retry_after_extractor].
func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult:
	if not enabled:
		await transport_enabled
	var result := await _send(envelope)
	var extractor: Callable = envelope.meta.route.route_config.get("retry_after_extractor", Callable())
	result.apply_payload_retry_after_extractor(extractor)
	return result


## Runs [method _enable], sets [member enabled], and emits
## [signal transport_enabled].
func enable() -> void:
	await _enable()
	enabled = true
	transport_enabled.emit()


## Sends [param envelope] to the remote target and returns its result.
## The method can [code]await[/code].
@abstract func _send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult
## Prepares the transport, for example opens a connection. The method can
## [code]await[/code].
@abstract func _enable() -> void
