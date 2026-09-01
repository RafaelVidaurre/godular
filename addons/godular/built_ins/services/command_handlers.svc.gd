extends CapGdlrCommandHandlers

var _pipelines: Dictionary[GDScript, GdlrCommandPipeline] = {}
var _global_around: Array[Dictionary] = []


func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: Context) -> Variant:
	return await pipeline_for(envelope.command.get_script()).run(envelope, ctx)


func set_core(CommandClass: GDScript, core: Callable) -> void:
	pipeline_for(CommandClass).set_core(core)


func use_before(CommandClass: GDScript, before: Callable) -> void:
	pipeline_for(CommandClass).use_before(before)


func use_around(CommandClass: GDScript, around: Callable) -> void:
	pipeline_for(CommandClass).use_around(around)


func use_after(CommandClass: GDScript, after: Callable) -> void:
	pipeline_for(CommandClass).use_after(after)


func use(CommandClass: GDScript, middleware: GdlrCommandMiddleware, priority := 0) -> void:
	pipeline_for(CommandClass).use(middleware, priority)


func remove_by_callback(CommandClass: GDScript, callback: Callable) -> void:
	pipeline_for(CommandClass).remove_by_callback(callback)


func use_global_around(around: Callable, priority := 0, should_run := Callable()) -> void:
	var entry := {
		"around": around,
		"priority": priority,
		"should_run": should_run,
	}
	_global_around.append(entry)
	for pipeline in _pipelines.values():
		pipeline.use_around(around, priority, should_run)


func remove_global_by_callback(callback: Callable) -> void:
	_global_around = _global_around.filter(func(entry: Dictionary) -> bool: return entry.around != callback)
	for pipeline in _pipelines.values():
		pipeline.remove_by_callback(callback)


func pipeline_for(CommandClass: GDScript) -> GdlrCommandPipeline:
	if not _pipelines.has(CommandClass):
		var pipeline := GdlrCommandPipeline.new()
		for entry in _global_around:
			pipeline.use_around(entry.around, entry.priority, entry.should_run)
		_pipelines[CommandClass] = pipeline
	return _pipelines[CommandClass]
