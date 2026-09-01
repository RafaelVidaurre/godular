extends CapGdlrJobsRegistry

var _jobs: Dictionary[StringName, CapGdlrJobs.JobSpec] = {}


func register_job(job_spec: CapGdlrJobs.JobSpec) -> void:
	_jobs[_get_job_key(job_spec)] = job_spec


func get_job(key: StringName) -> CapGdlrJobs.JobSpec:
	return _jobs.get(key)


func _get_job_key(job_spec: CapGdlrJobs.JobSpec) -> StringName:
	var JobSpecScript: GDScript = job_spec.get_script()
	assert("KEY" in JobSpecScript, "Job spec must have a KEY constant")
	return JobSpecScript.KEY
