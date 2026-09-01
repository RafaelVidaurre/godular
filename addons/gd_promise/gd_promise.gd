@tool
class_name GdPromise extends RefCounted

## Promise for GDScript with `then`, `catch`, and awaitable settlement.

## Emitted when the promise resolves.
signal resolved(value: Variant)
## Emitted when the promise rejects.
signal rejected(reason: Variant)
## Emitted when the promise settles with either outcome.
signal settled(state: Status, value_or_reason: Variant)

## Default rejection reason for `timeout()`.
const ERR_TIMEOUT = &"timeout"
## Settlement chains deeper than this emit deferred to protect the stack.
const MAX_SYNC_SETTLEMENT_DEPTH := 8

static var _id_counter: int = 0
static var _settlement_emit_depth: int = 0

## Promise lifecycle states.
enum Status {
	PENDING,
	RESOLVED,
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
## Alias of `value`.
var result: Variant:
	get:
		return value
## The resolved value or the rejection reason.
var value: Variant:
	get:
		return _value

## Unique identifier of the promise instance.
var id: int = _id_counter
var _status := Status.PENDING
var _value: Variant = null


func _to_string() -> String:
	return "GdPromise(%s:%s)" % [id, Status.keys()[_status]]


func _init(callback: Callable = func(resolve, _reject): resolve.call(null)) -> void:
	GdPromise._track_promise(self)
	callback.bind(_resolve, _reject).call()
	_id_counter += 1


## Chains a callback that runs with the resolved value. Returns a new promise.
func then(on_fulfilled: Callable) -> GdPromise:
	if is_rejected:
		return GdPromise.new_rejected(_value)

	return _create_promise_from_then_callback(on_fulfilled)


## Chains a callback that runs with the rejection reason. Returns a new promise.
func catch(callback: Callable) -> GdPromise:
	if is_resolved:
		return GdPromise.new_resolved(_value)

	return _create_promise_from_catch_callback(callback)


## Runs a callback regardless of the outcome and returns self.
func finally(callback: Callable) -> GdPromise:
	var callback_result = await callback.call()

	if callback_result != null:
		push_warning("GdPromise.finally() ignores callback return values.")

	return self


## Awaits resolution and returns the resolved value.
func await_resolved() -> Variant:
	if _status == Status.RESOLVED:
		return _value

	return await resolved


## Awaits settlement with either outcome.
func await_settled() -> void:
	if _status != Status.PENDING:
		return

	await settled


## Awaits rejection and returns the rejection reason.
func await_rejected() -> Variant:
	if _status == Status.REJECTED:
		return _value

	return await rejected


## Alias of `await_resolved()`.
func await_then() -> Variant:
	return await await_resolved()


## Alias of `await_rejected()`.
func await_catch() -> Variant:
	return await await_rejected()


## Alias of `await_settled()`.
func await_finally() -> void:
	await await_settled()


## Resolves the promise with a value. Does nothing after settlement.
func resolve(value_: Variant = null) -> void:
	_resolve(value_)


## Rejects the promise with a reason. Does nothing after settlement.
func reject(reason: Variant = null) -> void:
	_reject(reason)


func _resolve(value_: Variant = null) -> void:
	GdPromise._resolve_promise(self, value_)


func _reject(reason: Variant = null) -> void:
	GdPromise._reject_promise(self, reason)


func _emit_deferred_settlement(status_: Status, value_or_reason: Variant) -> void:
	GdPromise._emit_settlement_now(self, status_, value_or_reason)


func _create_promise_from_then_callback(callback: Callable) -> GdPromise:
	return GdPromise.new(func(resolve_, reject_):
		if is_resolved:
			var callback_result = await callback.call(value)

			if callback_result is GdPromise:
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


func _create_promise_from_catch_callback(callback: Callable) -> GdPromise:
	return GdPromise.new(func(resolve_, reject_):
		if is_rejected:
			var callback_result = await callback.call(_value)

			if callback_result is GdPromise:
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
	if callback_result is GdPromise:
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
	if callback_result is GdPromise:
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


## Creates a promise already resolved with a value.
static func new_resolved(value_: Variant = null) -> GdPromise:
	return GdPromise.new(func(resolve_, _reject): resolve_.call(value_))


## Creates a promise already rejected with a reason.
static func new_rejected(reason: Variant = null) -> GdPromise:
	return GdPromise.new(func(_resolve, reject_): reject_.call(reason))


## Resolves with all results in order, or rejects with the first reason.
static func all(promises: Array) -> GdPromise:
	return GdPromise.new(func(resolve_, reject_):
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


## Settles with the outcome of the first promise that settles.
static func race(promises: Array) -> GdPromise:
	return GdPromise.new(func(resolve_, reject_):
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


## Resolves after the given number of seconds.
static func sleep(duration: float) -> GdPromise:
	return GdPromise.new(func(resolve_, _reject):
		await (Engine.get_main_loop() as SceneTree).create_timer(duration).timeout
		resolve_.call()
	)


## Rejects after the given number of seconds.
static func timeout(duration: float, reason: Variant = ERR_TIMEOUT) -> GdPromise:
	return GdPromise.new(func(_resolve, reject_):
		await Engine.get_main_loop().root.get_tree().create_timer(duration).timeout
		reject_.call(reason)
	)


## Wraps a callable, signal, promise, or plain value in a promise.
static func to_promise(thing: Variant) -> GdPromise:
	if thing is Callable:
		return GdPromise._callable_to_promise(thing)

	if thing is GdPromise:
		return thing

	if thing is Signal:
		return GdPromise._signal_to_promise(thing)

	return GdPromise.new_resolved(thing)


## Resolves on the success signal or rejects on the failure signal.
static func from_signals(success_signal: Signal, failure_signal: Signal = Signal()) -> GdPromise:
	return GdPromise.new(func(resolve_, reject_):
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


static func _callable_to_promise(fn: Callable) -> GdPromise:
	return GdPromise.new(func(resolve_: Callable, _reject: Callable) -> void:
		var response = await fn.call()
		resolve_.call(response)
	)


static func _signal_to_promise(signal_: Signal) -> GdPromise:
	return GdPromise.new(func(resolve_, _reject):
		var signal_result = await signal_
		resolve_.call(signal_result)
	)


static func _resolve_promise(promise: GdPromise, value_: Variant) -> void:
	if promise._status != Status.PENDING:
		return

	promise._status = Status.RESOLVED
	promise._value = value_

	GdPromise._emit_settlement(promise, promise._status, value_)


static func _reject_promise(promise: GdPromise, reason: Variant = null) -> void:
	if promise._status != Status.PENDING:
		return

	promise._value = reason
	promise._status = Status.REJECTED

	GdPromise._emit_settlement(promise, promise._status, reason)


static func _emit_settlement(
	promise: GdPromise,
	status_: Status,
	value_or_reason: Variant,
) -> void:
	if _settlement_emit_depth >= MAX_SYNC_SETTLEMENT_DEPTH:
		promise._emit_deferred_settlement.call_deferred(status_, value_or_reason)
		return

	GdPromise._emit_settlement_now(promise, status_, value_or_reason)


static func _emit_settlement_now(
	promise: GdPromise,
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
	GdPromise._untrack_promise(promise)


static func _track_promise(promise: GdPromise) -> void:
	promise.reference()


static func _untrack_promise(promise: GdPromise) -> void:
	promise.unreference.call_deferred()
