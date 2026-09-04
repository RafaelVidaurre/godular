# Bundled jobs module. Import it with:
#     const JobsModule = preload("res://addons/godular/built_ins/modules/jobs/md_jobs.gd")
#     static var IMPORTS = [JobsModule]
# It provides CapGdlrJobsRegistry and CapGdlrJobs, exports both, and exposes
# CapGdlrJobs as a tree export.
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
