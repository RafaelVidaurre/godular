# CapGdlrCommandBus.CommandMeta

Inherits: `RefCounted`

## Properties

### `id: StringName`

### `correlation_id: StringName`

### `causation_id: StringName`

### `idempotency_key: StringName`

### `timeout: float`

### `actor: Dictionary`

### `route: CapGdlrCommandBus.CommandRoute`

## Methods

### `func to_dict() -> Dictionary`

### `static func from_dict(serialized: Dictionary) -> CapGdlrCommandBus.CommandMeta`
