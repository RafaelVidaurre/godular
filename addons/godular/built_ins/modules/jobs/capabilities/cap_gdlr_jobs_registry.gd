@abstract class_name CapGdlrJobsRegistry extends GdlrCapability

@abstract func register_job(job_spec: CapGdlrJobs.JobSpec) -> void
@abstract func get_job(key: StringName) -> CapGdlrJobs.JobSpec
