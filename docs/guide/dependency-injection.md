# Dependency injection

Each entry in `PROVIDERS` maps a token to a configuration dictionary. Godular builds a {ref}`GdlrModuleProvider <class_GdlrModuleProvider>` from it.

## Tokens

A token identifies a value. A token can be:

- a capability class, such as `CapScore`, or
- any other value, such as a `StringName`.

When the token is a class that extends `GdlrCapability`, the provided value must be an object whose script extends that class. Godular asserts this when it resolves the provider.

## Configuration keys

| Key | Meaning |
| --- | --- |
| `use` | A script, a callable, or a plain value. |
| `inject` | Tokens passed as positional arguments, in order. |
| `use_existing` | Another token. The provider resolves to the value of that token. |

`use` behaves by type:

- Script. Godular calls `new()` with the injected values as arguments.
- Callable. Godular calls it with the injected values as arguments. The callable can return a `GdbPromise`. Godular then waits for it.
- Any other value. Godular uses the value as is.

`inject` lists tokens. Godular resolves each token from the providers the module can see, then passes the values in the same order. See [Visibility](modules.md#visibility).

`use_existing` makes an alias. The provider resolves to the value of the other token. Do not combine it with `use`. When `use_existing` is set, Godular ignores `inject` and requires only the aliased token.

Godular asserts that a resolved value is not `null`.

## Example

```gdscript
class_name ConfigModule
extends GdlrModule

static var PROVIDERS = {
	&"first": {
		"use": func():
			return {"value": "first"},
	},
	&"second": {
		"inject": [&"first"],
		"use": func(first: Dictionary):
			return GdbPromise.new_resolved({"first": first}),
	},
	&"alias": {
		"use_existing": &"second",
	},
}
static var TREE_EXPORTS = [&"alias"]
```

- `&"first"` is a callable factory without dependencies.
- `&"second"` receives the value of `&"first"` and returns a promise. Godular waits for the promise.
- `&"alias"` resolves to the value of `&"second"`.

`GdlrModuleManager.request(&"alias")` returns `{"first": {"value": "first"}}`.

## Scope and caching

Godular creates one {ref}`GdlrDiContainer <class_GdlrDiContainer>` per module. A container builds each provider once and caches its value. Consumers of that provider receive the same value.
Separate modules can provide the same token with different values.

Godular resolves an injected token through the container of the module that provides it. A service exported by one module and used by three others is built once.

Concurrent requests share a pending resolution. If it fails, a later request can retry the provider.

## Asynchronous providers

A callable provider can return a `GdbPromise`. Godular resolves the promise before it uses the value. Providers that depend on the token wait as well. Use this for services that need to load data before they are ready.

`GdlrDiContainer.resolve_sync()` exists for synchronous resolution. Every provider in the dependency chain must then be synchronous.
