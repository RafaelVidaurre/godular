# CapGdlrCommandBus

Inherits: [GdlrCapability](GdlrCapability.md)

Capability that dispatches commands and defines the command data types.

## Enumerations

### `CommandStatus`

- `NACK` = `0`
- `ACK` = `1`
- `TIMEOUT` = `2`

### `ExecKind`

- `NONE` = `-1`
- `LOCAL` = `0`
- `REMOTE` = `1`
- `DUAL_LOCAL_FIRST` = `2`
- `DUAL_REMOTE_FIRST` = `3`

## Methods

### `func use(middleware: Callable) -> void`

### `func clear_middleware() -> void`

### `func dispatch(command_or_envelope: Variant, meta_params: Dictionary = {}) -> CapGdlrCommandBus.CommandResult`
