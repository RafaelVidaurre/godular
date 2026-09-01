@tool
extends Node

signal graph_mounted(graph: GdlrModuleGraph)
signal graph_started(graph: GdlrModuleGraph)

const Settings := preload("res://addons/godular/settings.gd")

var _graph: GdlrModuleGraph = null
var _graph_started := false

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	await _mount_editor_module_graph()
	await _start_editor_module_graph()

## Compiles a module script or dynamic module definition.
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


func start() -> void:
	await _graph.start().catch(func(error):
		assert(false, "Failed to start module graph: %s" % error)
	).await_then()
	_graph_started = true
	graph_started.emit(_graph)


func get_graph() -> GdlrModuleGraph:
	return _graph


func editor_is_graph_ready() -> bool:
	assert(Engine.is_editor_hint(), "editor_is_graph_ready() can only be called in editor")
	return _graph != null


func editor_await_graph_ready() -> void:
	assert(Engine.is_editor_hint(), "editor_await_graph_ready() can only be called in editor")

	while not _graph:
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame


func editor_await_graph_started() -> void:
	assert(Engine.is_editor_hint(), "editor_await_graph_started() can only be called in editor")

	await editor_await_graph_ready()

	while not _graph_started:
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame

## Returns an eagerly resolved `TREE_EXPORTS` dependency.
func request(capability: Variant, consumer_node: Node = null) -> Variant:
	assert(_graph != null, "App not mounted. Call mount() first.")
	return _graph.request(capability, consumer_node)


func _mount_editor_module_graph() -> void:
	var editor_root_module_path: String = Settings.editor_root_module_path
	if not editor_root_module_path:
		return

	var EditorModule: GDScript = load(editor_root_module_path)
	await mount(EditorModule)


func _start_editor_module_graph() -> void:
	if not _graph:
		return

	await _graph.start().await_then()
