@tool
class_name GdbPromise extends RefCounted
## Promise for GDScript.
##
## A promise settles once, with a resolved value or a rejection reason.
## Create one with an executor callable that receives
## [code skip-lint]resolve[/code] and [code skip-lint]reject[/code] callables:
## [codeblock]
## var loaded := GdbPromise.new(func(resolve: Callable, reject: Callable):
##     var result := await load_level()
##     if result.ok:
##         resolve.call(result.level)
##     else:
##         reject.call(result.error)
## )
## var level = await loaded.await_resolved()
## [/codeblock]
## Chain work with [method then] and [method catch], combine promises with
## [method all] and [method race], and wrap callables and signals with
## [method to_promise]. Settled promises are safe to await again.
##
## @tutorial(Promises): https://rafaelvidaurre.github.io/godular/guide/promises.html

## Emitted when the promise resolves.
signal resolved(value: Variant)
## Emitted when the promise rejects.
signal rejected(reason: Variant)
## Emitted when the promise settles with either outcome.
signal settled(state: Status, value_or_reason: Variant)

## Default rejection reason of [method timeout].
const ERR_TIMEOUT = &"timeout"
## Maximum depth of nested settlements handled in one call stack. Deeper
## settlements are emitted with [code]call_deferred()[/code] to protect the
## stack.
const MAX_SYNC_SETTLEMENT_DEPTH := 8

static var _id_counter: int = 0
static var _settlement_emit_depth: int = 0

## Promise lifecycle states.
enum Status {
	## The promise has not settled.
	PENDING,
	## The promise resolved with a value.
	RESOLVED,
	## The promise rejected with a reason.
	REJECTED,
}

## True when the promise is no longer pending.
var is_settled: bool:
	get:
		return _status != Status.PENDING
## True when the promise resolved.
var is_resolved: bool:
	get:
		return _status == Status.RESOLVED
## True when the promise rejected.
var is_rejected: bool:
	get:
		return _status == Status.REJECTED

## The current promise state.
var status: Status:
	get:
		return _status
## Alias of [member value].
var result: Variant:
	get:
		return value
## The resolved value or the rejection reason.
var value: Variant:
	get:
		return _value

## Sequence number of the promise instance.
var id: int = _id_counter
var _status := Status.PENDING
var _value: Variant = null


func _to_string() -> String:
	return "GdbPromise(%s:%s)" % [id, Status.keys()[_status]]


## Creates a promise and calls [param callback] with the
## [code skip-lint]resolve[/code] and [code skip-lint]reject[/code] callables. The callback can [code]await[/code].
## Without a callback the promise resolves with [code]null[/code].
func _init(callback: Callable = func(resolve, _reject): resolve.call(null)) -> void:
	GdbPromise._track_promise(self)
	callback.bind(_resolve, _reject).call()
	_id_counter += 1


## Returns a new promise that resolves with the return value of
## [param on_fulfilled], called with the resolved value. When the callback
## returns a promise, the new promise follows it. A rejection skips the
## callback and rejects the new promise with the same reason.
func then(on_fulfilled: Callable) -> GdbPromise:
	if is_rejected:
		return GdbPromise.new_rejected(_value)

	return _create_promise_from_then_callback(on_fulfilled)


## Returns a new promise. When this promise rejects, [param callback] runs
## with the reason and the new promise rejects with the return value of the
## callback. When the callback returns a promise, the new promise follows
## it. When this promise resolves, the new promise resolves with the same
## value.
## [b]Note:[/b] Unlike JavaScript, [method catch] does not recover the
## chain into a resolved state.
func catch(callback: Callable) -> GdbPromise:
	if is_resolved:
		return GdbPromise.new_resolved(_value)

	return _create_promise_from_catch_callback(callback)


## Calls [param callback] at once, awaits it, and returns this promise.
## The method does not wait for settlement. The return value of the
## callback is ignored, with a warning when it is not [code]null[/code].
func finally(callback: Callable) -> GdbPromise:
	var callback_result = await callback.call()

	if callback_result != null:
		push_warning("GdbPromise.finally() ignores callback return values.")

	return self


## Waits until the promise resolves and returns the value. A rejected
## promise never returns from this method.
func await_resolved() -> Variant:
	if _status == Status.RESOLVED:
		return _value

	return await resolved


## Waits until the promise settles with either outcome.
func await_settled() -> void:
	if _status != Status.PENDING:
		return

	await settled


## Waits until the promise rejects and returns the reason. A resolved
## promise never returns from this method.
func await_rejected() -> Variant:
	if _status == Status.REJECTED:
		return _value

	return await rejected


## Alias of [method await_resolved].
func await_then() -> Variant:
	return await await_resolved()


## Alias of [method await_rejected].
func await_catch() -> Variant:
	return await await_rejected()


## Alias of [method await_settled].
func await_finally() -> void:
	await await_settled()


## Resolves the promise with [param value_]. Does nothing after settlement.
func resolve(value_: Variant = null) -> void:
	_resolve(value_)


