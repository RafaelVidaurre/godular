class_name GdlrModuleGraph
extends RefCounted

const ModuleHelpers = preload("res://addons/godular/helpers.gd")
const DEFAULT_MODULE_ENABLE_TIMEOUT_S := 90.0

var _root_module: GdlrModuleDefinition
var _modules_definitions: Dictionary[GDScript, GdlrModuleDefinition] = {}
var _module_instances: Dictionary[GDScript, GdlrModule] = {}
var _unprocessed_root_module: Variant
var _module_containers: Dictionary[GDScript, GdlrDiContainer] = {}
var _tree_exports_providers: Dictionary[Variant, Dictionary] = {}
var _debug_plugins: Dictionary[String, DebugPlugin] = {}


func _init(root_module: Variant) -> void:
	_unprocessed_root_module = root_module


func compile() -> GdPromise:
	return _resolve_module_graph() \
		.then(func(_res):
		var root_module_key: GDScript
		if _unprocessed_root_module is GdlrModuleDefinition:
			root_module_key = _unprocessed_root_module.ModuleScript
		elif _unprocessed_root_module is GDScript:
			root_module_key = _unprocessed_root_module
		else:
			assert(false, "Invalid root module type")

		_root_module = _modules_definitions[root_module_key]

		_build_tree_exports_registry()
		_build_containers()
	).catch(func(error):
		var error_message: String = "Failed to compile module graph: %s" % error
		push_error(error_message)
		assert(false, error_message)
	)


## Mounts providers, resolves tree exports, and enables modules.
func start() -> GdPromise:
	return _mount_all_modules().then(func(_res):
		return _resolve_tree_exports()
	).then(func(_res):
		await _enable_all_modules()
	)


func get_module_definitions() -> Dictionary:
	return _modules_definitions


## Returns an eagerly resolved tree export.
func request(capability: Variant, _consumer_node: Node = null) -> Variant:
	if not capability in _tree_exports_providers:
		var requester := str(_consumer_node.get_path()) if _consumer_node else "unknown requester"
		var message := "Tree export %s not found (%s). Add it to the providing module's TREE_EXPORTS." % [ModuleHelpers.get_token_name(capability), requester]
		push_error(message)
		assert(false, message)
		return null

	var provider_info: Dictionary = _tree_exports_providers[capability]
	var provider_module_script: GDScript = provider_info["module_script"]
	var container: GdlrDiContainer = _module_containers[provider_module_script]

	if not container._instances_cache.has(capability):
		if not Engine.is_editor_hint():
			var message := "Tree export %s was not eagerly resolved" % ModuleHelpers.get_token_name(capability)
			push_error(message)
			assert(false, message)
			return null

		_resolve_sync(capability)

		return null

	return container._instances_cache[capability]


func _resolve_sync(capability: Variant) -> Variant:
	var container: GdlrDiContainer = _module_containers[_root_module.ModuleScript]
	return container.resolve_sync(capability)


## Maps typed capability properties and `INJECT` entries to provider tokens.
func get_init_dependencies(ObjectScript: GDScript) -> Dictionary:
	var init_dependencies := {}

	for property_info in ObjectScript.get_script_property_list():
		var capability_class_name: String = property_info.get(&"class_name", "")
		if not capability_class_name:
			continue

		var token := _find_script_class(capability_class_name)
		if not token:
			continue

		if not _is_script_subclass_of(token, GdlrCapability):
			continue

		init_dependencies[property_info[&"name"]] = token

	if "INJECT" in ObjectScript:
		var inject: Array = ObjectScript.INJECT
		for inject_entry in inject:
			if inject_entry is Dictionary:
				assert(inject_entry.has("token"), "Dictionaries in the INJECT property must have a 'token' key")
				assert(inject_entry.has("property"), "Dictionaries in the INJECT property must have a 'property' key")
				var token: Variant = inject_entry.token
				var property_name: String = inject_entry.property
				init_dependencies[property_name] = token
				continue

			assert(false, "Inject entry type not supported (value is: %s)" % inject_entry)

	return init_dependencies


