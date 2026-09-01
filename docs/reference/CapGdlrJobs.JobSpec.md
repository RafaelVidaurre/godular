# CapGdlrJobs.JobSpec

Inherits: `RefCounted`

## Methods

### `func get_key() -> StringName`

### `func initialize(svc_jobs: CapGdlrJobs) -> void`

### `func ensure_requirements() -> GdPromise`

### `func run(args: Dictionary = {}) -> GdPromise`

### `func abort_current_run() -> void`

### `func get_job_output(key: StringName) -> Variant`

### `func get_job_status(key: StringName) -> int`

### `func ensure_job(key: StringName) -> GdPromise`

Resolves after a required job completes.

### `func get_run_policy() -> int`
