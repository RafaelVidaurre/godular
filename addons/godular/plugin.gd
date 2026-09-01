@tool
extends EditorPlugin

const MODULE_MANAGER_SINGLETON_NAME = "GdlrModuleManager"

func _enable_plugin() -> void:
	add_autoload_singleton(MODULE_MANAGER_SINGLETON_NAME, "res://addons/godular/singletons/module_manager/module_manager.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton(MODULE_MANAGER_SINGLETON_NAME)
