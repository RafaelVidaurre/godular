# API reference

Generated from GDScript doc comments with `tools/generate_docs.sh`.
Do not edit these files by hand.

## Godular

- [CapGdlrCommandBus](CapGdlrCommandBus.md) — Capability that dispatches commands and defines the command data types.
  - [CapGdlrCommandBus.Command](CapGdlrCommandBus.Command.md)
  - [CapGdlrCommandBus.CommandEnvelope](CapGdlrCommandBus.CommandEnvelope.md)
  - [CapGdlrCommandBus.CommandMeta](CapGdlrCommandBus.CommandMeta.md)
  - [CapGdlrCommandBus.CommandResult](CapGdlrCommandBus.CommandResult.md)
  - [CapGdlrCommandBus.CommandRoute](CapGdlrCommandBus.CommandRoute.md)
  - [CapGdlrCommandBus.RateLimitInfo](CapGdlrCommandBus.RateLimitInfo.md)
- [CapGdlrCommandHandlers](CapGdlrCommandHandlers.md) — Capability that registers and runs local command handlers.
  - [CapGdlrCommandHandlers.Context](CapGdlrCommandHandlers.Context.md)
  - [CapGdlrCommandHandlers.LocalOutput](CapGdlrCommandHandlers.LocalOutput.md) — Local handler output carried through command middleware and serialization.
- [CapGdlrCommandRouter](CapGdlrCommandRouter.md) — Capability that plans the route for a command envelope.
- [CapGdlrCommandTransport](CapGdlrCommandTransport.md) — Capability that sends commands through registered transport adapters.
- [CapGdlrJobs](CapGdlrJobs.md) — Capability that starts jobs and tracks their progress.
  - [CapGdlrJobs.Job](CapGdlrJobs.Job.md)
  - [CapGdlrJobs.JobSpec](CapGdlrJobs.JobSpec.md)
- [CapGdlrJobsRegistry](CapGdlrJobsRegistry.md) — Capability that stores job specifications by key.
- [GdlrCapability](GdlrCapability.md) — Base class for capability contracts that modules provide and consume.
- [GdlrCommandHandler](GdlrCommandHandler.md) — Base class for command handlers registered with the command bus.
- [GdlrCommandMiddleware](GdlrCommandMiddleware.md) — Base class for command-bus middleware.
- [GdlrCommandPipeline](GdlrCommandPipeline.md) — Runs a command through prioritized before, around, after, and core-override callbacks.
  - [GdlrCommandPipeline.PipelineEntry](GdlrCommandPipeline.PipelineEntry.md) — One registered pipeline callback with its ordering data.
- [GdlrCommandTransportAdapter](GdlrCommandTransportAdapter.md) — Base class for command transports. Override `_send` and `_enable`.
- [GdlrDiContainer](GdlrDiContainer.md) — Resolves singleton providers and caches their values by token.
  - [GdlrDiContainer.ProviderFactory](GdlrDiContainer.ProviderFactory.md) — Resolves one provider definition together with its dependencies.
- [GdlrMiddlewarePipeline](GdlrMiddlewarePipeline.md) — Runs prioritized before, around, after, and conditional core-override callbacks.
  - [GdlrMiddlewarePipeline.PipelineEntry](GdlrMiddlewarePipeline.PipelineEntry.md) — One registered pipeline callback with its ordering data.
- [GdlrModule](GdlrModule.md) — Base class for modules. Declare `IMPORTS`, `EXPORTS`, `PROVIDERS`, and `TREE_EXPORTS` constants on subclasses.
- [GdlrModuleDefinition](GdlrModuleDefinition.md) — Builds a module configuration with chained `imports`, `exports`, `providers`, and `tree_exports` calls.
- [GdlrModuleGraph](GdlrModuleGraph.md) — Compiles a tree of module definitions and runs its lifecycle.
  - [GdlrModuleGraph.DebugPlugin](GdlrModuleGraph.DebugPlugin.md) — Base class for module-graph debug views.
- [GdlrModuleManager](GdlrModuleManager.md) — Autoload singleton that mounts, starts, and queries the module graph.
- [GdlrModuleProvider](GdlrModuleProvider.md) — Describes how a module creates the value for one token.

## GdPromise

- [GdPromise](GdPromise.md) — Promise for GDScript with `then`, `catch`, and awaitable settlement.
