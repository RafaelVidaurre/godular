@tool
extends Node
## Autoload that mounts, starts, and queries the module graph.
##
## Enabling the Godular plugin registers this script as the
## [code skip-lint]GdlrModuleManager[/code] autoload. Mount the root module once, start
## it, and then request tree exports from anywhere in the scene tree:
## [codeblock]
## func _ready() -> void:
##     await GdlrModuleManager.mount(GameModule)
##     await GdlrModuleManager.start()
##     var score: CapScore = GdlrModuleManager.request(CapScore)
## [/codeblock]
## [b]Editor.[/b] When the project setting
## [code]godular/editor_root_module_path[/code] points at a module script,
## the manager mounts and starts that module inside the editor. Editor
## tooling can wait for it with [method editor_await_graph_started].
##
## @tutorial(Getting started): https://rafaelvidaurre.github.io/godular/guide/getting-started.html
## @tutorial(Editor): https://rafaelvidaurre.github.io/godular/guide/editor.html

## Emitted after [method mount] compiles the graph.
signal graph_mounted(graph: GdlrModuleGraph)
## Emitted after [method start] enables every module.
signal graph_started(graph: GdlrModuleGraph)

const _Settings := preload("res://addons/godular/settings.gd")

var _graph: GdlrModuleGraph = null
var _graph_started := false

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	await _mount_editor_module_graph()
	await _start_editor_module_graph()

## Creates a graph from [param root_module] and compiles it.
## [param root_module] is a module script or a [GdlrModuleDefinition].
## A later call replaces the current graph.
func mount(root_module: Variant) -> void:
	if root_module is GDScript:
		_graph = GdlrModuleGraph.new(root_module)
	elif root_module is GdlrModuleDefinition:
		_graph = GdlrModuleGraph.new(root_module)
	else:
		assert(false, "mount() expects either a GDScript or GdlrModuleDefinition instance")
		return
	_graph_started = false

	await _graph.compile().await_then()
	graph_mounted.emit(_graph)


## Starts the mounted graph. See [method GdlrModuleGraph.start].
func start() -> void:
	await _graph.start().catch(func(error):
		assert(false, "Failed to start module graph: %s" % error)
	).await_then()
	_graph_started = true
	graph_started.emit(_graph)


## Returns the mounted graph, or [code]null[/code] before [method mount].
func get_graph() -> GdlrModuleGraph:
	return _graph


## Returns true when the editor graph is mounted. Editor only.
func editor_is_graph_ready() -> bool:
	assert(Engine.is_editor_hint(), "editor_is_graph_ready() can only be called in editor")
	return _graph != null


## Waits until the editor graph is mounted. Editor only.
func editor_await_graph_ready() -> void:
	assert(Engine.is_editor_hint(), "editor_await_graph_ready() can only be called in editor")

	while not _graph:
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame


## Waits until the editor graph is started. Editor only.
func editor_await_graph_started() -> void:
	assert(Engine.is_editor_hint(), "editor_await_graph_started() can only be called in editor")

	await editor_await_graph_ready()

	while not _graph_started:
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame

## Returns the value of a tree export. See [method GdlrModuleGraph.request].
## Fails before [method mount].
func request(capability: Variant, consumer_node: Node = null) -> Variant:
	assert(_graph != null, "App not mounted. Call mount() first.")
	return _graph.request(capability, consumer_node)


func _mount_editor_module_graph() -> void:
	var editor_root_module_path: String = _Settings.editor_root_module_path
	if not editor_root_module_path:
		return

	var EditorModule: GDScript = load(editor_root_module_path)
	await mount(EditorModule)


func _start_editor_module_graph() -> void:
	if not _graph:
		return

	await start()
