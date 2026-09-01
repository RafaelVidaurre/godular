# GdlrMiddlewarePipeline

Inherits: `RefCounted`

Runs prioritized before, around, after, and conditional core-override callbacks.

## Methods

### `func _init(core_: Callable = Callable()) -> void`

### `func set_core(fn: Callable) -> void`

Sets the callback the pipeline wraps.

### `func get_core() -> Callable`

Returns the core callback.

### `func set_core_override(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void`

The highest-priority matching override replaces the core callback.

### `func use_before(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void`

Before callbacks run by ascending priority, then insertion order.

### `func use_around(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void`

Around callbacks form an onion with lower priority on the outside.

### `func use_after(fn: Callable, priority: int = 0, should_run: Callable = Callable()) -> void`

After callbacks may transform the result and run in ascending order.

### `func remove_by_callback(fn: Callable) -> void`

Removes every pipeline entry that uses the given callback.

### `func run() -> Variant`

Runs the arguments through the pipeline and returns the result.