func _find_script_class(class_name_: String) -> GDScript:
	if ResourceLoader.exists(class_name_):
		return load(class_name_) as GDScript
	for class_info in ProjectSettings.get_global_class_list():
		if class_info["class"] == class_name_:
			return load(class_info["path"]) as GDScript
	return null


func _is_script_subclass_of(script: Script, base_script: Script) -> bool:
	var current := script
	while current:
		if current == base_script:
			return true
		current = current.get_base_script()
	return false


func _resolve_module_graph(module: Variant = _unprocessed_root_module) -> GdPromise:
	return GdPromise.new(func(resolve, reject):
		var normalize_module_definition_promise: GdPromise = _normalize_module_definition(module)
		await normalize_module_definition_promise.await_settled()

		if normalize_module_definition_promise.is_rejected:
			reject.call(normalize_module_definition_promise.value)
			return

		var definition: GdlrModuleDefinition = normalize_module_definition_promise.result
		_store_module_definition(definition)

		var process_imports_promise: GdPromise = _process_module_imports(definition)
		await process_imports_promise.await_settled()

		if process_imports_promise.is_rejected:
			reject.call(process_imports_promise.value)
			return

		var import_promises: Array[GdPromise] = []
		for imported_module in definition.get_imports().values():
			import_promises.append(_resolve_module_graph(imported_module))

		var all_import_promises = GdPromise.all(import_promises)
		await all_import_promises.await_settled()

		if all_import_promises.is_rejected:
			reject.call(all_import_promises.value)
			return

		var resolved_imports: Array = all_import_promises.result
		resolve.call(resolved_imports)
	)


func _store_module_definition(definition: GdlrModuleDefinition) -> void:
	var core_definition: GdlrModuleDefinition = null
	if _modules_definitions.has(definition.ModuleScript):
		core_definition = _modules_definitions[definition.ModuleScript]
	_modules_definitions[definition.ModuleScript] = definition
	if core_definition:
		for export_key in core_definition._exports:
			definition._exports[export_key] = definition._exports[export_key] or core_definition._exports[export_key]
		definition._providers = core_definition._providers.merged(definition._providers, true)
		for tree_export_key in core_definition._tree_exports:
			definition._tree_exports[tree_export_key] = definition._tree_exports[tree_export_key] or core_definition._tree_exports[tree_export_key]


func _process_module_imports(definition: GdlrModuleDefinition) -> GdPromise:
	if definition._unprocessed_imports.is_empty():
		return GdPromise.new_resolved()

	return GdPromise.new(func(resolve, reject):
		var import_promises: Array[GdPromise] = []

		for imported_module in definition._unprocessed_imports:
			import_promises.append(_normalize_module_definition(imported_module))

		var all_imports = GdPromise.all(import_promises)
		await all_imports.await_settled()

		var normalized_imports: Array = all_imports.result

		for index in range(normalized_imports.size()):
			var normalized_import = normalized_imports[index]
			if normalized_import == null:
				reject.call("Import is null for module %s at index %d. This might be caused by an error in a for_root() call" % [ModuleHelpers.get_module_name(definition.ModuleScript), index])
				return

			if normalized_import is GdlrModuleDefinition:
				definition._imports[normalized_import.ModuleScript] = normalized_import

		definition._unprocessed_imports.clear()

		resolve.call()
	)

func _build_tree_exports_registry() -> void:
	for module_script in _modules_definitions.keys():
		var module_definition := _modules_definitions[module_script]

		var tree_exports = module_definition.get_tree_exports()
		for token in tree_exports.keys():
			if token in _tree_exports_providers:
				var existing_module: GDScript = _tree_exports_providers[token]["module_script"]
				push_error("Tree export %s is declared by both %s and %s" % [ModuleHelpers.get_token_name(token), ModuleHelpers.get_module_name(existing_module), ModuleHelpers.get_module_name(module_script)])
				continue

			var provider_info := _find_provider_for_token(module_script, token)

			if provider_info.is_empty():
				push_error("Tree export %s in module %s has no visible provider" % [ModuleHelpers.get_token_name(token), ModuleHelpers.get_module_name(module_script)])
				continue

			_tree_exports_providers[token] = provider_info


