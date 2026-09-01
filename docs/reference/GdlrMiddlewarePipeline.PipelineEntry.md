# GdlrMiddlewarePipeline.PipelineEntry

Inherits: `RefCounted`

One registered pipeline callback with its ordering data.

## Properties

### `callback: Callable`

The registered callback.

### `priority: int`

Sort key. Lower values run first.

### `insertion_order: int`

Tie breaker for entries with the same priority.

### `should_run: Callable`

Optional predicate that decides if the entry runs.

## Methods

### `func _init(cb: Callable, prio: int = 0, ins_order: int = 0, should: Callable = Callable()) -> void`

### `func run_callback() -> Variant`

Calls the callback with the given arguments and awaits the result.
