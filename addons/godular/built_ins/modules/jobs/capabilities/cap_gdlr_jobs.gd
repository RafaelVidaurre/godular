@abstract class_name CapGdlrJobs
extends GdlrCapability


enum JobStatus {
	NONE = -1,
	## The job waits for an explicit start.
	WAITING_FOR_START,
	## The job waits for its requirements.
	WAITING_FOR_REQUIREMENTS,
	RUNNING,
	COMPLETED,
	FAILED,
}

enum JobRunPolicy {
	## Runs when `ensure_job` requests it.
	WHEN_REQUIRED,
	## Runs only through `run_job`.
	MANUAL,
}


@abstract func run_job(key: StringName, args := {}) -> GdPromise
@abstract func ensure_job(key: StringName) -> GdPromise
## Clears a job. `abort_started` also clears an active job.
@abstract func reset_job(key: StringName, abort_started := false) -> GdPromise
@abstract func get_job_output(key: StringName) -> Variant
@abstract func get_job_status(key: StringName) -> JobStatus
## Returns true after a job is created.
@abstract func has_job(key: StringName) -> bool


class JobSpec:
	var _svc_jobs: CapGdlrJobs


	func get_key() -> StringName:
		var JobSpecScript: GDScript = get_script()
		var job_has_key: bool = "KEY" in JobSpecScript
		assert(job_has_key, "Job spec must have a KEY constant")
		return JobSpecScript.KEY


	func initialize(svc_jobs: CapGdlrJobs) -> void:
		_svc_jobs = svc_jobs


	func ensure_requirements() -> GdPromise:
		return _ensure_requirements()


	func run(args := {}) -> GdPromise:
		return _run(args)


	func abort_current_run() -> void:
		pass


	func get_job_output(key: StringName) -> Variant:
		return _svc_jobs.get_job_output(key)


	func get_job_status(key: StringName) -> CapGdlrJobs.JobStatus:
		return _svc_jobs.get_job_status(key)


	## Resolves after a required job completes.
	func ensure_job(key: StringName) -> GdPromise:
		return _svc_jobs.ensure_job(key)


	func get_run_policy() -> JobRunPolicy:
		return _get_run_policy()


	func _run(args := {}) -> GdPromise:
		assert(false, "Subclass must implement _run")
		return null


	func _ensure_requirements() -> GdPromise:
		return GdPromise.new_resolved()


	func _get_run_policy() -> JobRunPolicy:
		return JobRunPolicy.WHEN_REQUIRED


class Job:
	signal status_changed(status: JobStatus)

	var spec: CapGdlrJobs.JobSpec
	var status := JobStatus.WAITING_FOR_START:
		set(value):
			status = value
			status_changed.emit(value)
	var error: Variant = null
	var output: Variant = null
	var aborted := false
	## Settles when the job completes or fails.
	var promise := GdPromise.new(func(resolve, reject):
		while true:
			var status: JobStatus = await status_changed
			if status == JobStatus.COMPLETED:
				resolve.call(output)
				return

			if status == JobStatus.FAILED:
				reject.call(error)
				return
	)


	func _init(spec: CapGdlrJobs.JobSpec) -> void:
		self .spec = spec


	func ensure_requirements() -> GdPromise:
		var ensuring_requirements_promise := spec.ensure_requirements()
		status = JobStatus.WAITING_FOR_REQUIREMENTS
		ensuring_requirements_promise.catch(func(error_: Variant):
			error = error_
			status = JobStatus.FAILED
		)

		return ensuring_requirements_promise


	func run(args := {}) -> GdPromise:
		var running_job_promise := spec.run(args)
		status = JobStatus.RUNNING

		running_job_promise.then(func(output_: Variant):
			output = output_
			status = JobStatus.COMPLETED
		).catch(func(error_: Variant):
			error = error_
			status = JobStatus.FAILED
		)

		return promise
