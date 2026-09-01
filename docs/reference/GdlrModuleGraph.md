# GdlrModuleGraph

Inherits: `RefCounted`

Compiles a tree of module definitions and runs its lifecycle.

## Constants

- `DEFAULT_MODULE_ENABLE_TIMEOUT_S` = `90.0` — Seconds a module `enable()` call can take before it fails.

## Methods

### `func _init(root_module: Variant) -> void`

### `func compile() -> GdPromise`

Resolves module definitions and builds the dependency containers.

### `func start() -> GdPromise`

Mounts providers, resolves tree exports, and enables modules.

### `func get_module_definitions() -> Dictionary`

Returns the compiled module definitions keyed by module script.

### `func request(capability: Variant, _consumer_node: Node = null) -> Variant`

Returns an eagerly resolved tree export.

### `func get_init_dependencies(ObjectScript: GDScript) -> Dictionary`

Maps typed capability properties and `INJECT` entries to provider tokens.

### `func register_debug_plugin(plugin_name: String, plugin: GdlrModuleGraph.DebugPlugin) -> void`

Registers a debug view under a unique name.

### `func get_debug_plugins() -> Dictionary[String, GdlrModuleGraph.DebugPlugin]`

Returns the registered debug views keyed by name.
