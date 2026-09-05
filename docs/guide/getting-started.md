# Getting started

## Install

Godular needs Godot 4.5 or later.

From the Asset Library:

1. Open the AssetLib tab in the Godot editor and search for "Godular".
2. Download and install it into your project.
3. Enable "Godular" under Project Settings, then Plugins.

From GitHub:

1. Download a [release](https://github.com/RafaelVidaurre/godular/releases) zip, or the repository as a zip.
2. Copy the `addons` folder into your project.
3. Enable "Godular" under Project Settings, then Plugins.

Both packages contain `addons/godular` and `addons/gdb_promise`. Godular uses the {ref}`GdbPromise <class_GdbPromise>` library for asynchronous work. It is developed in the [gd-better-promises](https://github.com/RafaelVidaurre/gd-better-promises) repository and bundled here. Keep both folders.

Version 0.2.0 uses `GdbPromise` in `addons/gdb_promise`. When upgrading from 0.1.0, remove the old `addons/gd_promise` folder and replace `GdPromise` with `GdbPromise` in your scripts. The Store may still provide 0.1.0 while the new version awaits submission or review. Use the [GitHub releases](https://github.com/RafaelVidaurre/godular/releases) for version 0.2.0.

When you enable the plugin, it adds the `GdlrModuleManager` autoload. This autoload mounts and starts your modules.

## Your first module

A capability names a contract. A service implements it. A module tells Godular how to build the service and who can use it.

The capability is an abstract class:

```gdscript
# cap_score.gd
@abstract class_name CapScore
extends GdlrCapability

@abstract func add_points(amount: int) -> void
```

The service extends the capability:

```gdscript
# svc_score.gd
class_name SvcScore
extends CapScore

var total := 0

func add_points(amount: int) -> void:
	total += amount
```

The module declares the provider and the exports:

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

Each declaration does one thing:

- `PROVIDERS` tells Godular to create one `SvcScore` for the `CapScore` token.
- `EXPORTS` lets modules that import `GameModule` use `CapScore`.
- `TREE_EXPORTS` lets any node get `CapScore` through `GdlrModuleManager.request()`.
- `var score: CapScore` receives the service before `register()` and `enable()` run.
- `enable()` runs after every imported module is enabled.

Mount the root module once, start it, and request the export:

```gdscript
# main.gd
extends Node

func _ready() -> void:
	await GdlrModuleManager.mount(GameModule)
	await GdlrModuleManager.start()
	var score: CapScore = GdlrModuleManager.request(CapScore)
	print(score.total)
```

This prints `10`. See {ref}`GdlrModuleManager <class_GdlrModuleManager>` for the autoload API and [Modules](modules.md) for the full module model.
