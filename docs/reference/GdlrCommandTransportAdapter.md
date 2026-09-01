# GdlrCommandTransportAdapter

Inherits: `Node`

Base class for command transports. Override `_send` and `_enable`.

## Signals

### `transport_enabled()`

Emitted after `enable()` completes.

## Properties

### `enabled: bool`

True after the transport is enabled. `send()` waits while this is false.

## Methods

### `func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult`

Sends a command envelope through the transport and returns its result.

### `func enable() -> void`

Runs the transport setup and unblocks queued `send()` calls.
