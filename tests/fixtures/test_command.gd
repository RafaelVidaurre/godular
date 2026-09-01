class_name GdlrTestCommand
extends CapGdlrCommandBus.Command

var message := ""


func _to_dict() -> Dictionary:
	return {"message": message}


static func from_dict(serialized: Dictionary) -> GdlrTestCommand:
	var command := GdlrTestCommand.new()
	command.message = serialized.get("message", "")
	return command
