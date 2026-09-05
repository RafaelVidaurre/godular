extends CapGdlrJobs

var _job_registry: CapGdlrJobsRegistry
var _jobs: Dictionary[StringName, CapGdlrJobs.Job] = {}


func _init(job_registry: CapGdlrJobsRegistry) -> void:
	_job_registry = job_registry


## Runs a manual job once and resolves with its output.
func run_job(key: StringName, args := {}) -> GdbPromise:
	var job_spec: CapGdlrJobs.JobSpec = _job_registry.get_job(key)
	assert(job_spec != null, "Job spec not found in jobs registry: %s" % key)

	if job_spec.get_run_policy() != JobRunPolicy.MANUAL:
		return GdbPromise.new_rejected("Job %s is not runnable on demand" % key)

	_create_job(job_spec)

	return _start_job(job_spec, args)


func get_job_output(key: StringName) -> Variant:
	var job: CapGdlrJobs.Job = _jobs.get(key)
	if job == null:
		var msg := "No job with key %s has been run yet" % key
		assert(false, msg)
		push_error(msg)
		return null

	return job.output


func get_job_status(key: StringName) -> CapGdlrJobs.JobStatus:
	var job: CapGdlrJobs.Job = _jobs.get(key)
	if job == null:
		var msg := "No job with key %s has been run yet" % key
		assert(false, msg)
		push_error(msg)
		return CapGdlrJobs.JobStatus.NONE

	return job.status


func has_job(key: StringName) -> bool:
	return _jobs.has(key)


## Ensures a job completes. Starts WHEN_REQUIRED jobs on the first request.
func ensure_job(key: StringName) -> GdbPromise:
	var job_spec: CapGdlrJobs.JobSpec = _job_registry.get_job(key)
	var job: CapGdlrJobs.Job = _jobs.get(key)

	if job == null:
		job = _create_job(job_spec)

		if job_spec.get_run_policy() == JobRunPolicy.MANUAL:
			return _get_job_started_promise(key).then(func(_res):
				return job.promise
			)

		return _start_job(job_spec)

	return job.promise

## Clears a job so it can run again.
func reset_job(key: StringName, abort_started := false) -> GdbPromise:
	var job: CapGdlrJobs.Job = _jobs.get(key)
	if not job:
		var msg := "No job with key %s has been run yet" % key
		assert(false, msg)
		push_error(msg)
		return GdbPromise.new_rejected(msg)

	var status := job.status
	if not [CapGdlrJobs.JobStatus.WAITING_FOR_START, CapGdlrJobs.JobStatus.COMPLETED, CapGdlrJobs.JobStatus.FAILED].has(status):
		if abort_started:
			job.aborted = true
			job.spec.abort_current_run()
			job.error = "Job %s aborted for reset while status was %s" % [key, status]
			job.status = CapGdlrJobs.JobStatus.FAILED
			_jobs.erase(key)
			return GdbPromise.new_resolved()

		var msg := "Cannot reset job %s. Its status is %s" % [key, job.status]
		assert(false, msg)
		push_error(msg)
		return GdbPromise.new_rejected(msg)

	_jobs.erase(key)

	return GdbPromise.new_resolved()


func _create_job(job_spec: CapGdlrJobs.JobSpec) -> CapGdlrJobs.Job:
	var key := job_spec.get_key()
	if _jobs.has(key):
		return _jobs.get(key)

	var job := CapGdlrJobs.Job.new(job_spec)
	_jobs[key] = job

	return job


func _get_job_started_promise(key: StringName) -> GdbPromise:
	return GdbPromise.new(func(resolve, reject):
		var job: CapGdlrJobs.Job = _jobs.get(key)

		if job == null:
			var msg := "FATAL: Job not found for key: %s, but the job was ready to start. This should never happen" % key
			assert(false, msg)
			reject.call(msg)
			return

		if job.status != CapGdlrJobs.JobStatus.WAITING_FOR_START:
			var msg := "FATAL: Status of job %s is not WAITING_FOR_START, but the job was ready to start. This should never happen" % key
			assert(false, msg)
			reject.call(msg)
			return

		var status: CapGdlrJobs.JobStatus = await job.status_changed
		if status in [CapGdlrJobs.JobStatus.WAITING_FOR_REQUIREMENTS, CapGdlrJobs.JobStatus.RUNNING, CapGdlrJobs.JobStatus.COMPLETED]:
			resolve.call()
			return

		var msg := "FATAL: Status of job %s changed to %s from WAITING_FOR_START, should have been a started state. This should never happen" % [key, status]
		assert(false, msg)
		reject.call(msg)
		return
	)


func _start_job(job_spec: JobSpec, args := {}) -> GdbPromise:
	var key := job_spec.get_key()
	var job: CapGdlrJobs.Job = _jobs.get(key)

	if job == null:
		var msg := "FATAL: Job not found for key: %s, but the job was ready to start. This should never happen" % key
		assert(false, msg)
		push_error(msg)
		return GdbPromise.new_rejected(msg)

	if job.status != CapGdlrJobs.JobStatus.WAITING_FOR_START:
		return job.promise

	job_spec.initialize(self)
	job.ensure_requirements().then(func(_res):
		if job.aborted or _jobs.get(key) != job:
			return GdbPromise.new_rejected("Job %s was aborted before requirements completed" % key)
		return job.run(args)
	)

	return job.promise
