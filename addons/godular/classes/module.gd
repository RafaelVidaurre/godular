class_name GdlrModule
extends RefCounted
## Base class for modules.
##
## A module declares what it imports, what it provides, and what it exports.
## Godular reads four optional static members from the module script:
## [codeblock]
## class_name GameModule
## extends GdlrModule
##
## # Modules this module depends on. Godular registers and enables them first.
## static var IMPORTS = [SettingsModule, AudioModule]
##
## # How to build each token. Keys are capabilities or other tokens.
## static var PROVIDERS = {
##     CapScore: {"use": SvcScore, "inject": [CapSettings]},
## }
##
## # Tokens that modules importing this module can consume.
## static var EXPORTS = [CapScore]
##
## # Tokens resolved at start and available through GdlrModuleManager.request().
## static var TREE_EXPORTS = [CapScore]
## [/codeblock]
## A module script can also be a plain script that holds the static members and
## an inner class that extends [GdlrModule]. See
## [method GdlrModuleDefinition.get_module_class].
## [br][br]
## [b]Provider configuration.[/b] Each entry in [code]PROVIDERS[/code] maps a
## token to a dictionary with these keys:[br]
## - [code]use[/code]: a script, a callable, or a plain value. Godular calls
## [code]new()[/code] on a script and calls a callable. It uses any other value
## as is. A callable can return a [GdbPromise] for asynchronous work.[br]
## - [code]inject[/code]: tokens passed as positional arguments, in order.
## Godular resolves them from this module's providers first, then from the
## exports of imported modules.[br]
## - [code]use_existing[/code]: another token. The provider resolves to the
## value of that token. Use it to alias a capability.[br]
## Each token resolves once per module and Godular caches the value.
## [br][br]
## [b]Injection.[/b] Before [method register] runs, Godular sets every typed
## property whose type extends [GdlrCapability] to the resolved value of that
## capability. For tokens that are not capability classes, declare a static
## [code]INJECT[/code] array:
## [codeblock]
## static var INJECT = [{"token": &"settings", "property": "settings"}]
## var settings: Dictionary
## [/codeblock]
## [b]Lifecycle.[/b] Godular creates each module once with its imports created
## first. It then calls [method register], resolves every tree export, and
## finally calls [method enable] on each module in dependency order. A module
## waits for the [method enable] calls of its imports. Each [method enable]
## call must finish within
## [constant GdlrModuleGraph.DEFAULT_MODULE_ENABLE_TIMEOUT_S] seconds.
##
## @tutorial(Modules): https://rafaelvidaurre.github.io/godular/guide/modules.html
## @tutorial(Dependency injection): https://rafaelvidaurre.github.io/godular/guide/dependency-injection.html


const _ModuleHelpers = preload("res://addons/godular/helpers.gd")


var _module_graph: GdlrModuleGraph


func _init(module_graph: GdlrModuleGraph) -> void:
	_module_graph = module_graph


## Runs once after Godular injects the module dependencies and registers the
## imported modules. Override it to register handlers, jobs, or other data.
## Keep it synchronous. Use [method enable] for asynchronous work.
func register() -> void:
	pass


## Runs after every imported module is enabled. Override it to start the
## module. The method can [code]await[/code]. Modules that import this module
## wait until it returns.
func enable() -> void:
	pass


## Copies the dependencies of this module into [param instance].
## The object declares what it needs in the same way as a module: typed
## properties whose type extends [GdlrCapability], or a static
## [code]INJECT[/code] array. Godular only copies tokens that this module
## also declares. It reports an error for each token it cannot find.
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
			push_error("Cannot resolve init dependency %s for object %s: the module has no matching dependency" % [_ModuleHelpers.get_token_name(token), object_name])


## Registers a debug view on the module graph. See
## [method GdlrModuleGraph.register_debug_plugin].
func register_debug_plugin(plugin_name: String, plugin: GdlrModuleGraph.DebugPlugin) -> void:
	_module_graph.register_debug_plugin(plugin_name, plugin)
