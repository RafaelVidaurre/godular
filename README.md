# Godular

Godular helps you organize a Godot game into modules and connect their services.
Each module declares what it needs, what it provides, and what it shares.
Godular supplies those dependencies and starts modules in dependency order.

For example, a score module can provide a service that both gameplay and the UI use.
Godular creates that provider once in its module and shares the instance with its consumers.
If a service needs to load data or a module needs time to start, Godular waits for it.

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

Both packages contain `addons/godular` and `addons/gdb_promise`. [GdbPromise](https://github.com/RafaelVidaurre/gd-better-promises) is the promise library that Godular uses. It ships with the plugin.

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

## Features

- Declare module dependencies with `IMPORTS`, `PROVIDERS`, `EXPORTS`, and `TREE_EXPORTS`.
- Create services with dependency injection, including factories that return promises.
- Add middleware before, after, or around a callable.
- Dispatch commands to local handlers or through a transport you provide.
- Run jobs with dependencies, manual start options, and resets.
- Run a module graph inside the editor to support your own tools.

## Documentation

The [documentation site](https://rafaelvidaurre.github.io/godular/) has guides for each feature and the API reference. The reference is generated from the doc comments in the source, so the same text shows up in the editor's built-in help (F1).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to report bugs, set up a clone, run the tests, and open a pull request. Maintainers release the addon as described in [RELEASING.md](RELEASING.md).

## AI disclosure

Code, documentation, and the project icon were produced with AI assistance under human review.

## License

[MIT](LICENSE)
