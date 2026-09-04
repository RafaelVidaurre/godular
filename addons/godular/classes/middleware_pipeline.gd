class_name GdlrMiddlewarePipeline
extends RefCounted
## Wraps a core callable with before, around, after, and override callbacks.
##
## Create a pipeline around any callable and run it with the same arguments
## as the callable:
## [codeblock]
## var pipeline := GdlrMiddlewarePipeline.new(func(amount: int): return amount + 1)
## pipeline.use_before(func(amount: int): print("adding ", amount))
## pipeline.use_around(func(next: Callable, amount: int): return await next.call(amount * 2))
## pipeline.use_after(func(result: int, amount: int): return result * 3)
## var result = await pipeline.run(2)  # 15
## [/codeblock]
## Callback signatures, where [code]args[/code] are the arguments passed to
## [method run]:[br]
## - before: [code]func(args...)[/code]. Return values are ignored.[br]
## - around: [code]func(next: Callable, args...)[/code]. Call [code]next[/code]
## with the arguments to continue and return its result.[br]
## - after: [code]func(result, args...)[/code]. Return the result to pass on.[br]
## - core and core override: [code]func(args...)[/code].[br]
## - should_run: [code]func(args...) -> bool[/code].[br]
## The core and around callbacks can [code]await[/code]. Before and after
## callbacks run without [code]await[/code] and must return without waiting.
## [br][br]
## [b]Order.[/b] Before and after callbacks run by ascending priority, then by
## insertion order. Around callbacks form layers. The callback with the lowest
## priority is the outer layer. Among core overrides whose predicate matches,
## the one with the highest priority replaces the core.
##
## @tutorial(Middleware): https://rafaelvidaurre.github.io/godular/guide/middleware.html

var _core: Callable
var _before: Array[PipelineEntry] = []
var _around: Array[PipelineEntry] = []
var _after: Array[PipelineEntry] = []
var _core_overrides: Array[PipelineEntry] = []
var _next_insertion_order: int = 0


## Creates a pipeline. [param core_] is optional. Set it later with
## [method set_core].
func _init(core_ := Callable()) -> void:
	if core_.is_valid():
		set_core(core_)


## Sets the callable that the pipeline wraps.
func set_core(fn: Callable) -> void:
	_core = fn


## Returns the callable that the pipeline wraps.
func get_core() -> Callable:
	return _core


## Adds a callable that replaces the core when [param should_run] returns
## true. An override without a predicate always matches.
func set_core_override(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_core_override(e)


## Adds a callback that runs before the core.
func use_before(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_before(e)


## Adds a callback that wraps the core.
func use_around(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_around(e)


## Adds a callback that runs after the core and can replace the result.
func use_after(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void:
	var e := PipelineEntry.new(fn, priority, _next_insertion_order, should_run)
	_next_insertion_order += 1
	_insert_sorted_after(e)


## Removes every callback and override that uses [param fn].
func remove_by_callback(fn: Callable) -> void:
	_before = _before.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_around = _around.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_after = _after.filter(func(entry: PipelineEntry): return entry.callback != fn)
	_core_overrides = _core_overrides.filter(func(entry: PipelineEntry): return entry.callback != fn)


## Runs the arguments through the pipeline and returns the final result.
## Fails when no core is set.
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

## One registered callback with its ordering data.
##
## [b]Internal.[/b] The pipeline creates entries. User code does not.
class PipelineEntry extends RefCounted:
	## The registered callback.
	var callback: Callable
	## Sort key. Lower values run first.
	var priority: int
	## Tie breaker for entries with the same priority.
	var insertion_order: int
	## Optional predicate that decides if the entry runs.
	var should_run: Callable = Callable()

	func _init(cb: Callable, prio: int = 0, ins_order: int = 0, should: Callable = Callable()) -> void:
		callback = cb
		priority = prio
		insertion_order = ins_order
		should_run = should


	## Calls [member callback] with the given arguments and returns the
	## awaited result.
	func run_callback(...args) -> Variant:
		# Binding first keeps callback signature errors visible.
		var bound_fn: Callable = callback.bindv(args)

		return await bound_fn.call()
