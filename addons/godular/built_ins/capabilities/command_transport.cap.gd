@abstract class_name CapGdlrCommandTransport
extends GdlrCapability
## Capability that sends commands to remote targets.
##
## A transport keeps one [GdlrCommandTransportAdapter] per target name and
## sends each envelope through the adapter named by
## [member CapGdlrCommandBus.CommandRoute.target]. Godular does not ship a
## service for this capability. Implement it in your project.
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html

## Sends [param envelope] to its target and returns the result.
@abstract func send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult
## Registers [param adapter] under [param target].
@abstract func register_adapter(target: StringName, adapter: GdlrCommandTransportAdapter) -> void
## Returns the adapter registered under [param target].
@abstract func get_adapter(target: StringName) -> GdlrCommandTransportAdapter
