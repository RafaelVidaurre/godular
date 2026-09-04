@abstract class_name GdlrCommandMiddleware
extends RefCounted
## Base class for command middleware.
##
## A middleware groups pipeline callbacks for one command type. Implement any
## of these methods. [method GdlrCommandPipeline.use] registers each one it
## finds:
## [codeblock]
## class_name LogMiddleware
## extends GdlrCommandMiddleware
##
## # Runs before the handler.
## func _before(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> void:
##     print("dispatching ", envelope.command)
##
## # Wraps the handler. Call next to continue and return its result.
## func _around(next: Callable, envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant:
##     return await next.call(envelope, ctx)
##
## # Runs after the handler. Returns the result to pass on.
## func _after(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context, result: Variant) -> Variant:
##     return result
##
## # Optional predicates with the same arguments as the callbacks they guard.
## func _should_run_before(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> bool:
##     return true
## [/codeblock]
## Only [code]_around[/code] can [code]await[/code]. The optional predicates are [code]_should_run_before[/code],
## [code]_should_run_around[/code], and [code]_should_run_after[/code].
## Register the middleware with [method CapGdlrCommandHandlers.use].
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html
