@abstract class_name GdlrCommandHandler
extends RefCounted

## Base class for command handlers registered with the command bus.


## Handles one command envelope and returns the handler result.
@abstract func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant
