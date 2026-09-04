# Promises

{ref}`GdPromise <class_GdPromise>` is the promise library that Godular uses for asynchronous work. It ships in `addons/gd_promise`. A promise settles once, with a resolved value or a rejection reason. A settled promise is safe to await again.

## Creating a promise

The constructor takes an executor callable. Godular calls it at once with a `resolve` callable and a `reject` callable. The executor can `await`:

```gdscript
var loaded := GdPromise.new(func(resolve: Callable, reject: Callable):
	var result := await load_level()
	if result.ok:
		resolve.call(result.level)
	else:
		reject.call(result.error)
)
```

Without an executor, the promise resolves with `null`.

Shortcuts:

- `GdPromise.new_resolved(value)` creates a resolved promise.
- `GdPromise.new_rejected(reason)` creates a rejected promise.
- `promise.resolve(value)` and `promise.reject(reason)` settle a pending promise. They do nothing after settlement.

## Reading the state

| Member | Meaning |
| --- | --- |
| `is_settled` | True when the promise is no longer pending. |
| `is_resolved` | True when the promise resolved. |
| `is_rejected` | True when the promise rejected. |
| `status` | `Status.PENDING`, `Status.RESOLVED`, or `Status.REJECTED`. |
| `value` | The resolved value or the rejection reason. |
| `result` | Alias of `value`. |

## Awaiting

| Method | Behaviour |
| --- | --- |
| `await_resolved()` | Waits for resolution and returns the value. A rejected promise never returns from it. |
| `await_rejected()` | Waits for rejection and returns the reason. A resolved promise never returns from it. |
| `await_settled()` | Waits for either outcome. |

`await_then()`, `await_catch()`, and `await_finally()` are aliases of these three methods.

Check the state after `await_settled()` when both outcomes are possible:

```gdscript
await promise.await_settled()
if promise.is_rejected:
	push_error(promise.value)
```

## Chaining

`then(on_fulfilled)` returns a new promise. When this promise resolves, the callback runs with the value and the new promise resolves with the return value of the callback. When the callback returns a promise, the new promise follows it. When this promise rejects, the callback does not run and the new promise rejects with the same reason.

`catch(callback)` returns a new promise. When this promise rejects, the callback runs with the reason and the new promise rejects with the return value of the callback. When the callback returns a promise, the new promise follows that promise. When this promise resolves, the new promise resolves with the same value.

`catch()` does not recover the chain into a resolved state. This differs from JavaScript. To continue with a resolved value after a failure, return a resolved promise from the callback:

```gdscript
var safe := risky.catch(func(_reason):
	return GdPromise.new_resolved(default_value)
)
```

`finally(callback)` calls the callback at once, awaits it, and returns this promise. It does not wait for settlement. The return value of the callback is ignored. A non-null return value logs a warning.

## Combining

`GdPromise.all(promises)` resolves with an array of the results in the same order once every promise resolves. It rejects with the first rejection reason. An empty array resolves with an empty array.

`GdPromise.race(promises)` settles with the outcome of the first promise that settles. An empty array never settles.

```gdscript
var results: Array = await GdPromise.all([
	GdPromise.new_resolved(1),
	GdPromise.new_resolved(2),
]).await_resolved()  # [1, 2]
```

## Timers

`GdPromise.sleep(duration)` resolves after `duration` seconds.

`GdPromise.timeout(duration, reason)` rejects after `duration` seconds. `reason` defaults to `GdPromise.ERR_TIMEOUT`. Combine it with `race()` to limit the time of another promise.

Both use a scene tree timer. They need a running `SceneTree`.

## Converting

`GdPromise.to_promise(thing)` returns a promise for any value:

- A callable is called. The promise resolves with its awaited return value.
- A signal resolves the promise with its next emission.
- A promise is returned as is.
- Any other value becomes a resolved promise.

`GdPromise.from_signals(success_signal, failure_signal)` resolves with the first emission of the success signal or rejects with the first emission of the failure signal. Each signal must emit one argument. The failure signal is optional.

## Signals

A promise emits `resolved(value)`, `rejected(reason)`, and `settled(state, value_or_reason)`. The `settled` signal emits first.

Deeply nested settlements are emitted with `call_deferred()` once the nesting reaches `GdPromise.MAX_SYNC_SETTLEMENT_DEPTH`. The value is 8.
