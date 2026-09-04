@abstract class_name CapGdlrCommandRouter
extends GdlrCapability
## Capability that plans the route of a command.
##
## Godular does not ship a service for this capability, and the bundled
## [CapGdlrCommandBus] service does not call it. Provide a router when your
## application decides routes in one place, and set the result on
## [member CapGdlrCommandBus.CommandMeta.route] before you dispatch.
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html

## Returns the route for [param envelope].
@abstract func plan(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandRoute
