# CapGdlrCommandBus.RateLimitInfo

Inherits: `RefCounted`

## Properties

### `limited: bool`

True when the command result represents a rate-limited attempt.

### `policy_id: StringName`

Stable identifier for the policy bucket that limited the command.

## Methods

### `func _init(limited_: bool = false, policy_id_: StringName = &"") -> void`

### `func to_dict() -> Dictionary`

### `static func from_dict(serialized: Dictionary) -> CapGdlrCommandBus.RateLimitInfo`
