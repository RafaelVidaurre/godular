# Modules

A module is a script that extends {ref}`GdlrModule <class_GdlrModule>`. Godular reads four optional static members from the module script.

| Member | Type | Meaning |
| --- | --- | --- |
| `IMPORTS` | Array | Modules this module depends on. Godular creates and enables them first. |
| `PROVIDERS` | Dictionary | How to build each token. See [Dependency injection](dependency-injection.md). |
| `EXPORTS` | Array | Tokens that modules importing this module can use. |
| `TREE_EXPORTS` | Array | Tokens that any node can get through `GdlrModuleManager.request()`. |

```gdscript
class_name GameModule
extends GdlrModule

static var IMPORTS = [SettingsModule]
static var PROVIDERS = {
	CapScore: {"use": SvcScore, "inject": [CapSettings]},
}
static var EXPORTS = [CapScore]
static var TREE_EXPORTS = [CapScore]
```

Declare the members with `static var` or `const`. Godular reads them by name from the script.

## Module scripts without a class

A module script can be a plain script that holds the static members and an inner class that extends `GdlrModule`. Godular instantiates the inner class. The bundled jobs module uses this form:

```gdscript
# addons/godular/built_ins/modules/jobs/md_jobs.gd
const SvcJobs = preload("./services/svc_jobs.gd")
const RegJobs = preload("./registries/reg_jobs.gd")

static var PROVIDERS = {
	CapGdlrJobsRegistry: {"use": RegJobs},
	CapGdlrJobs: {"inject": [CapGdlrJobsRegistry], "use": SvcJobs},
}
static var EXPORTS = [CapGdlrJobsRegistry, CapGdlrJobs]
static var TREE_EXPORTS = [CapGdlrJobs]

class JobsModule extends GdlrModule:
	pass
```

`GdlrModuleDefinition.get_module_class()` finds the inner class. It fails when the script has no class that extends `GdlrModule`.

## Lifecycle

`GdlrModuleManager.mount()` compiles the graph. `GdlrModuleManager.start()` runs the lifecycle in this order:

1. Godular creates each module instance. It creates the imports of a module before the module.
2. Godular sets the injected properties of the module.
3. Godular calls `register()`. Keep `register()` synchronous.
4. After every module is registered, Godular resolves every `TREE_EXPORTS` token.
5. Godular calls `enable()` on each module in dependency order. It awaits each call. A module that imports another module runs `enable()` after that module returns from `enable()`.

Each `enable()` call must return within `GdlrModuleGraph.DEFAULT_MODULE_ENABLE_TIMEOUT_S` seconds. The value is 90. After that time Godular reports an error, stops the assertion in debug builds, and continues with the next module. The slow `enable()` keeps running.

```gdscript
func register() -> void:
	handlers.set_core(AddPointsCommand, AddPointsHandler.new().run)

func enable() -> void:
	await settings.load()
```

## Injection

Godular fills two kinds of properties before `register()` runs.

Typed properties whose type extends `GdlrCapability`:

```gdscript
var score: CapScore
```

Properties listed in a static `INJECT` array. Use it for tokens that are not capability classes:

```gdscript
static var INJECT = [{"token": &"api_url", "property": "api_url"}]
var api_url: String
```

Each `INJECT` entry must be a dictionary with a `token` key and a `property` key.

Godular resolves the token from the providers the module can see. It fails when no provider is visible.

### Plain objects

A module can copy its own dependencies into another object with `inject_dependencies()`. The object declares its needs in the same way: typed capability properties or a static `INJECT` array. Godular copies only tokens that the module also declares. It reports an error for each token it cannot match.

```gdscript
class_name ScoreView
extends RefCounted

var score: CapScore
```

```gdscript
func register() -> void:
	var view := ScoreView.new()
	inject_dependencies(view)
```

## Visibility

A module sees:

- the tokens in its own `PROVIDERS`, and
- the tokens in the `EXPORTS` of the modules it lists in `IMPORTS`.

Godular looks in the module's providers first. It then looks in each direct import. When an import exports a token that the import itself gets from one of its own imports, the lookup continues through that chain. A module can list an imported token in its own `EXPORTS`. Modules that import it then see the token.

Each module has one container. A token resolves once per container and Godular caches the value.

## Tree exports

`TREE_EXPORTS` lists tokens for code outside the module graph. Godular resolves every tree export during `start()`, before any `enable()` call. Any node can then read the value:

```gdscript
var score: CapScore = GdlrModuleManager.request(CapScore, self)
```

The second argument is optional. Godular only uses it to name the requester in error messages.

Only one module can tree-export a token. Godular reports an error when two modules declare the same tree export. The providing module must see a provider for the token. Otherwise Godular reports an error.

`request()` fails before `start()` completes. Tree exports are not resolved before that point.

## Dynamic configuration

A {ref}`GdlrModuleDefinition <class_GdlrModuleDefinition>` configures a module at runtime. Set `ModuleScript` and chain `imports()`, `providers()`, `exports()`, and `tree_exports()`. A common form is a static `for_root()` function on the module:

```gdscript
extends GdlrModule

static var PROVIDERS = {
	&"setting": {"use": "static"},
}
static var TREE_EXPORTS = [&"setting"]

static func for_root(value: String) -> GdlrModuleDefinition:
	var definition := GdlrModuleDefinition.new()
	definition.ModuleScript = load("res://path/to/this_module.gd")
	definition.providers({
		&"setting": {"use": value},
	})
	return definition
```

Pass the definition to `GdlrModuleManager.mount()` or list it in the `IMPORTS` of another module. `IMPORTS` entries can also be a `GdPromise` that resolves to a module script or a definition.

Godular merges the static members of the script with the definition. Providers in the definition replace static providers with the same token. In the example, `request(&"setting")` returns the value passed to `for_root()`.
