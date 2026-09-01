# CapGdlrCommandTransport

Inherits: [GdlrCapability](GdlrCapability.md)

Capability that sends commands through registered transport adapters.

## Methods

### `func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult`

### `func register_adapter(target: StringName, adapter: GdlrCommandTransportAdapter) -> void`

### `func get_adapter(target: StringName) -> GdlrCommandTransportAdapter`
