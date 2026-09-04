@abstract class_name GdlrCommandHandler
extends RefCounted
## Base class for command handlers.
##
## A handler runs one command type. Register it as the core of the command
## pipeline:
## [codeblock]
## class_name AddPointsHandler
## extends GdlrCommandHandler
##
## func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant:
##     var command: AddPointsCommand = envelope.command
##     return CapGdlrCommandHandlers.LocalOutput.new([{"points": command.amount}], [])
##
## # In a module:
## handlers.set_core(AddPointsCommand, AddPointsHandler.new().run)
## [/codeblock]
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html


## Runs the command in [param envelope] and returns the handler output.
## The bundled command bus expects a [CapGdlrCommandHandlers.LocalOutput].
## The method can [code]await[/code].
@abstract func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant
