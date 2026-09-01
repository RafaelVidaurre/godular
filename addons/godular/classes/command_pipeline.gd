extends RefCounted
class_name GdlrCommandPipeline


var _core: Callable
var _before: Array[PipelineEntry] = []
var _around: Array[PipelineEntry] = []
var _after: Array[PipelineEntry] = []
var _core_overrides: Array[PipelineEntry] = []
var _next_insertion_order: int = 0

func set_core(fn: Callable) -> void:
	_core = fn


func set_core_override(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_core_override(e)


func use_before(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_before(e)


func use_around(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_around(e)


func use_after(fn: Callable, priority := 0, should_run := Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_after(e)


func use(middleware: GdlrCommandMiddleware, priority := 0) -> void:
	var has_methods := false
	if middleware.has_method("_before"):
		has_methods = true
		var should_run := Callable()
		if middleware.has_method("_should_run_before"):
			should_run = middleware._should_run_before
		use_before(middleware._before, priority, should_run)

	if middleware.has_method("_around"):
		has_methods = true
		var should_run := Callable()
		if middleware.has_method("_should_run_around"):
			should_run = middleware._should_run_around
		use_around(middleware._around, priority, should_run)

	if middleware.has_method("_after"):
		has_methods = true
		var should_run := Callable()
		if middleware.has_method("_should_run_after"):
			should_run = middleware._should_run_after
		use_after(middleware._after, priority, should_run)

	if not has_methods:
		push_error("GdlrCommandMiddleware %s does not implement a pipeline callback." % middleware.get_script().resource_path)
		return


func remove_by_callback(fn: Callable) -> void:
	_before = _before.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_around = _around.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_after = _after.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_core_overrides = _core_overrides.filter(func(entry: PipelineEntry): return entry.callback != fn)


func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant:
	assert(_core.is_valid(), "GdlrCommandPipeline: core function not registered for command: %s." % envelope.command)

	var core_fn := _select_core(envelope, ctx)

	for e in _before:
		if _should_entry_run(e.should_run, envelope, ctx):
			e.callback.call(envelope, ctx)

	var next := func(e, c): return await core_fn.call(e, c)
	for i in range(_around.size() - 1, -1, -1):
		var around_entry := _around[i]
		if !_should_entry_run(around_entry.should_run, envelope, ctx):
			continue
		var inner_next := next
		next = func(e: CapGdlrCommandBus.CommandEnvelope, c: CapGdlrCommandHandlers.Context): return await around_entry.callback.call(inner_next, e, c)

	var result := await next.call(envelope, ctx)

	for e in _after:
		if _should_entry_run(e.should_run, envelope, ctx):
			result = e.callback.call(envelope, ctx, result)

	return result


func _should_entry_run(should_run: Callable, envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> bool:
	if !should_run.is_valid():
		return true
	return should_run.call(envelope, ctx)


func _select_core(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Callable:
	if _core_overrides.is_empty():
		return _core
	var selected := _core
	for override in _core_overrides:
		if _should_entry_run(override.should_run, envelope, ctx):
			selected = override.callback
	return selected


func _insert_sorted_before(entry: PipelineEntry) -> void:
	var idx := _lower_bound(_before, entry.priority, entry.insertion_order)
	_before.insert(idx, entry)


func _insert_sorted_after(entry: PipelineEntry) -> void:
	var idx := _lower_bound(_after, entry.priority, entry.insertion_order)
	_after.insert(idx, entry)


func _insert_sorted_around(entry: PipelineEntry) -> void:
	var idx := _lower_bound(_around, entry.priority, entry.insertion_order)
	_around.insert(idx, entry)


func _insert_sorted_core_override(entry: PipelineEntry) -> void:
	var idx := _lower_bound(_core_overrides, entry.priority, entry.insertion_order)
	_core_overrides.insert(idx, entry)


func _lower_bound(entries: Array, priority: int, insertion_order: int) -> int:
	var lo := 0
	var hi := entries.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		var m = entries[mid]
		if priority < m.priority:
			hi = mid
		elif priority > m.priority:
			lo = mid + 1
		else:
			if insertion_order <= m.insertion_order:
				hi = mid
			else:
				lo = mid + 1
	return lo


class PipelineEntry extends RefCounted:
	var callback: Callable
	var priority: int
	var insertion_order: int
	var should_run: Callable = Callable()

	func _init(callback: Callable, priority: int = 0, insertion_order: int = 0, should_run: Callable = Callable()) -> void:
		self.callback = callback
		self.priority = priority
		self.insertion_order = insertion_order
		self.should_run = should_run
