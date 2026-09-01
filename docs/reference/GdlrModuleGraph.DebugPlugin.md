# GdlrModuleGraph.DebugPlugin

Inherits: `Control`

Base class for module-graph debug views.

## Properties

### `plugin_name: String`

Name shown in the debugger. Set by `register_debug_plugin`.

## Methods

### `func _init(name: String = "Debug Plugin") -> void`

### `func refresh() -> void`

Redraws the view. Override `_refresh` to implement it.
