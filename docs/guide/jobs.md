# Jobs

Use jobs for work that other parts of your game need to wait for, such as loading data.
Each job runs once until you reset it. Jobs can require other jobs; Godular waits for those requirements before starting the work.

## The jobs module

Import the bundled jobs module:

```gdscript
const JobsModule = preload("res://addons/godular/built_ins/modules/jobs/md_jobs.gd")

static var IMPORTS = [JobsModule]
```

The module provides and exports {ref}`CapGdlrJobsRegistry <class_CapGdlrJobsRegistry>` and {ref}`CapGdlrJobs <class_CapGdlrJobs>`. It tree-exports `CapGdlrJobs`, so scene code can call `GdlrModuleManager.request(CapGdlrJobs)`.

## Job specifications

A specification extends `CapGdlrJobs.JobSpec`. Declare a `KEY` constant and override `_run()`:

```gdscript
class_name DependencyJob
extends CapGdlrJobs.JobSpec

const KEY := &"jobs/dependency"

func _run(_args := {}) -> GdbPromise:
	return GdbPromise.new_resolved("dependency-output")
```

```gdscript
class_name ManualJob
extends CapGdlrJobs.JobSpec

const KEY := &"jobs/manual"

func _ensure_requirements() -> GdbPromise:
	return ensure_job(DependencyJob.KEY)

func _run(_args := {}) -> GdbPromise:
	return GdbPromise.new_resolved("manual-output")

func _get_run_policy() -> CapGdlrJobs.JobRunPolicy:
	return CapGdlrJobs.JobRunPolicy.MANUAL
```

The overridable methods:

| Method | Default | Purpose |
| --- | --- | --- |
| `_run(args)` | Fails. | Does the work. Returns a promise of the output. A rejection fails the job. |
| `_ensure_requirements()` | Resolves at once. | Waits for other jobs or resources. Call `ensure_job(key)` here. |
| `_get_run_policy()` | `WHEN_REQUIRED` | When the job starts. |
| `abort_current_run()` | Does nothing. | Cancels work when `reset_job()` aborts the job. |

Inside a specification, `ensure_job()`, `get_job_output()`, and `get_job_status()` forward to the jobs service.

## Registering

Register specifications in `register()`:

```gdscript
var jobs_registry: CapGdlrJobsRegistry
var jobs: CapGdlrJobs

func register() -> void:
	jobs_registry.register_job(DependencyJob.new())
	jobs_registry.register_job(ManualJob.new())
```

`register_job()` stores the specification under its `KEY`. A later call with the same key replaces it.

## Starting jobs

`ensure_job(key)` returns a promise of the output of the job. It creates the job on the first call. What happens next depends on the run policy:

- `WHEN_REQUIRED`. The job starts at once.
- `MANUAL`. The job waits for `run_job()`. The promise from `ensure_job()` resolves after that run completes.

`run_job(key, args)` starts a `MANUAL` job and returns a promise of its output. It rejects when the job is not manual. When the job already exists and is not waiting for its start, it returns the existing promise and does not run again.

```gdscript
func enable() -> void:
	var ensured := jobs.ensure_job(ManualJob.KEY)
	jobs.run_job(ManualJob.KEY)
	print(await ensured.await_resolved())  # manual-output
	print(jobs.get_job_output(DependencyJob.KEY))  # dependency-output
```

`ManualJob` requires `DependencyJob`, so the dependency runs first.

## Status

`get_job_status(key)` returns a `JobStatus`:

| Status | Meaning |
| --- | --- |
| `WAITING_FOR_START` | The job waits for `run_job()`. |
| `WAITING_FOR_REQUIREMENTS` | The job waits for `_ensure_requirements()`. |
| `RUNNING` | `_run()` is in progress. |
| `COMPLETED` | The job completed. `get_job_output()` returns its output. |
| `FAILED` | The job failed or was aborted. |
| `NONE` | No job with that key exists. The service also reports an error. |

`get_job_output(key)` returns the output of a job. It reports an error when no job with that key exists. `has_job(key)` returns true when a job with that key exists.

## Resetting

`reset_job(key, abort_started)` clears a job so that it can run again.

- When the status is `WAITING_FOR_START`, `COMPLETED`, or `FAILED`, the service removes the job and resolves.
- When the status is `WAITING_FOR_REQUIREMENTS` or `RUNNING` and `abort_started` is false, the service reports an error and rejects.
- When the status is `WAITING_FOR_REQUIREMENTS` or `RUNNING` and `abort_started` is true, the service marks the job as aborted, calls `abort_current_run()` on the specification, sets the status to `FAILED`, removes the job, and resolves. The promise of the aborted run rejects.

The service reports an error and rejects when no job with that key exists.

After a reset, `ensure_job()` creates a new job and `_run()` runs again. An aborted job whose requirements resolve later does not resume.
