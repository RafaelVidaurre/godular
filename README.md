# Godular

Modular architecture for Godot. Godular lets you split a game into modules that declare what they provide and what they depend on, and it wires everything together for you.

If your project has reached the point where autoloads reach into other autoloads and nobody remembers what has to initialize first, that is the problem Godular solves. You describe each part of your game as a module with imports, providers, and exports. Godular compiles them into a graph, builds every service exactly once, injects it wherever it is needed, and enables modules in dependency order, waiting for async work along the way.

Documentation: <https://rafaelvidaurre.github.io/godular/>

## Install

Godular needs Godot 4.5 or later. CI runs the test suite on 4.5, 4.6, and 4.7.

From the Godot Asset Library:

1. In the Godot editor, open the AssetLib tab and search for "Godular".
2. Download and install it into your project.
3. Enable "Godular" under Project Settings, then Plugins.

From GitHub:

1. Download a [release](https://github.com/RafaelVidaurre/godular/releases) zip, or the repository as a zip.
2. Copy the `addons` folder into your project.
3. Enable "Godular" under Project Settings, then Plugins.

Both packages contain `addons/godular` and `addons/gd_promise`. [GdPromise](https://github.com/RafaelVidaurre/gd-better-promises) is the promise library that Godular uses. It ships with the plugin.

Enabling the plugin adds the `GdlrModuleManager` autoload, which is how you mount and start your modules.

## Your first module

A capability is the contract, a service implements it, and a module tells Godular how to build and share it:

```gdscript
# cap_score.gd
@abstract class_name CapScore
extends GdlrCapability

@abstract func add_points(amount: int) -> void
```

```gdscript
# svc_score.gd
class_name SvcScore
extends CapScore

var total := 0

func add_points(amount: int) -> void:
	total += amount
```

```gdscript
# game_module.gd
class_name GameModule
extends GdlrModule

static var PROVIDERS = {
	CapScore: {"use": SvcScore},
}
static var EXPORTS = [CapScore]
static var TREE_EXPORTS = [CapScore]

# Typed properties matching a provided capability are injected automatically.
var score: CapScore

func enable() -> void:
	score.add_points(10)
```

Mount the root module once, then request tree exports from anywhere in the scene tree:

```gdscript
# main.gd
extends Node

func _ready() -> void:
	await GdlrModuleManager.mount(GameModule)
	await GdlrModuleManager.start()
	var score: CapScore = GdlrModuleManager.request(CapScore)
	print(score.total)
```

Modules compose through `IMPORTS`: a module can import other modules and consume anything they export. Godular registers and enables dependencies before dependants. It enables modules one at a time, and waits for each `enable()` before it calls the next one.

## What's in the box

- Module graph: declarative `IMPORTS`, `PROVIDERS`, `EXPORTS`, and `TREE_EXPORTS`, compiled and started in dependency order.
- Dependency injection: a container that builds each provider once, resolves factory arguments, supports async factories, and injects typed properties on modules and plain objects.
- Middleware pipelines: wrap any callable with before, after, and around callbacks, with priorities and core overrides.
- Command bus: dispatch commands locally or through a transport you provide, with handlers, per-command and global middleware, serializable envelopes, and rate limit metadata.
- Jobs: declare units of work with requirements, run policies, and reset semantics, driven by promises.
- GdPromise: a small promise library for GDScript (`all`, `race`, `await_resolved`, and more), shipped as its own addon.
- Editor support: point `godular/editor_root_module_path` at a module and Godular runs a module graph inside the editor too, for building editor tooling.

## Documentation

The [documentation site](https://rafaelvidaurre.github.io/godular/) has guides for each feature and the API reference. The reference is generated from the doc comments in the source, so the same text shows up in the editor's built-in help (F1).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to report bugs, set up a clone, run the tests, and open a pull request. Maintainers release the addon as described in [RELEASING.md](RELEASING.md).

## License

[MIT](LICENSE)