## Rejects the promise with [param reason]. Does nothing after settlement.
func reject(reason: Variant = null) -> void:
	_reject(reason)


func _resolve(value_: Variant = null) -> void:
	GdbPromise._resolve_promise(self, value_)


func _reject(reason: Variant = null) -> void:
	GdbPromise._reject_promise(self, reason)


func _emit_deferred_settlement(status_: Status, value_or_reason: Variant) -> void:
	GdbPromise._emit_settlement_now(self, status_, value_or_reason)


func _create_promise_from_then_callback(callback: Callable) -> GdbPromise:
	return GdbPromise.new(func(resolve_, reject_):
		if is_resolved:
			var callback_result = await callback.call(value)

			if callback_result is GdbPromise:
				if callback_result.is_resolved:
					resolve_.call(callback_result.value)
					return
				if callback_result.is_rejected:
					reject_.call(callback_result.value)
					return

				callback_result.resolved.connect(func(value_: Variant):
					resolve_.call(value_)
				)
				callback_result.rejected.connect(func(reason: Variant):
					reject_.call(reason)
				)
				return

			resolve_.call(callback_result)
			return

		settled.connect(func(state: Status, value_or_reason: Variant):
			if state == Status.REJECTED:
				reject_.call(value_or_reason)
				return

			_on_resolved_within_callback.call(value_or_reason, callback, resolve_, reject_)
		)
	)


func _create_promise_from_catch_callback(callback: Callable) -> GdbPromise:
	return GdbPromise.new(func(resolve_, reject_):
		if is_rejected:
			var callback_result = await callback.call(_value)

			if callback_result is GdbPromise:
				if callback_result.is_resolved:
					resolve_.call(callback_result.value)
					return
				if callback_result.is_rejected:
					reject_.call(callback_result.value)
					return

				callback_result.resolved.connect(func(value_: Variant):
					resolve_.call(value_)
				)
				callback_result.rejected.connect(func(reason: Variant):
					reject_.call(reason)
				)
				return

			reject_.call(callback_result)
			return

		settled.connect(func(state: Status, value_or_reason: Variant):
			if state == Status.RESOLVED:
				resolve_.call(value_or_reason)
				return

			_on_rejected_within_callback.call(value_or_reason, callback, resolve_, reject_)
		)
	)


func _on_rejected_within_callback(
	value_: Variant,
	callback: Callable,
	resolve_: Callable,
	reject_: Callable,
) -> void:
	var callback_result = await callback.call(value_)
	if callback_result is GdbPromise:
		if callback_result.is_resolved:
			resolve_.call(callback_result.value)
			return
		if callback_result.is_rejected:
			reject_.call(callback_result.value)
			return
		callback_result.resolved.connect(func(resolved_value: Variant):
			resolve_.call(resolved_value)
		)
		callback_result.rejected.connect(func(reason: Variant):
			reject_.call(reason)
		)
		return

	reject_.call(callback_result)


func _on_resolved_within_callback(
	value_: Variant,
	callback: Callable,
	resolve_: Callable,
	reject_: Callable,
) -> void:
	var callback_result = await callback.call(value_)
	if callback_result is GdbPromise:
		if callback_result.is_resolved:
			resolve_.call(callback_result.value)
			return
		if callback_result.is_rejected:
			reject_.call(callback_result.value)
			return
		callback_result.resolved.connect(func(resolved_value: Variant):
			resolve_.call(resolved_value)
		)
		callback_result.rejected.connect(func(reason: Variant):
			reject_.call(reason)
		)
		return

	resolve_.call(callback_result)


## Creates a promise resolved with [param value_].
static func new_resolved(value_: Variant = null) -> GdbPromise:
	return GdbPromise.new(func(resolve_, _reject): resolve_.call(value_))


## Creates a promise rejected with [param reason].
static func new_rejected(reason: Variant = null) -> GdbPromise:
	return GdbPromise.new(func(_resolve, reject_): reject_.call(reason))


## Returns a promise that resolves with an array of the results of
## [param promises], in the same order, once all of them resolve. It
## rejects with the first rejection reason. An empty array resolves with an
## empty array.
static func all(promises: Array) -> GdbPromise:
	return GdbPromise.new(func(resolve_, reject_):
		if promises.is_empty():
			resolve_.call([])
			return

		var state := {
			"completed_count": 0,
			"results": [],
			"is_settled": false,
		}

		state.results.resize(promises.size())

		for i in range(promises.size()):
			var promise = promises[i]
			if promise._status == Status.REJECTED:
				if not state.is_settled:
					state.is_settled = true
					reject_.call(promise._value)
				return
			elif promise._status == Status.RESOLVED:
				state.results[i] = promise._value
				state.completed_count += 1
			else:
				promise.resolved.connect(func(value_: Variant):
					if state.is_settled:
						return
					state.results[i] = value_
					state.completed_count += 1
					if state.completed_count == promises.size():
						state.is_settled = true
						resolve_.call(state.results)
				)

				promise.rejected.connect(func(reason: Variant):
					if state.is_settled:
						return
					state.is_settled = true
					reject_.call(reason)
				)

		if state.completed_count == promises.size():
			resolve_.call(state.results)
	)


