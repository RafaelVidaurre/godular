@abstract class_name CapGdlrJobsRegistry extends GdlrCapability

## Capability that stores job specifications by key.

@abstract func register_job(job_spec: CapGdlrJobs.JobSpec) -> void
@abstract func get_job(key: StringName) -> CapGdlrJobs.JobSpec
