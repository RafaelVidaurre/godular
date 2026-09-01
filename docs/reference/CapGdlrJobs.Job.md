# CapGdlrJobs.Job

Inherits: `RefCounted`

## Signals

### `status_changed(status: int)`

## Properties

### `spec: CapGdlrJobs.JobSpec`

### `status: int`

### `error: Variant`

### `output: Variant`

### `aborted: bool`

### `promise: GdPromise`

Settles when the job completes or fails.

## Methods

### `func _init(spec: CapGdlrJobs.JobSpec) -> void`

### `func ensure_requirements() -> GdPromise`

### `func run(args: Dictionary = {}) -> GdPromise`
