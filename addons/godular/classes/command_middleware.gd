@abstract class_name GdlrCommandMiddleware
extends RefCounted
## Base class for command-bus middleware.
##
## Override `_before`, `_around(next, envelope, ctx)`, `_after`, or their
## corresponding `_should_run_*` predicates.
