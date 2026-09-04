@abstract class_name CapGdlrJobs
extends GdlrCapability
## Capability that runs jobs and tracks their status.
##
## A job is a unit of work described by a [CapGdlrJobs.JobSpec]. Jobs can
## require other jobs, and Godular runs the requirements first. Each job runs
## once until [method reset_job] clears it.
## [br][br]
## Import the bundled jobs module to get this capability, then register
## specifications through [CapGdlrJobsRegistry]:
## [codeblock]
## const JobsModule = preload("res://addons/godular/built_ins/modules/jobs/md_jobs.gd")
##
## static var IMPORTS = [JobsModule]
##
## var jobs_registry: CapGdlrJobsRegistry
## var jobs: CapGdlrJobs
##
## func register() -> void:
##     jobs_registry.register_job(LoadSaveJob.new())
##
## func enable() -> void:
##     var save_data = await jobs.ensure_job(LoadSaveJob.KEY).await_resolved()
## [/codeblock]
## The jobs module exports [CapGdlrJobs] as a tree export, so scene code can
## also call [method GdlrModuleManager.request] with it.
##
## @tutorial(Jobs): https://rafaelvidaurre.github.io/godular/guide/jobs.html


## Status of a job.
enum JobStatus {
	## No job with that key has run. See [method get_job_status].
	NONE = -1,
	## The job waits for [method run_job].
	WAITING_FOR_START,
	## The job waits for its requirements.
	WAITING_FOR_REQUIREMENTS,
	## The job runs.
	RUNNING,
	## The job completed. [method get_job_output] returns its output.
	COMPLETED,
	## The job failed or was aborted.
	FAILED,
}

## When a job starts.
enum JobRunPolicy {
	## The job starts when [method ensure_job] first requests it.
	WHEN_REQUIRED,
	## The job starts only through [method run_job]. [method ensure_job]
	## waits for that call.
	MANUAL,
}


## Starts a [constant MANUAL] job and returns a promise of its
## output. The promise rejects when the job is not manual. A job that
## already ran returns its existing promise.
@abstract func run_job(key: StringName, args := {}) -> GdPromise
## Returns a promise of the output of the job with [param key]. Creates the
## job on the first call. A [constant WHEN_REQUIRED] job starts
## immediately. A [constant MANUAL] job starts on
## [method run_job].
@abstract func ensure_job(key: StringName) -> GdPromise
## Clears the job with [param key] so that it can run again. A job that
## waits for its start, completed, or failed is cleared at once. For a job
## that waits for requirements or runs, the method fails unless
## [param abort_started] is true. Then it calls
## [method CapGdlrJobs.JobSpec.abort_current_run], marks the job as failed,
## and clears it.
@abstract func reset_job(key: StringName, abort_started := false) -> GdPromise
## Returns the output of the completed job with [param key]. Fails when no
## job with that key ran.
@abstract func get_job_output(key: StringName) -> Variant
## Returns the status of the job with [param key]. When no job with that
## key ran, the method reports an error and returns [constant NONE].
@abstract func get_job_status(key: StringName) -> JobStatus
## Returns true when a job with [param key] exists.
@abstract func has_job(key: StringName) -> bool


## Describes one job.
##
## Extend it, declare a [code]KEY[/code] constant, and override
## [method _run]:
## [codeblock]
## class_name LoadSaveJob
## extends CapGdlrJobs.JobSpec
##
## const KEY := &"save/load"
##
## func _ensure_requirements() -> GdPromise:
##     return ensure_job(MountStorageJob.KEY)
##
## func _run(args := {}) -> GdPromise:
##     return GdPromise.new_resolved(load_save())
## [/codeblock]
## Register the specification with [method CapGdlrJobsRegistry.register_job].
class JobSpec:
	var _svc_jobs: CapGdlrJobs


	## Returns the [code]KEY[/code] constant of the specification.
	func get_key() -> StringName:
		var JobSpecScript: GDScript = get_script()
		var job_has_key: bool = "KEY" in JobSpecScript
		assert(job_has_key, "Job spec must have a KEY constant")
		return JobSpecScript.KEY


	## Connects the specification to the jobs service. The service calls it
	## before the job starts.
	func initialize(svc_jobs: CapGdlrJobs) -> void:
		_svc_jobs = svc_jobs


	## Returns a promise that resolves when the requirements are met. See
	## [method _ensure_requirements].
	func ensure_requirements() -> GdPromise:
		return _ensure_requirements()


	## Runs the job. See [method _run].
	func run(args := {}) -> GdPromise:
		return _run(args)


	## Stops the current run. [method CapGdlrJobs.reset_job] calls it when it
	## aborts the job. Override it to cancel work. The default does nothing.
	func abort_current_run() -> void:
		pass


	## Returns the output of another job. See
	## [method CapGdlrJobs.get_job_output].
	func get_job_output(key: StringName) -> Variant:
		return _svc_jobs.get_job_output(key)


	## Returns the status of another job. See
	## [method CapGdlrJobs.get_job_status].
	func get_job_status(key: StringName) -> CapGdlrJobs.JobStatus:
		return _svc_jobs.get_job_status(key)


	## Returns a promise of the output of another job. See
	## [method CapGdlrJobs.ensure_job]. Use it in [method _ensure_requirements].
	func ensure_job(key: StringName) -> GdPromise:
		return _svc_jobs.ensure_job(key)


	## Returns the run policy. See [method _get_run_policy].
	func get_run_policy() -> JobRunPolicy:
		return _get_run_policy()


	## Override it to do the work. Return a promise of the job output. Reject
	## the promise to fail the job.
	func _run(args := {}) -> GdPromise:
		assert(false, "Subclass must implement _run")
		return null


	## Override it to wait for other jobs or resources before [method _run].
	## The default resolves at once.
	func _ensure_requirements() -> GdPromise:
		return GdPromise.new_resolved()


	## Override it to change when the job starts. The default is
	## [constant CapGdlrJobs.WHEN_REQUIRED].
	func _get_run_policy() -> JobRunPolicy:
		return JobRunPolicy.WHEN_REQUIRED


## One run of a job specification.
##
## The jobs service creates jobs. Read them for status, output, and errors.
class Job:
	## Emitted when [member status] changes.
	signal status_changed(status: JobStatus)

	## The specification of the job.
	var spec: CapGdlrJobs.JobSpec
	## The current status. Setting it emits [signal status_changed].
	var status := JobStatus.WAITING_FOR_START:
		set(value):
			status = value
			status_changed.emit(value)
	## The rejection reason after a failure.
	var error: Variant = null
	## The output after completion.
	var output: Variant = null
	## True after [method CapGdlrJobs.reset_job] aborted the job.
	var aborted := false
	## Resolves with [member output] when the job completes. Rejects with
	## [member error] when the job fails.
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


	## Creates a job for [param spec].
	func _init(spec: CapGdlrJobs.JobSpec) -> void:
		self .spec = spec


	## Sets the status to [constant CapGdlrJobs.WAITING_FOR_REQUIREMENTS] and
	## waits for the requirements of the specification. A rejection fails
	## the job.
	func ensure_requirements() -> GdPromise:
		var ensuring_requirements_promise := spec.ensure_requirements()
		status = JobStatus.WAITING_FOR_REQUIREMENTS
		ensuring_requirements_promise.catch(func(error_: Variant):
			error = error_
			status = JobStatus.FAILED
		)

		return ensuring_requirements_promise


	## Sets the status to [constant CapGdlrJobs.RUNNING], runs the
	## specification, and returns [member promise].
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