## Returns a promise that settles with the outcome of the first promise in
## [param promises] that settles. An empty array never settles.
static func race(promises: Array) -> GdbPromise:
	return GdbPromise.new(func(resolve_, reject_):
		if promises.is_empty():
			return

		var state := {
			"is_settled": false,
		}

		for promise in promises:
			if promise._status == Status.RESOLVED:
				if not state.is_settled:
					state.is_settled = true
					resolve_.call(promise.result)
				return
			if promise._status == Status.REJECTED:
				if not state.is_settled:
					state.is_settled = true
					reject_.call(promise.result)
				return

			promise.resolved.connect(func(value_: Variant):
				if state.is_settled:
					return
				state.is_settled = true
				resolve_.call(value_)
			)

			promise.rejected.connect(func(reason: Variant):
				if state.is_settled:
					return
				state.is_settled = true
				reject_.call(reason)
			)
	)


## Returns a promise that resolves after [param duration] seconds.
static func sleep(duration: float) -> GdbPromise:
	return GdbPromise.new(func(resolve_, _reject):
		await (Engine.get_main_loop() as SceneTree).create_timer(duration).timeout
		resolve_.call()
	)


## Returns a promise that rejects with [param reason] after
## [param duration] seconds.
static func timeout(duration: float, reason: Variant = ERR_TIMEOUT) -> GdbPromise:
	return GdbPromise.new(func(_resolve, reject_):
		await Engine.get_main_loop().root.get_tree().create_timer(duration).timeout
		reject_.call(reason)
	)


## Returns a promise for [param thing]. A callable is called and the
## promise resolves with its awaited return value. A signal resolves the
## promise with its next emission. A promise is returned as is. Any other
## value becomes a resolved promise.
static func to_promise(thing: Variant) -> GdbPromise:
	if thing is Callable:
		return GdbPromise._callable_to_promise(thing)

	if thing is GdbPromise:
		return thing

	if thing is Signal:
		return GdbPromise._signal_to_promise(thing)

	return GdbPromise.new_resolved(thing)


## Returns a promise that resolves with the first emission of
## [param success_signal] or rejects with the first emission of
## [param failure_signal]. Both signals must emit exactly one argument.
static func from_signals(success_signal: Signal, failure_signal: Signal = Signal()) -> GdbPromise:
	return GdbPromise.new(func(resolve_, reject_):
		success_signal.connect(func(value_: Variant):
			if not failure_signal.is_null() and failure_signal.is_connected(reject_):
				failure_signal.disconnect(reject_)
			resolve_.call(value_)
		, CONNECT_ONE_SHOT)

		if not failure_signal.is_null():
			failure_signal.connect(func(reason: Variant):
				if success_signal.is_connected(resolve_):
					success_signal.disconnect(resolve_)
				reject_.call(reason)
			, CONNECT_ONE_SHOT)
	)


static func _callable_to_promise(fn: Callable) -> GdbPromise:
	return GdbPromise.new(func(resolve_: Callable, _reject: Callable) -> void:
		var response = await fn.call()
		resolve_.call(response)
	)


static func _signal_to_promise(signal_: Signal) -> GdbPromise:
	return GdbPromise.new(func(resolve_, _reject):
		var signal_result = await signal_
		resolve_.call(signal_result)
	)


static func _resolve_promise(promise: GdbPromise, value_: Variant) -> void:
	if promise._status != Status.PENDING:
		return

	promise._status = Status.RESOLVED
	promise._value = value_

	GdbPromise._emit_settlement(promise, promise._status, value_)


static func _reject_promise(promise: GdbPromise, reason: Variant = null) -> void:
	if promise._status != Status.PENDING:
		return

	promise._value = reason
	promise._status = Status.REJECTED

	GdbPromise._emit_settlement(promise, promise._status, reason)


static func _emit_settlement(
	promise: GdbPromise,
	status_: Status,
	value_or_reason: Variant,
) -> void:
	if _settlement_emit_depth >= MAX_SYNC_SETTLEMENT_DEPTH:
		promise._emit_deferred_settlement.call_deferred(status_, value_or_reason)
		return

	GdbPromise._emit_settlement_now(promise, status_, value_or_reason)


static func _emit_settlement_now(
	promise: GdbPromise,
	status_: Status,
	value_or_reason: Variant,
) -> void:
	_settlement_emit_depth += 1
	promise.settled.emit(status_, value_or_reason)

	if status_ == Status.RESOLVED:
		promise.resolved.emit(value_or_reason)
	else:
		promise.rejected.emit(value_or_reason)

	_settlement_emit_depth -= 1
	GdbPromise._untrack_promise(promise)


static func _track_promise(promise: GdbPromise) -> void:
	promise.reference()


static func _untrack_promise(promise: GdbPromise) -> void:
	promise.unreference.call_deferred()
