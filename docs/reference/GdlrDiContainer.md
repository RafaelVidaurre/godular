# GdlrDiContainer

Inherits: `RefCounted`

Resolves singleton providers and caches their values by token.

## Methods

### `func add_provider_factory(token: Variant, provider: GdlrDiContainer.ProviderFactory) -> void`

Registers a provider factory for a token.

### `func resolve(token: Variant) -> GdPromise`

Resolves a token asynchronously and caches the value.

### `func resolve_sync(token: Variant) -> Variant`

Resolves a token synchronously. All providers in the chain must be synchronous.
