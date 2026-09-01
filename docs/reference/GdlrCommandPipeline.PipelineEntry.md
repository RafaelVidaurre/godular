# GdlrCommandPipeline.PipelineEntry

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

### `func _init(callback: Callable, priority: int = 0, insertion_order: int = 0, should_run: Callable = Callable()) -> void`
