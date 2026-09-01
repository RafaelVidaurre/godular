# GdlrModule

Inherits: `RefCounted`

Base class for modules. Declare `IMPORTS`, `EXPORTS`, `PROVIDERS`, and `TREE_EXPORTS` constants on subclasses.

## Methods

### `func _init(module_graph: GdlrModuleGraph) -> void`

### `func enable() -> void`

Runs after all imported modules are enabled.

### `func inject_dependencies(instance: Object) -> void`

Copies matching module dependencies into a module-scoped object. The object can use typed capability properties or a static `INJECT` array.

### `func register_debug_plugin(plugin_name: String, plugin: GdlrModuleGraph.DebugPlugin) -> void`

Registers a view for an external graph debugger.
