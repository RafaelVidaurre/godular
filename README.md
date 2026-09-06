# Godular

_Modular architecture framework for Godot. Godular allows you to split your game (or app) into modules, leveraging dependency injection (DI) to manage complex projects and their lifecycles._

Godular establishes a way of structuring code into modules, explicitly declaring what each module provides and what it depends on.
This has several benefits:
1. It makes code dependencies explicit, if something's missing, the game will fail immediately, not deep within a gameplay session.
2. It promotes decoupling, making your code easier to maintain and reuse. Your game runs on mobile and desktop? Mount a different UI module depending on the platform.
3. Testing is easier. Dependencies expect specific contracts (Capabilities), this alongside DI makes testing much easier. You can simply mount mock modules where you need them, allowing easier to maintain test suites and less side effects obscuring your test failures.

## Important
Keep in mind that Godular is still in early development, although it has been extensively used in my company, in a very complex repository, one project is still just one project. 
There are still some rough edges here and there, and there's definitely a lot more that can be done to make Godular even more useful.

## Features

- Dependency injection for services and factories.
- Middleware that runs before, after, or around a callable.
- A command bus for local handlers and transports you provide.
- Jobs with dependencies, manual start options, and resets.

## Install

Godular needs Godot 4.5 or later.

1. Install the complete `addons` folder from your download. Keep both bundled add-on folders.
2. Enable **Godular** under **Project Settings**, then **Plugins**.
3. Follow the [getting started guide](https://rafaelvidaurre.github.io/godular/guide/getting-started.html) to create your first module.

## AI disclosure

Code, documentation, and the project icon were produced with AI assistance under human review.


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
