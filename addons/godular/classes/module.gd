class_name GdlrModule
extends RefCounted

## Base class for modules. Declare `IMPORTS`, `EXPORTS`, `PROVIDERS`, and `TREE_EXPORTS` constants on subclasses.


const ModuleHelpers = preload("res://addons/godular/helpers.gd")


var _module_graph: GdlrModuleGraph


func _init(module_graph: GdlrModuleGraph) -> void:
	_module_graph = module_graph


## Runs after all imported modules are enabled.
func enable() -> void:
	pass


## Copies matching module dependencies into a module-scoped object.
## The object can use typed capability properties or a static `INJECT` array.
func inject_dependencies(instance: Object) -> void:
	var instance_init_dependencies := _module_graph.get_init_dependencies(instance.get_script())
	var module_init_dependencies := _module_graph.get_init_dependencies(get_script())
	for instance_property_name in instance_init_dependencies.keys():
		var token: Variant = instance_init_dependencies[instance_property_name]
		var found_module_property_name := ""
		for module_property_name in module_init_dependencies.keys():
			if module_init_dependencies[module_property_name] == token:
				found_module_property_name = module_property_name
				break
		if found_module_property_name:
			instance.set(instance_property_name, self.get(found_module_property_name))
		else:
			var object_name: String = instance.get_script().resource_path if instance.get_script() else instance.get_class()
			push_error("Cannot resolve init dependency %s for object %s: the module has no matching dependency" % [ModuleHelpers.get_token_name(token), object_name])


## Registers a view for an external graph debugger.
func register_debug_plugin(plugin_name: String, plugin: GdlrModuleGraph.DebugPlugin) -> void:
	_module_graph.register_debug_plugin(plugin_name, plugin)
