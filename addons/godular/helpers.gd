extends RefCounted

static func get_module_name(module_or_script: Variant) -> String:
	if module_or_script is GdlrModule:
		return get_module_name(module_or_script.get_script())
	if module_or_script is GDScript:
		return module_or_script.resource_path.get_file().get_basename().to_pascal_case()
	return ""

static func get_token_name(token: Variant) -> String:
	if token is GDScript:
		return token.resource_path.get_file().get_basename().to_pascal_case()
	return str(token)