func _build_containers() -> void:
	for module_script in _modules_definitions.keys():
		_module_containers[module_script] = GdlrDiContainer.new()

	for module_script in _modules_definitions.keys():
		var module_definition := _modules_definitions[module_script]
		var container := _module_containers[module_script]
		var providers_dict := module_definition.get_providers()

		for token in providers_dict.keys():
			var provider_config: Dictionary = providers_dict[token]
			var inject: Array = provider_config.get("inject", [])
			var use: Variant = provider_config.get("use")
			var use_existing: Variant = provider_config.get("use_existing", null)
			var actual_inject := inject.duplicate()
			if use_existing != null:
				actual_inject = [use_existing]

			var provider := GdlrModuleProvider.new(token, actual_inject, use, use_existing)
			var provider_factory := _create_provider_factory(provider, module_script, container)
			container.add_provider_factory(token, provider_factory)


func _resolve_tree_exports() -> GdPromise:
	return GdPromise.new(func(resolve, reject):
		var resolution_promises: Array[GdPromise] = []
		var tokens_being_resolved: Array = []

		for token in _tree_exports_providers.keys():
			var provider_info: Dictionary = _tree_exports_providers[token]
			var provider_module_script: GDScript = provider_info["module_script"]
			var container: GdlrDiContainer = _module_containers[provider_module_script]

			var promise: GdPromise = container.resolve(token)
			resolution_promises.append(promise)
			tokens_being_resolved.append(token)

		var all_resolved = GdPromise.all(resolution_promises)
		await all_resolved.await_settled()

		if all_resolved.is_rejected:
			for i in range(resolution_promises.size()):
				var promise: GdPromise = resolution_promises[i]
				var token: Variant = tokens_being_resolved[i]
				if promise.is_rejected:
					var provider_info: Dictionary = _tree_exports_providers[token]
					var provider_module_script: GDScript = provider_info["module_script"]
					push_error("Failed to resolve tree export %s from module %s: %s" % [ModuleHelpers.get_token_name(token), ModuleHelpers.get_module_name(provider_module_script), promise.value])

			reject.call(all_resolved.value)
		else:
			resolve.call(all_resolved.result)
	)


func _create_provider_factory(provider: GdlrModuleProvider, provider_module_script: GDScript, owner_container: GdlrDiContainer) -> GdlrDiContainer.ProviderFactory:
	var dependency_factories: Dictionary[Variant, GdlrDiContainer.ProviderFactory] = {}

	for required_token in provider.requires:
		var dep_provider_info := _find_provider_for_token(provider_module_script, required_token)

		if dep_provider_info.is_empty():
			push_error("Cannot find provider %s required by module %s" % [ModuleHelpers.get_token_name(required_token), ModuleHelpers.get_module_name(provider_module_script)])
			assert(false, "Cannot find provider for dependency token %s required by provider in module %s" % [ModuleHelpers.get_token_name(required_token), ModuleHelpers.get_module_name(provider_module_script)])
			continue

		var dep_provider: GdlrModuleProvider = dep_provider_info["provider"]
		var dep_module_script: GDScript = dep_provider_info["module_script"]

		assert(_module_containers.has(dep_module_script), "Container for module %s not found when building factory for %s" % [ModuleHelpers.get_module_name(dep_module_script), ModuleHelpers.get_token_name(provider.token)])
		var dep_container := _module_containers[dep_module_script]

		var dep_factory := _create_provider_factory(dep_provider, dep_module_script, dep_container)
		dependency_factories[required_token] = dep_factory

	return GdlrDiContainer.ProviderFactory.new(provider, dependency_factories, owner_container)


