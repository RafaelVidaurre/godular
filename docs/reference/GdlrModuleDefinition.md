# GdlrModuleDefinition

Inherits: `RefCounted`

Builds a module configuration with chained `imports`, `exports`, `providers`, and `tree_exports` calls.

## Properties

### `ModuleScript: GDScript`

The script that contains the module class.

## Methods

### `func get_imports() -> Dictionary[GDScript, GdlrModuleDefinition]`

Returns the processed imports keyed by module script.

### `func get_exports() -> Dictionary[Variant, bool]`

Returns the exported tokens.

### `func get_providers() -> Dictionary[Variant, Dictionary]`

Returns the provider configurations keyed by token.

### `func get_tree_exports() -> Dictionary[Variant, bool]`

Returns the tokens exposed to the scene tree.

### `func imports(imports_: Array = []) -> GdlrModuleDefinition`

Adds imported modules and returns self for chaining.

### `func providers(providers_: Dictionary = {}) -> GdlrModuleDefinition`

Adds provider configurations and returns self for chaining.

### `func tree_exports(tree_exports_: Array = []) -> GdlrModuleDefinition`

Adds tokens exposed to the scene tree and returns self for chaining.

### `func exports(exports_: Array = []) -> GdlrModuleDefinition`

Adds tokens visible to importing modules and returns self for chaining.

### `static func get_module_class(ModuleScript_: GDScript) -> GDScript`

Returns the `GdlrModule` subclass declared in a module script.
