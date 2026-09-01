# GdlrModuleProvider

Inherits: `RefCounted`

Describes how a module creates the value for one token.

## Properties

### `token: Variant`

The token this provider satisfies.

### `use: Variant`

A value, script, or callable used to create the provided value.

### `use_existing: Variant`

Uses another token when this value is not null.

### `requires: Array`

Dependencies passed to script constructors or callables in this order.

## Methods

### `func _init(token_: Variant, requires_: Array, use_: Variant, use_existing_: Variant = null) -> void`

### `func resolve(resolved_dependencies: Array) -> Variant`

Creates the provided value from the resolved dependencies.
