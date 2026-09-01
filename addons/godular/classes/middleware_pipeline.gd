class_name GdlrMiddlewarePipeline
extends RefCounted

## Runs prioritized before, around, after, and conditional core-override callbacks.

var _core: Callable
var _before: Array[PipelineEntry] = []
var _around: Array[PipelineEntry] = []
var _after: Array[PipelineEntry] = []
var _core_overrides: Array[PipelineEntry] = []
var _next_insertion_order: int = 0


func _init(core_ := Callable()) -> void:
	if core_.is_valid():
		set_core(core_)


func set_core(fn: Callable) -> void:
	_core = fn


func get_core() -> Callable:
	return _core


## The highest-priority matching override replaces the core callback.
func set_core_override(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_core_override(e)


## Before callbacks run by ascending priority, then insertion order.
func use_before(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_before(e)


## Around callbacks form an onion with lower priority on the outside.
func use_around(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_around(e)


## After callbacks may transform the result and run in ascending order.
func use_after(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_after(e)


func remove_by_callback(fn: Callable) -> void:
	_before = _before.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_around = _around.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_after = _after.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_core_overrides = _core_overrides.filter(func(entry: PipelineEntry): return entry.callback != fn)


func run(...args) -> Variant:
	assert(_core.is_valid(), "GdlrMiddlewarePipeline core not set")

	var core_fn := _select_core(args)

	for e in _before:
		if _should_entry_run(e.should_run, args):
			e.run_callback.callv(args)

	var next := func(...arguments): return await core_fn.callv(arguments)
	for i in range(_around.size() - 1, -1, -1):
		var around_entry := _around[i]
		if !_should_entry_run(around_entry.should_run, args):
			continue
		var inner_next := next
		next = func(...arguments):
			var callback_args = [inner_next]
			callback_args.append_array(arguments)
			return await around_entry.run_callback.callv(callback_args)

	var result := await next.callv(args)

	for e in _after:
		if _should_entry_run(e.should_run, args):
			var after_args := [result]
			after_args.append_array(args)
			result = e.run_callback.callv(after_args)

	return result


func _should_entry_run(should_run: Callable, args: Array) -> bool:
	if not should_run.is_valid():
		return true
	return should_run.callv(args)


func _select_core(args: Array) -> Callable:
	if _core_overrides.is_empty():
		return _core
	var selected := _core
	for override in _core_overrides:
		if _should_entry_run(override.should_run, args):
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

	func _init(cb: Callable, prio: int = 0, ins_order: int = 0, should: Callable = Callable()) -> void:
		callback = cb
		priority = prio
		insertion_order = ins_order
		should_run = should


	func run_callback(...args) -> Variant:
		# Binding first keeps callback signature errors visible.
		var bound_fn: Callable = callback.bindv(args)

		return await bound_fn.call()
