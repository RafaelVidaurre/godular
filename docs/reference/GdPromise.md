# GdPromise

Inherits: `RefCounted`

Promise for GDScript with `then`, `catch`, and awaitable settlement.

## Signals

### `resolved(value: Variant)`

Emitted when the promise resolves.

### `rejected(reason: Variant)`

Emitted when the promise rejects.

### `settled(state: int, value_or_reason: Variant)`

Emitted when the promise settles with either outcome.

## Enumerations

### `Status`

- `PENDING` = `0`
- `RESOLVED` = `1`
- `REJECTED` = `2`

## Constants

- `ERR_TIMEOUT` = `&"timeout"` — Default rejection reason for `timeout()`.
- `MAX_SYNC_SETTLEMENT_DEPTH` = `8` — Settlement chains deeper than this emit deferred to protect the stack.

## Properties

### `is_settled: bool`

True when the promise is no longer pending.

### `is_resolved: bool`

True when the promise resolved.

### `is_rejected: bool`

True when the promise rejected.

### `status: int`

The current promise state.

### `result: Variant`

Alias of `value`.

### `value: Variant`

The resolved value or the rejection reason.

### `id: int`

Unique identifier of the promise instance.

## Methods

### `func _init(callback: Callable = <anonymous lambda>) -> void`

### `func then(on_fulfilled: Callable) -> GdPromise`

Chains a callback that runs with the resolved value. Returns a new promise.

### `func catch(callback: Callable) -> GdPromise`

Chains a callback that runs with the rejection reason. Returns a new promise.

### `func finally(callback: Callable) -> GdPromise`

Runs a callback regardless of the outcome and returns self.

### `func await_resolved() -> Variant`

Awaits resolution and returns the resolved value.

### `func await_settled() -> void`

Awaits settlement with either outcome.

### `func await_rejected() -> Variant`

Awaits rejection and returns the rejection reason.

### `func await_then() -> Variant`

Alias of `await_resolved()`.

### `func await_catch() -> Variant`

Alias of `await_rejected()`.

### `func await_finally() -> void`

Alias of `await_settled()`.

### `func resolve(value_: Variant = null) -> void`

Resolves the promise with a value. Does nothing after settlement.

### `func reject(reason: Variant = null) -> void`

Rejects the promise with a reason. Does nothing after settlement.

### `static func new_resolved(value_: Variant = null) -> GdPromise`

Creates a promise already resolved with a value.

### `static func new_rejected(reason: Variant = null) -> GdPromise`

Creates a promise already rejected with a reason.

### `static func all(promises: Array) -> GdPromise`

Resolves with all results in order, or rejects with the first reason.

### `static func race(promises: Array) -> GdPromise`

Settles with the outcome of the first promise that settles.

### `static func sleep(duration: float) -> GdPromise`

Resolves after the given number of seconds.

### `static func timeout(duration: float, reason: Variant = &"timeout") -> GdPromise`

Rejects after the given number of seconds.

### `static func to_promise(thing: Variant) -> GdPromise`

Wraps a callable, signal, promise, or plain value in a promise.

### `static func from_signals(success_signal: Signal, failure_signal: Signal = Signal()) -> GdPromise`

Resolves on the success signal or rejects on the failure signal.
