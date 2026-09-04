# Middleware

{ref}`GdlrMiddlewarePipeline <class_GdlrMiddlewarePipeline>` wraps one callable, the core, with callbacks that run before it, around it, and after it. Run the pipeline with the same arguments as the core.

```gdscript
var pipeline := GdlrMiddlewarePipeline.new(func(value: int): return value + 1)
var result = await pipeline.run(2)  # 3
```

Set or replace the core later with `set_core()`. Read it with `get_core()`.

## Callbacks

`args` stands for the arguments passed to `run()`. The core and around callbacks can `await`. Before and after callbacks run without `await`, so they must return without waiting.

| Method | Signature | Return value |
| --- | --- | --- |
| `use_before(fn, priority, should_run)` | `func(args...)` | Ignored. |
| `use_around(fn, priority, should_run)` | `func(next: Callable, args...)` | The result to pass on. Call `next` with the arguments to continue. |
| `use_after(fn, priority, should_run)` | `func(result, args...)` | The new result. |
| `set_core_override(fn, priority, should_run)` | `func(args...)` | The result. Replaces the core when `should_run` returns true. |

`priority` defaults to `0`. `should_run` is optional. It has the signature `func(args...) -> bool`. When it returns false, the pipeline skips the callback. An override without a predicate always matches.

## Order

- Before callbacks run by ascending priority. Callbacks with the same priority run in insertion order.
- After callbacks follow the same rule.
- Around callbacks form layers. The callback with the lowest priority is the outer layer.
- Among core overrides whose predicate matches, the one with the highest priority replaces the core. Among overrides with the same priority, the last one added wins.

`remove_by_callback(fn)` removes every before, around, after, and override entry that uses `fn`.

## Worked example

This is the pipeline from the test suite:

```gdscript
var events: Array[String] = []
var pipeline := GdlrMiddlewarePipeline.new(func(value: int):
	events.append("core")
	return value + 1
)
pipeline.use_before(func(_value: int): events.append("before-high"), 10)
pipeline.use_before(func(_value: int): events.append("before-low"), -10)
pipeline.use_around(func(next: Callable, value: int):
	events.append("around-enter")
	var result = await next.call(value * 2)
	events.append("around-exit")
	return result
)
pipeline.use_after(func(result: int, _value: int):
	events.append("after")
	return result * 3
)
var result = await pipeline.run(2)
```

`result` is `15`. The around callback doubles `2` to `4`, the core adds `1`, and the after callback multiplies `5` by `3`.

`events` is `["before-low", "before-high", "around-enter", "core", "around-exit", "after"]`. The before callback with priority `-10` runs before the one with priority `10`.

Add an override that matches only the value `4`:

```gdscript
pipeline.set_core_override(func(_value: int): return 9, 5, func(value: int): return value == 4)
var overridden = await pipeline.run(4)
```

`overridden` is `27`. The around callback doubles `4` to `8`, the predicate receives `4` and matches, the override returns `9`, and the after callback multiplies it by `3`.

The pipeline evaluates the override predicates with the original arguments of `run()`, not with the arguments that around callbacks pass to `next`.

## Command pipelines

The command bus uses {ref}`GdlrCommandPipeline <class_GdlrCommandPipeline>`, a pipeline with a fixed argument list of an envelope and a context. See [Command bus](command-bus.md).
