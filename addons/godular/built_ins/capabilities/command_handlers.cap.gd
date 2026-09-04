@abstract class_name CapGdlrCommandHandlers
extends GdlrCapability
## Capability that registers and runs local command handlers.
##
## Each command class gets one pipeline. Register the handler as the core of
## that pipeline and add middleware around it:
## [codeblock]
## var handlers: CapGdlrCommandHandlers
##
## func register() -> void:
##     handlers.set_core(AddPointsCommand, AddPointsHandler.new().run)
##     handlers.use(AddPointsCommand, LogMiddleware.new())
## [/codeblock]
## Godular ships a service for this capability at
## [code]res://addons/godular/built_ins/services/command_handlers.svc.gd[/code].
## See [GdlrCommandPipeline] for the callback signatures and the run order.
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html


## Runs the command in [param envelope] through the pipeline of its class
## and returns the result of the pipeline.
@abstract func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: Context) -> Variant
## Sets the handler callable for [param command]. See [GdlrCommandHandler].
@abstract func set_core(command: GDScript, core: Callable) -> void
## Adds a callback that runs before the handler of [param command].
@abstract func use_before(command: GDScript, before: Callable) -> void
## Adds a callback that wraps the handler of [param command].
@abstract func use_around(command: GDScript, around: Callable) -> void
## Adds a callback that runs after the handler of [param command].
@abstract func use_after(command: GDScript, after: Callable) -> void
## Registers every callback that [param middleware] implements for
## [param command]. See [GdlrCommandMiddleware].
@abstract func use(command: GDScript, middleware: GdlrCommandMiddleware, priority := 0) -> void
## Removes every callback of [param command] that uses [param callback].
@abstract func remove_by_callback(command: GDScript, callback: Callable) -> void
## Adds an around callback to the pipelines of every command, including
## commands registered later.
@abstract func use_global_around(around: Callable, priority := 0, should_run := Callable()) -> void
## Removes a callback added with [method use_global_around] from every
## pipeline.
@abstract func remove_global_by_callback(callback: Callable) -> void

## Services that a handler can call while it runs.
class Context extends RefCounted:
	## Returns application state. The bundled bus sets a callable that
	## returns [code]null[/code]. Replace it in a middleware or a custom bus.
	var get_state: Callable
	## Dispatches another envelope through the bus. Takes a
	## [CapGdlrCommandBus.CommandEnvelope] and returns a
	## [CapGdlrCommandBus.CommandResult].
	var dispatch: Callable


## Output of a local handler.
##
## The bundled bus serializes it with [method to_dict] into
## [member CapGdlrCommandBus.CommandResult.payload].
class LocalOutput extends RefCounted:
	## State changes that the handler requests. Godular does not interpret
	## them.
	var state_dispatches: Array[Dictionary]
	## Side effects that the handler requests. Godular does not interpret
	## them.
	var effects: Array[Dictionary]

	## Creates an output.
	func _init(state_dispatches_: Array[Dictionary] = [], effects_: Array[Dictionary] = []) -> void:
		state_dispatches = state_dispatches_
		effects = effects_

	## Serializes the output. See [method from_dict].
	func to_dict() -> Dictionary:
		return {"state_dispatches": state_dispatches, "effects": effects}


	## Restores an output from the output of [method to_dict].
	static func from_dict(serialized: Dictionary) -> LocalOutput:
		return LocalOutput.new(
			serialized.get("state_dispatches", []),
			serialized.get("effects", []),
		)
