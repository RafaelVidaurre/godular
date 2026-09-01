# GdlrCommandHandler

Inherits: `RefCounted`

Base class for command handlers registered with the command bus.

## Methods

### `func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant`

Handles one command envelope and returns the handler result.