func _find_provider_for_token(module_script: GDScript, token: Variant) -> Dictionary:
	var module_definition := _modules_definitions.get(module_script, null)

	if not module_definition:
		push_error("Module %s is unavailable while resolving %s" % [ModuleHelpers.get_module_name(module_script), ModuleHelpers.get_token_name(token)])
		return {}

	var providers_dict: Dictionary[Variant, Dictionary] = module_definition.get_providers()

	if token in providers_dict:
		var provider_config: Dictionary = providers_dict[token]
		var inject: Array = provider_config.get("inject", [])
		var use: Variant = provider_config.get("use")
		var use_existing: Variant = provider_config.get("use_existing", null)
		var actual_inject := inject.duplicate()
		if use_existing != null:
			actual_inject = [use_existing]

		var provider := GdlrModuleProvider.new(token, actual_inject, use, use_existing)

		return {
			"provider": provider,
			"module_script": module_script
		}

	var imports: Dictionary[GDScript, GdlrModuleDefinition] = module_definition.get_imports()

	for imported_module_script in imports.keys():
		var imported_definition := _modules_definitions.get(imported_module_script, null)

		if not imported_definition:
			push_error("Imported module %s is unavailable while resolving %s" % [ModuleHelpers.get_module_name(imported_module_script), ModuleHelpers.get_token_name(token)])
			continue

		var exported_tokens: Dictionary[Variant, bool] = imported_definition.get_exports()

		if token in exported_tokens:
			return _find_provider_for_token(imported_module_script, token)

	return {}


func _mount_all_modules() -> GdPromise:
	return GdPromise.new(func(resolve, reject):
		var modules_in_order: Array[GDScript] = _get_modules_in_dependency_order()
		var mount_promises: Array[GdPromise] = []

		for module_script in modules_in_order:
			mount_promises.append(_mount_module(module_script))

		var all_mounted = GdPromise.all(mount_promises)
		await all_mounted.await_settled()

		if all_mounted.is_rejected:
			reject.call(all_mounted.value)
		else:
			resolve.call(all_mounted.result)
	)


func _mount_module(ModuleScript: GDScript) -> GdPromise:
	return GdPromise.new(func(resolve, reject):
		if ModuleScript in _module_instances:
			resolve.call(_module_instances[ModuleScript])
			return

		var module_definition := _modules_definitions[ModuleScript]
		var imports: Dictionary[GDScript, GdlrModuleDefinition] = module_definition.get_imports()

		var import_promises: Array[GdPromise] = []
		for imported_module_script in imports.keys():
			import_promises.append(_mount_module(imported_module_script))

		if not import_promises.is_empty():
			var all_imports = GdPromise.all(import_promises)
			await all_imports.await_settled()

			if all_imports.is_rejected:
				reject.call(all_imports.value)
				return

		var ModuleClass := GdlrModuleDefinition.get_module_class(ModuleScript)

		var module: GdlrModule = ModuleClass.new(self)

		var init_dependencies := get_init_dependencies(ModuleClass)
		var container := _module_containers[ModuleScript]

		var dependency_promises: Array[GdPromise] = []
		var property_names: Array[String] = []

		for property_name in init_dependencies.keys():
			var token: Variant = init_dependencies[property_name]
			property_names.append(property_name)
			var resolution_promise: GdPromise

			if container._provider_factories.has(token):
				resolution_promise = container.resolve(token)
			else:
				var provider_info := _find_provider_for_token(ModuleScript, token)
				if provider_info.is_empty():
					var err_msg := "Cannot resolve init dependency '%s' for module '%s' - no provider found" % [ModuleHelpers.get_token_name(token), ModuleHelpers.get_module_name(ModuleScript)]
					push_error(err_msg)
					assert(false, err_msg)
					reject.call(err_msg)
					return

				var provider_module_script: GDScript = provider_info.module_script
				var provider_container := _module_containers[provider_module_script]
				resolution_promise = provider_container.resolve(token)

			dependency_promises.append(resolution_promise)

		if not dependency_promises.is_empty():
			var all_dependencies = GdPromise.all(dependency_promises)
			await all_dependencies.await_settled()

			if all_dependencies.is_rejected:
				push_error("Failed to resolve dependencies for module %s: %s" % [ModuleHelpers.get_module_name(ModuleScript), all_dependencies.value])
				reject.call(all_dependencies.value)
				return

			var resolved_values: Array = all_dependencies.result
			for i in range(property_names.size()):
				var property_name := property_names[i]
				var resolved_value: Variant = resolved_values[i]
				module[property_name] = resolved_value

		_module_instances[ModuleScript] = module

		if module.has_method("register"):
			module.register()

		resolve.call(module)
	)

