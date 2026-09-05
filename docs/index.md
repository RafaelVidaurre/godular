# Godular

Godular helps you organize a Godot game into modules and connect their services.
A module declares what it needs, what it provides, and what it shares with other modules.

Godular supplies the dependencies and starts modules in dependency order.
Each provider is created once in its module and shared with its consumers.
Godular waits for factories and module startup to finish before it starts dependent work.

## Start a module

1. Install the addon and enable the plugin. See [Getting started](guide/getting-started.md).
2. Declare a capability, a service, and a module.

```gdscript
# game_module.gd
class_name GameModule
extends GdlrModule

static var PROVIDERS = {
	CapScore: {"use": SvcScore},
}
static var TREE_EXPORTS = [CapScore]
```

3. Mount and start the root module once.

```gdscript
await GdlrModuleManager.mount(GameModule)
await GdlrModuleManager.start()
```

4. Request a tree export from any node.

```gdscript
var score: CapScore = GdlrModuleManager.request(CapScore)
```

## Guides

- [Getting started](guide/getting-started.md)
- [Modules](guide/modules.md)
- [Dependency injection](guide/dependency-injection.md)
- [Middleware](guide/middleware.md)
- [Command bus](guide/command-bus.md)
- [Jobs](guide/jobs.md)
- [Promises](guide/promises.md)
- [Editor](guide/editor.md)

## Reference

- [API reference](api/index.md)

## AI disclosure

Code, documentation, and the project icon were produced with AI assistance under human review.

```{toctree}
:hidden:
:maxdepth: 2

guide/getting-started
guide/modules
guide/dependency-injection
guide/middleware
guide/command-bus
guide/jobs
guide/promises
guide/editor
api/index
contributing
```
