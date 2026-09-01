# CapGdlrCommandHandlers.LocalOutput

Inherits: `RefCounted`

Local handler output carried through command middleware and serialization.

## Properties

### `state_dispatches: Dictionary[]`

### `effects: Dictionary[]`

## Methods

### `func _init(state_dispatches_: Dictionary[] = [], effects_: Dictionary[] = []) -> void`

### `func to_dict() -> Dictionary`

### `static func from_dict(serialized: Dictionary) -> CapGdlrCommandHandlers.LocalOutput`
