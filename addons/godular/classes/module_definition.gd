@tool
class_name GdlrModuleDefinition
extends RefCounted
## Configures a module at runtime.
##
## A module definition wraps a module script and adds imports, providers,
## exports, and tree exports with chained calls. Use it when a module needs
## configuration that static declarations cannot express, for example a
## value known only at startup:
## [codeblock]
## class_name ConfigModule
## extends GdlrModule
##
## static var PROVIDERS = {&"api_url": {"use": "http://localhost"}}
## static var TREE_EXPORTS = [&"api_url"]
##
## static func for_root(api_url: String) -> GdlrModuleDefinition:
##     var definition := GdlrModuleDefinition.new()
##     definition.ModuleScript = ConfigModule
##     return definition.providers({&"api_url": {"use": api_url}})
## [/codeblock]
## Pass the definition to [method GdlrModuleManager.mount] or list it in the
## [code]IMPORTS[/code] of another module. Godular merges the static
## declarations of the script with the definition. Providers in the definition
## replace static providers with the same token.
##
## @tutorial(Modules): https://rafaelvidaurre.github.io/godular/guide/modules.html

## The script that contains the module class.
var ModuleScript: GDScript

var _imports: Dictionary[GDScript, GdlrModuleDefinition] = {}
var _exports: Dictionary[Variant, bool] = {}
var _tree_exports: Dictionary[Variant, bool] = {}
var _providers: Dictionary[Variant, Dictionary] = {}
var _unprocessed_imports: Array[Variant] = []


## Returns the imported module definitions keyed by module script.
## The dictionary is complete after [method GdlrModuleGraph.compile].
func get_imports() -> Dictionary[GDScript, GdlrModuleDefinition]:
	return _imports


## Returns the exported tokens as dictionary keys.
func get_exports() -> Dictionary[Variant, bool]:
	return _exports


## Returns the provider configurations keyed by token.
## See [GdlrModule] for the configuration keys.
func get_providers() -> Dictionary[Variant, Dictionary]:
	return _providers


## Returns the tree export tokens as dictionary keys.
func get_tree_exports() -> Dictionary[Variant, bool]:
	return _tree_exports


## Adds imported modules and returns this definition.
## Each entry is a module script, a [GdlrModuleDefinition], or a [GdbPromise]
## that resolves to one of them.
func imports(imports_: Array[Variant] = []) -> GdlrModuleDefinition:
	_unprocessed_imports.append_array(imports_)

	return self


## Adds provider configurations keyed by token and returns this definition.
## See [GdlrModule] for the configuration keys.
func providers(providers_: Dictionary = {}) -> GdlrModuleDefinition:
	for provider_token in providers_:
		_providers[provider_token] = providers_[provider_token]
	return self

## Adds tokens that [method GdlrModuleManager.request] can return, and
## returns this definition.
func tree_exports(tree_exports_: Array[Variant] = []) -> GdlrModuleDefinition:
	for tree_export_token in tree_exports_:
		_tree_exports[tree_export_token] = true
	return self


## Adds tokens that importing modules can consume, and returns this
## definition.
func exports(exports_: Array[Variant] = []) -> GdlrModuleDefinition:
	for exported_token in exports_:
		_exports[exported_token] = true
	return self


## Returns the class that Godular instantiates for a module script.
## When [param ModuleScript_] extends [GdlrModule], the method returns it.
## Otherwise the method returns the first inner class of the script that
## extends [GdlrModule], and fails when there is none.
static func get_module_class(ModuleScript_: GDScript) -> GDScript:
	if _is_script_subclass_of(ModuleScript_, GdlrModule):
		return ModuleScript_

	var constant_map := ModuleScript_.get_script_constant_map()

	for const_name in constant_map:
		var const_value = constant_map[const_name]
		if const_value is GDScript and _is_script_subclass_of(const_value, GdlrModule):
			return const_value

	assert(false, "No class extending GdlrModule found in script %s" % ModuleScript_.resource_path.get_file())

	return null


static func _is_script_subclass_of(script: Script, base_script: Script) -> bool:
	var current := script
	while current:
		if current == base_script:
			return true
		current = current.get_base_script()
	return false
