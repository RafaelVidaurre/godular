@abstract class_name CapGdlrJobsRegistry
extends GdlrCapability
## Capability that stores job specifications by key.
##
## Register specifications in [method GdlrModule.register]. The bundled
## jobs module provides this capability. See [CapGdlrJobs].
##
## @tutorial(Jobs): https://rafaelvidaurre.github.io/godular/guide/jobs.html

## Stores [param job_spec] under its [code]KEY[/code] constant. A later
## call with the same key replaces the specification.
@abstract func register_job(job_spec: CapGdlrJobs.JobSpec) -> void
## Returns the specification stored under [param key], or [code]null[/code].
@abstract func get_job(key: StringName) -> CapGdlrJobs.JobSpec
