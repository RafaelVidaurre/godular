@abstract class_name CapGdlrCommandRouter
extends GdlrCapability

## Capability that plans the route for a command envelope.

@abstract func plan(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandRoute
