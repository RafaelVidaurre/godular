@abstract class_name CapGdlrCommandHandlers
extends GdlrCapability


@abstract func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: Context) -> Variant
@abstract func set_core(command: GDScript, core: Callable) -> void
@abstract func use_before(command: GDScript, before: Callable) -> void
@abstract func use_around(command: GDScript, around: Callable) -> void
@abstract func use_after(command: GDScript, after: Callable) -> void
@abstract func use(command: GDScript, middleware: GdlrCommandMiddleware, priority := 0) -> void
@abstract func remove_by_callback(command: GDScript, callback: Callable) -> void
@abstract func use_global_around(around: Callable, priority := 0, should_run := Callable()) -> void
@abstract func remove_global_by_callback(callback: Callable) -> void

class Context extends RefCounted:
	var get_state: Callable
	var dispatch: Callable


## Local handler output carried through command middleware and serialization.
class LocalOutput extends RefCounted:
	var state_dispatches: Array[Dictionary]
	var effects: Array[Dictionary]

	func _init(state_dispatches_: Array[Dictionary] = [], effects_: Array[Dictionary] = []) -> void:
		state_dispatches = state_dispatches_
		effects = effects_

	func to_dict() -> Dictionary:
		return {"state_dispatches": state_dispatches, "effects": effects}


	static func from_dict(serialized: Dictionary) -> LocalOutput:
		return LocalOutput.new(
			serialized.get("state_dispatches", []),
			serialized.get("effects", []),
		)