func _get_modules_in_dependency_order() -> Array[GDScript]:
	var visited: Dictionary[GDScript, bool] = {}
	var result: Array[GDScript] = []

	if _root_module:
		_visit_module_for_topological_sort(_root_module.ModuleScript, visited, result)

	for module_script in _modules_definitions.keys():
		if not visited.get(module_script, false):
			_visit_module_for_topological_sort(module_script, visited, result)

	return result


func _visit_module_for_topological_sort(module_script: GDScript, visited: Dictionary[GDScript, bool], result: Array[GDScript]) -> void:
	if visited.get(module_script, false):
		return

	visited[module_script] = true

	var module_definition := _modules_definitions.get(module_script, null)
	if module_definition:
		var imports: Dictionary[GDScript, GdlrModuleDefinition] = module_definition.get_imports()
		for imported_module_script in imports.keys():
			if imported_module_script in _modules_definitions:
				_visit_module_for_topological_sort(imported_module_script, visited, result)

	if module_script in _modules_definitions:
		result.append(module_script)


func _enable_all_modules() -> void:
	var modules_in_order: Array[GDScript] = _get_modules_in_dependency_order()

	for module_script in modules_in_order:
		var module: GdlrModule = _module_instances[module_script]
		var promise := GdPromise.race([
			GdPromise.to_promise(module.enable),
			GdPromise.timeout(DEFAULT_MODULE_ENABLE_TIMEOUT_S, "Module enable timeout"),
		])
		await promise.await_settled()
		if promise.is_rejected:
			push_error("Module %s 'enable' timed out" % ModuleHelpers.get_module_name(module_script))
			assert(false, "Module %s 'enable' timed out" % ModuleHelpers.get_module_name(module_script))


func _normalize_module_definition(module: Variant) -> GdPromise:
	if module is GdPromise:
		return module.then(func(resolved_module: Variant):
			return _normalize_module_definition(resolved_module)
		)

	if module is GdlrModuleDefinition:
		var imports = module.ModuleScript.IMPORTS if "IMPORTS" in module.ModuleScript else []
		var exports = module.ModuleScript.EXPORTS if "EXPORTS" in module.ModuleScript else []
		var static_providers = module.ModuleScript.PROVIDERS if "PROVIDERS" in module.ModuleScript else {}
		var tree_exports = module.ModuleScript.TREE_EXPORTS if "TREE_EXPORTS" in module.ModuleScript else []

		var existing_providers = module.get_providers()
		var merged_providers = static_providers.duplicate()
		for provider_token in existing_providers:
			merged_providers[provider_token] = existing_providers[provider_token]

		for index in range(imports.size()):
			var import_token = imports[index]
			if import_token == null:
				return GdPromise.new_rejected("Import is null for module %s at index %d. This might be caused by an error in a for_root() call" % [ModuleHelpers.get_module_name(module.ModuleScript), index])

		module.imports(imports)
		module.exports(exports)
		module.providers(merged_providers)
		module.tree_exports(tree_exports)

		return GdPromise.new_resolved(module)

	assert(module is GDScript, "Module must be a GDScript or a GdlrModuleDefinition")

	var ModuleScript = module
	var module_definition := GdlrModuleDefinition.new()
	module_definition.ModuleScript = ModuleScript

	return _normalize_module_definition(module_definition)

## Base class for module-graph debug views.
class DebugPlugin extends Control:
	var plugin_name: String = ""

	func _init(name: String = "Debug Plugin") -> void:
		plugin_name = name

	func _refresh() -> void:
		pass

	func refresh() -> void:
		_refresh()


func register_debug_plugin(plugin_name: String, plugin: DebugPlugin) -> void:
	if _debug_plugins.has(plugin_name):
		push_warning("Debug plugin '%s' is already registered and will be replaced." % plugin_name)

	plugin.plugin_name = plugin_name
	_debug_plugins[plugin_name] = plugin


func get_debug_plugins() -> Dictionary[String, DebugPlugin]:
	return _debug_plugins
