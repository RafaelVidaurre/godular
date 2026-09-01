# GdlrModuleManager

Inherits: `Node`

Autoload singleton that mounts, starts, and queries the module graph.

## Signals

### `graph_mounted(graph: GdlrModuleGraph)`

Emitted after `mount()` compiles the graph.

### `graph_started(graph: GdlrModuleGraph)`

Emitted after `start()` enables all modules.

## Methods

### `func mount(root_module: Variant) -> void`

Compiles a module script or dynamic module definition.

### `func start() -> void`

Starts the mounted module graph.

### `func get_graph() -> GdlrModuleGraph`

Returns the mounted module graph, or null before `mount()`.

### `func editor_is_graph_ready() -> bool`

Returns true when the editor module graph is mounted. Editor only.

### `func editor_await_graph_ready() -> void`

Waits until the editor module graph is mounted. Editor only.

### `func editor_await_graph_started() -> void`

Waits until the editor module graph is started. Editor only.

### `func request(capability: Variant, consumer_node: Node = null) -> Variant`

Returns an eagerly resolved `TREE_EXPORTS` dependency.
