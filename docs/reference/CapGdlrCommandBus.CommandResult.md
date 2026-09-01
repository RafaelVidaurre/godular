# CapGdlrCommandBus.CommandResult

Inherits: `RefCounted`

## Constants

- `RATE_LIMITED_REASON` = `"RATE_LIMITED"`
- `RETRY_AFTER_SOURCE_NONE` = `&""`
- `RETRY_AFTER_SOURCE_RATE_LIMIT` = `&"rate_limit"`

## Properties

### `ok: bool`

### `status: int`

### `reason: String`

### `payload: Variant`

### `metadata: Dictionary`

### `retry_after_s: float`

### `retry_after_source: StringName`

### `rate_limit: CapGdlrCommandBus.RateLimitInfo`

Optional rate-limit details for NACK results created by command-level rate limiting.

## Methods

### `func _init(ok_: bool, status_: int, reason_: String, payload_: Variant, metadata_: Dictionary = {}, rate_limit_: CapGdlrCommandBus.RateLimitInfo = null, retry_after_s_: float = -1.0, retry_after_source_: StringName = &"") -> void`

### `static func rate_limited(retry_after_s: float = -1.0, policy_id: StringName = &"", message: String = "RATE_LIMITED") -> CapGdlrCommandBus.CommandResult`

Builds the standard command result for a rate-limited command attempt.

### `func is_rate_limited() -> bool`

Returns true when this result was produced by command rate limiting.

### `func get_retry_after_s(default_value: float = -1.0) -> float`

Returns the normalized retry-after value for this command result.

### `func set_retry_after_s(value: float, source: StringName) -> void`

Sets retry guidance after command or transport-specific parsing has normalized it.

### `func apply_payload_retry_after_extractor(extractor: Callable) -> void`

Applies route-provided retry parsing to this result's decoded payload.

### `func get_rate_limit_info() -> CapGdlrCommandBus.RateLimitInfo`

Returns typed rate-limit details, if this result has them.

### `func to_dict() -> Dictionary`

### `static func from_dict(serialized: Dictionary, CommandClass: GDScript = null) -> CapGdlrCommandBus.CommandResult`
