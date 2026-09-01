# GdlrDiContainer.ProviderFactory

Inherits: `RefCounted`

Resolves one provider definition together with its dependencies.

## Methods

### `func _init(provider_definition: GdlrModuleProvider, dependency_providers: Dictionary[Variant, GdlrDiContainer.ProviderFactory] = {}, owner_container: GdlrDiContainer = null) -> void`

### `func resolve() -> GdPromise`

Resolves the dependencies, then the provider value.

### `func resolve_sync() -> Variant`

Resolves the dependencies and the provider value synchronously.
