# CapGdlrCommandHandlers

Inherits: [GdlrCapability](GdlrCapability.md)

Capability that registers and runs local command handlers.

## Methods

### `func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant`

### `func set_core(command: GDScript, core: Callable) -> void`

### `func use_before(command: GDScript, before: Callable) -> void`

### `func use_around(command: GDScript, around: Callable) -> void`

### `func use_after(command: GDScript, after: Callable) -> void`

### `func use(command: GDScript, middleware: GdlrCommandMiddleware, priority: int = 0) -> void`

### `func remove_by_callback(command: GDScript, callback: Callable) -> void`

### `func use_global_around(around: Callable, priority: int = 0, should_run: Callable = Callable()) -> void`

### `func remove_global_by_callback(callback: Callable) -> void`
