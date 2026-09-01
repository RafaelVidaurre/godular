@tool
class_name GdlrModuleDefinition
extends RefCounted

var ModuleScript: GDScript

var _imports: Dictionary[GDScript, GdlrModuleDefinition] = {}
var _exports: Dictionary[Variant, bool] = {}
var _tree_exports: Dictionary[Variant, bool] = {}
var _providers: Dictionary[Variant, Dictionary] = {}
var _unprocessed_imports: Array[Variant] = []


func get_imports() -> Dictionary[GDScript, GdlrModuleDefinition]:
	return _imports


func get_exports() -> Dictionary[Variant, bool]:
	return _exports


func get_providers() -> Dictionary[Variant, Dictionary]:
	return _providers


func get_tree_exports() -> Dictionary[Variant, bool]:
	return _tree_exports


func imports(imports_: Array[Variant] = []) -> GdlrModuleDefinition:
	_unprocessed_imports.append_array(imports_)

	return self


func providers(providers_: Dictionary = {}) -> GdlrModuleDefinition:
	for provider_token in providers_:
		_providers[provider_token] = providers_[provider_token]
	return self

func tree_exports(tree_exports_: Array[Variant] = []) -> GdlrModuleDefinition:
	for tree_export_token in tree_exports_:
		_tree_exports[tree_export_token] = true
	return self


func exports(exports_: Array[Variant] = []) -> GdlrModuleDefinition:
	for exported_token in exports_:
		_exports[exported_token] = true
	return self


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
