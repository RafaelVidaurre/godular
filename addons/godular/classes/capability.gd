@abstract class_name GdlrCapability
extends RefCounted
## Base class for capability contracts.
##
## A capability is an abstract class that names a set of methods. A module
## provides a capability with a service that extends it, and other modules
## consume the capability without knowing the service.
## [codeblock]
## @abstract class_name CapScore
## extends GdlrCapability
##
## @abstract func add_points(amount: int) -> void
## [/codeblock]
## Capabilities are the usual tokens in the [code]PROVIDERS[/code],
## [code]EXPORTS[/code], and [code]TREE_EXPORTS[/code] declarations of a
## [GdlrModule]. When a provider token is a capability, Godular asserts that
## the provided value extends it. Godular injects a typed property whose type
## is a capability automatically.
##
## @tutorial(Modules): https://rafaelvidaurre.github.io/godular/guide/modules.html
