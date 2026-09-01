@tool
extends EditorPlugin


func _enter_tree() -> void:
	_verify.call_deferred()


func _verify() -> void:
	await get_tree().process_frame
	var filesystem := get_editor_interface().get_resource_filesystem()
	while filesystem.is_scanning():
		await filesystem.filesystem_changed
	await get_tree().process_frame
	get_editor_interface().set_plugin_enabled("godular", true)
	for _frame in range(10):
		await get_tree().process_frame
	var enabled := get_editor_interface().is_plugin_enabled("godular")
	var autoload_path: String = ProjectSettings.get_setting("autoload/GdlrModuleManager", "")
	var resource_path := autoload_path.trim_prefix("*")
	if resource_path.begins_with("uid://"):
		resource_path = ResourceUID.get_id_path(ResourceUID.text_to_id(resource_path))
	if not enabled or resource_path != "res://addons/godular/singletons/module_manager/module_manager.gd":
		printerr("GODULAR_PLUGIN_TEST_FAILURE: autoload was not registered")
		get_tree().quit(1)
		return
	get_editor_interface().set_plugin_enabled("godular", false)
	for _frame in range(3):
		await get_tree().process_frame
	if ProjectSettings.has_setting("autoload/GdlrModuleManager"):
		printerr("GODULAR_PLUGIN_TEST_FAILURE: autoload was not removed")
		get_tree().quit(1)
		return
	get_editor_interface().set_plugin_enabled("godular", true)
	for _frame in range(3):
		await get_tree().process_frame
	ProjectSettings.save()
	print("GODULAR_PLUGIN_TEST: enable and disable lifecycle passed")
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)
