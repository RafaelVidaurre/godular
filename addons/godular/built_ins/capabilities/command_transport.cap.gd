@abstract class_name CapGdlrCommandTransport
extends GdlrCapability

@abstract func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult
@abstract func register_adapter(target: StringName, adapter: GdlrCommandTransportAdapter) -> void
@abstract func get_adapter(target: StringName) -> GdlrCommandTransportAdapter
