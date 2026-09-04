class_name GdlrModuleProvider
extends RefCounted
## Describes how a module creates the value for one token.
##
## [b]Internal.[/b] Godular builds providers from the [code]PROVIDERS[/code]
## declarations of a [GdlrModule]. User code does not create them.
##
## @tutorial(Dependency injection): https://rafaelvidaurre.github.io/godular/guide/dependency-injection.html

const _Helpers = preload("res://addons/godular/helpers.gd")

## The token this provider satisfies.
var token: Variant
## A script, a callable, or a plain value that creates the provided value.
var use: Variant
## Another token. When set, the provider resolves to the value of that token.
var use_existing: Variant = null
## Tokens passed as positional arguments to [member use], in order.
var requires: Array = []


func _init(token_: Variant, requires_: Array, use_: Variant, use_existing_: Variant = null) -> void:
	token = token_
	use = use_
	use_existing = use_existing_
	requires = requires_


## Creates the provided value from the resolved values of [member requires].
## When [member token] extends [GdlrCapability], the method asserts that the
## value extends the capability.
func resolve(resolved_dependencies: Array[Variant]) -> Variant:
	if use_existing != null:
		assert(resolved_dependencies.size() == 1, "use_existing providers should have exactly one dependency")
		return resolved_dependencies[0]

	var resolved_value: Variant
	if use is Callable:
		resolved_value = use.callv(resolved_dependencies)
	elif use is GDScript:
		resolved_value = use.new.callv(resolved_dependencies)
	else:
		resolved_value = use

	assert(resolved_value != null, "Resolved value is null for provider %s with %d dependencies. Check the logs for previous errors" % [_Helpers.get_token_name(token), resolved_dependencies.size()])

	if token is GDScript and _is_subclass_of(token, GdlrCapability) and resolved_value is Object:
		var resolved_script := resolved_value.get_script() as Script
		assert(
			resolved_script != null and _is_subclass_of(resolved_script, token),
			"Provider %s must resolve to an implementation of its capability" % _Helpers.get_token_name(token)
		)

	return resolved_value


func _is_subclass_of(script: Script, base_script: Script) -> bool:
	var current: Script = script
	while current:
		if current == base_script:
			return true
		current = current.get_base_script()
	return false
