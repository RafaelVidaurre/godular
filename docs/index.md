# Godular

Godular splits a Godot game into modules. Each module declares what it imports, what it provides, and what it exports. Godular compiles the modules into a graph, builds each service once, injects it where it is needed, and enables the modules in dependency order. It waits for asynchronous work along the way.

## In four steps

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
