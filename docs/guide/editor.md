# Editor

Godular can run a module graph inside the Godot editor. Use this to build editor tooling with the same modules as the game.

## Editor root module

Set the project setting `godular/editor_root_module_path` to the path of a module script, for example `res://tools/editor_module.gd`. The plugin registers the setting with a file hint for `.gd` files.

When the setting is not empty, the `GdlrModuleManager` autoload loads that script on `_enter_tree()`, mounts it, and starts it. This happens only when the engine runs as the editor. In a running game the setting has no effect.

## Waiting for the editor graph

Editor tooling can start before the graph is ready. {ref}`GdlrModuleManager <class_GdlrModuleManager>` has three methods for this case:

| Method | Behaviour |
| --- | --- |
| `editor_is_graph_ready()` | Returns true when the editor graph is mounted. |
| `editor_await_graph_ready()` | Waits until the editor graph is mounted. |
| `editor_await_graph_started()` | Waits until the editor graph is started. |

All three are editor only. They assert when called in a running game.

```gdscript
@tool
extends EditorPlugin

func _enter_tree() -> void:
	await GdlrModuleManager.editor_await_graph_started()
	var tool_service: CapTool = GdlrModuleManager.request(CapTool)
```

`get_graph()` returns the mounted {ref}`GdlrModuleGraph <class_GdlrModuleGraph>`, or `null` before `mount()`. The `graph_mounted` and `graph_started` signals also pass the graph.

## Debug plugins

Godular does not ship a debugger UI. It provides a registration point for one.

A debug plugin extends `GdlrModuleGraph.DebugPlugin`, a `Control` with a `plugin_name`. Override `_refresh()` to redraw the view. `refresh()` calls it.

```gdscript
class_name ScoreDebugPlugin
extends GdlrModuleGraph.DebugPlugin

var score: CapScore

func _refresh() -> void:
	# Update child controls from score.
	pass
```

A module registers a plugin with `register_debug_plugin(name, plugin)`. Godular sets `plugin_name` to the name. A second registration with the same name replaces the first and reports a warning.

```gdscript
func register() -> void:
	var plugin := ScoreDebugPlugin.new("Score")
	plugin.score = score
	register_debug_plugin("Score", plugin)
```

An external tool reads the registered plugins with `graph.get_debug_plugins()`. The result is a dictionary from name to plugin.
