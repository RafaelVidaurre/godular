const SvcJobs = preload("./services/svc_jobs.gd")
const RegJobs = preload("./registries/reg_jobs.gd")


static var PROVIDERS = {
	CapGdlrJobsRegistry: {
		"use": RegJobs,
	},
	CapGdlrJobs: {
		"inject": [CapGdlrJobsRegistry],
		"use": SvcJobs,
	},
}

static var IMPORTS = []


static var EXPORTS = [
	CapGdlrJobsRegistry,
	CapGdlrJobs,
]


static var TREE_EXPORTS = [
	CapGdlrJobs,
]

class JobsModule extends GdlrModule:
	pass
