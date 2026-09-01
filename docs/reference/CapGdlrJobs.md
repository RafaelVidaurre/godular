# CapGdlrJobs

Inherits: [GdlrCapability](GdlrCapability.md)

Capability that starts jobs and tracks their progress.

## Enumerations

### `JobStatus`

- `NONE` = `-1`
- `WAITING_FOR_START` = `0` — The job waits for an explicit start.
- `WAITING_FOR_REQUIREMENTS` = `1` — The job waits for its requirements.
- `RUNNING` = `2`
- `COMPLETED` = `3`
- `FAILED` = `4`

### `JobRunPolicy`

- `WHEN_REQUIRED` = `0` — Runs when `ensure_job` requests it.
- `MANUAL` = `1` — Runs only through `run_job`.

## Methods

### `func run_job(key: StringName, args: Dictionary = {}) -> GdPromise`

### `func ensure_job(key: StringName) -> GdPromise`

### `func reset_job(key: StringName, abort_started: bool = false) -> GdPromise`

Clears a job. `abort_started` also clears an active job.

### `func get_job_output(key: StringName) -> Variant`

### `func get_job_status(key: StringName) -> int`

### `func has_job(key: StringName) -> bool`

Returns true after a job is created.
