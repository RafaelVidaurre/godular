class_name GdlrDiContainer
extends RefCounted
## Resolves singleton providers and caches their values by token.

var _instances_cache: Dictionary[Variant, Variant] = {}
var _provider_factories: Dictionary[Variant, ProviderFactory] = {}


## Registers a provider factory for a token.
func add_provider_factory(token: Variant, provider: ProviderFactory) -> void:
	_provider_factories[token] = provider


## Resolves a token asynchronously and caches the value.
func resolve(token: Variant) -> GdPromise:
	var token_name = _get_token_name(token)

	if _instances_cache.has(token):
		var cached_value = _instances_cache[token]
		return GdPromise.new_resolved(cached_value)

	if not _provider_factories.has(token):
		assert(false, "No provider found for token: %s (token value: %s)" % [token_name, token])
		return GdPromise.new_rejected("No provider found for token: %s" % token_name)

	return _provider_factories[token].resolve().then(func(value: Variant):
		_instances_cache[token] = value
		return value
	)

## Resolves a token synchronously. All providers in the chain must be synchronous.
func resolve_sync(token: Variant) -> Variant:
	var token_name = _get_token_name(token)

	if _instances_cache.has(token):
		return _instances_cache[token]

	if not _provider_factories.has(token):
		assert(false, "No provider found for token: %s (token value: %s)" % [token_name, token])
		return null

	return _provider_factories[token].resolve_sync()

func _get_token_name(token: Variant) -> String:
	if token is GDScript:
		return token.resource_path.get_file().get_basename()
	return str(token)


## Resolves one provider definition together with its dependencies.
class ProviderFactory extends RefCounted:
	var _dependency_providers: Dictionary[Variant, ProviderFactory] = {}
	var _provider_definition: GdlrModuleProvider
	var _owner_container: GdlrDiContainer = null

	func _init(provider_definition: GdlrModuleProvider, dependency_providers: Dictionary[Variant, ProviderFactory] = {}, owner_container: GdlrDiContainer = null) -> void:
		_provider_definition = provider_definition
		_dependency_providers = dependency_providers
		_owner_container = owner_container


	## Resolves the dependencies, then the provider value.
	func resolve() -> GdPromise:
		var dependency_promises: Array[GdPromise] = []
		for required_token in _provider_definition.requires:
			var dep_factory: ProviderFactory = _dependency_providers[required_token]
			if dep_factory._owner_container:
				dependency_promises.append(dep_factory._owner_container.resolve(required_token))
			else:
				dependency_promises.append(dep_factory.resolve())

		return GdPromise.all(dependency_promises).then(func(dependencies: Array[Variant]):
			return _provider_definition.resolve(dependencies)
		)

	## Resolves the dependencies and the provider value synchronously.
	func resolve_sync() -> Variant:
		var dependency_values: Array[Variant] = []
		for required_token in _provider_definition.requires:
			var dep_factory: ProviderFactory = _dependency_providers[required_token]
			if dep_factory._owner_container:
				dependency_values.append(dep_factory._owner_container.resolve_sync(required_token))
			else:
				dependency_values.append(dep_factory.resolve_sync())
		return _provider_definition.resolve(dependency_values)
