class_name GdlrModuleProvider
extends RefCounted

const Helpers = preload("res://addons/godular/helpers.gd")

var token: Variant
## A value, script, or callable used to create the provided value.
var use: Variant
## Uses another token when this value is not null.
var use_existing: Variant = null
## Dependencies passed to script constructors or callables in this order.
var requires: Array = []


func _init(token_: Variant, requires_: Array, use_: Variant, use_existing_: Variant = null) -> void:
	token = token_
	use = use_
	use_existing = use_existing_
	requires = requires_


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

	assert(resolved_value != null, "Resolved value is null for provider %s with %d dependencies. Check the logs for previous errors" % [Helpers.get_token_name(token), resolved_dependencies.size()])

	if token is GDScript and _is_subclass_of(token, GdlrCapability) and resolved_value is Object:
		var resolved_script := resolved_value.get_script() as Script
		assert(
			resolved_script != null and _is_subclass_of(resolved_script, token),
			"Provider %s must resolve to an implementation of its capability" % Helpers.get_token_name(token)
		)

	return resolved_value


func _is_subclass_of(script: Script, base_script: Script) -> bool:
	var current: Script = script
	while current:
		if current == base_script:
			return true
		current = current.get_base_script()
	return false
