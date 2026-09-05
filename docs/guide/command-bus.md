# Command bus

Use the command bus to send requests to local handlers or a remote service.
Each command holds the request data. An envelope adds metadata such as an identifier and a route.
The bus passes the envelope through middleware, then runs the command where its route specifies.

Godular ships these parts:

| Part | Kind | Bundled service |
| --- | --- | --- |
| {ref}`CapGdlrCommandBus <class_CapGdlrCommandBus>` | Capability | `res://addons/godular/built_ins/services/command_bus.svc.gd` |
| {ref}`CapGdlrCommandHandlers <class_CapGdlrCommandHandlers>` | Capability | `res://addons/godular/built_ins/services/command_handlers.svc.gd` |
| {ref}`CapGdlrCommandTransport <class_CapGdlrCommandTransport>` | Capability | None. Implement it in your project. |
| {ref}`CapGdlrCommandRouter <class_CapGdlrCommandRouter>` | Capability | None. The bundled bus does not call it. |
| {ref}`GdlrCommandHandler <class_GdlrCommandHandler>` | Base class | |
| {ref}`GdlrCommandMiddleware <class_GdlrCommandMiddleware>` | Base class | |
| {ref}`GdlrCommandTransportAdapter <class_GdlrCommandTransportAdapter>` | Base class | |

## Connect the services

Provide the handlers service, a transport of your own, and the bus:

```gdscript
class_name CommandsModule
extends GdlrModule

const SvcCommandBus = preload("res://addons/godular/built_ins/services/command_bus.svc.gd")
const SvcCommandHandlers = preload("res://addons/godular/built_ins/services/command_handlers.svc.gd")

static var PROVIDERS = {
	CapGdlrCommandHandlers: {"use": SvcCommandHandlers},
	CapGdlrCommandTransport: {"use": MyTransport},
	CapGdlrCommandBus: {
		"use": SvcCommandBus,
		"inject": [CapGdlrCommandHandlers, CapGdlrCommandTransport],
	},
}
static var EXPORTS = [CapGdlrCommandBus, CapGdlrCommandHandlers]
static var TREE_EXPORTS = [CapGdlrCommandBus]
```

The bundled bus takes the handlers service and the transport in this order.

## Commands

A command extends `CapGdlrCommandBus.Command`. Put it in its own script file, not in an inner class, so that Godular can load it by path when it deserializes. Implement `_to_dict()` with the inputs of the command.

```gdscript
class_name AddPointsCommand
extends CapGdlrCommandBus.Command

var amount := 0

func _to_dict() -> Dictionary:
	return {"amount": amount}
```

`to_dict()` returns the script path and the inputs. `Command.deserialize()` loads the script and restores the command. It uses a static `from_dict(inputs)` when the class defines one. Otherwise it creates the command with `new()` and sets each input as a property.

A command class can define an inner class named `Payload` with a static `from_dict(data)`. `CommandResult.from_dict(serialized, CommandClass)` then restores the payload of a successful result with it.

Override `_get_display_name()` to name the command in log output.

## Envelopes

A `CommandEnvelope` holds a `command` and a `meta`. `CommandMeta` has these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | StringName | Identifier of the dispatch. Required by `CommandMeta.from_dict()`. |
| `correlation_id` | StringName | Identifier shared by the commands of one workflow. |
| `causation_id` | StringName | Identifier of the command that caused this one. |
| `idempotency_key` | StringName | Key that lets a receiver ignore a repeated dispatch. |
| `timeout` | float | Timeout in seconds. Godular does not enforce it. |
| `actor` | Dictionary | Data about who dispatched the command. |
| `route` | CommandRoute | Where the command runs. |

Godular does not fill any of these fields. Set them yourself.

A `CommandRoute` has `exec_kind`, `target`, and `route_config`. `target` names the transport adapter for remote execution. `route_config` holds options for the transport.

```gdscript
var command := AddPointsCommand.new()
command.amount = 10
var meta := CapGdlrCommandBus.CommandMeta.new()
meta.id = &"command-1"
meta.route = CapGdlrCommandBus.CommandRoute.new(CapGdlrCommandBus.ExecKind.LOCAL)
var envelope := CapGdlrCommandBus.CommandEnvelope.new(command, meta)
```

## Dispatch

`dispatch()` accepts an envelope or a command. For a command, the bus creates a `CommandMeta` and sets each key of `meta_params` on it:

```gdscript
var result := await bus.dispatch(command, {
	"id": &"command-1",
	"route": CapGdlrCommandBus.CommandRoute.new(CapGdlrCommandBus.ExecKind.LOCAL),
})
```

The envelope must have a route. The bundled bus reads `meta.route.exec_kind` and fails on a `null` route.

The bundled bus executes by `exec_kind`:

| `ExecKind` | Behaviour |
| --- | --- |
| `LOCAL` | Runs the local handlers. Returns `ACK` with the `LocalOutput` dictionary as payload. |
| `REMOTE` | Sends the envelope through the transport. Returns the remote result. |
| `DUAL_LOCAL_FIRST` | Runs the local handlers, then sends through the transport. Returns the remote result. |
| `DUAL_REMOTE_FIRST` | Sends through the transport, then runs the local handlers. Returns the remote result. |
| Any other value | Returns `NACK` with the reason `Invalid execution kind`. |

## Results

A `CommandResult` has these fields:

| Field | Meaning |
| --- | --- |
| `ok` | True when the command succeeded. |
| `status` | `ACK`, `NACK`, or `TIMEOUT`. |
| `reason` | Explanation of a failure. |
| `payload` | Data from the handler or the remote target. |
| `metadata` | Free-form data. The constructor copies it. |
| `retry_after_s` | Seconds to wait before a retry. Negative when unknown. |
| `retry_after_source` | Who set the retry time. |
| `rate_limit` | `RateLimitInfo`, or `null`. |

`CommandResult.rate_limited(retry_after_s, policy_id, message)` creates a `NACK` with the reason `RATE_LIMITED`, the payload `{"message": message}`, and rate-limit details. `is_rate_limited()` returns true for such a result. `get_retry_after_s(default_value)` returns the retry time, or the default when the time is not positive.

Results serialize with `to_dict()` and `from_dict()`. An object payload must have a `to_dict()` method.

## Handlers

A handler extends `GdlrCommandHandler` and implements `run(envelope, ctx)`. The bundled bus expects a `CapGdlrCommandHandlers.LocalOutput`:

```gdscript
class_name AddPointsHandler
extends GdlrCommandHandler

func run(envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant:
	var command: AddPointsCommand = envelope.command
	return CapGdlrCommandHandlers.LocalOutput.new([{"points": command.amount}], [])
```

`LocalOutput` has `state_dispatches` and `effects`, both arrays of dictionaries. Godular does not interpret them.

Register the handler as the core of the command pipeline:

```gdscript
var handlers: CapGdlrCommandHandlers

func register() -> void:
	handlers.set_core(AddPointsCommand, AddPointsHandler.new().run)
```

The handlers service keeps one {ref}`GdlrCommandPipeline <class_GdlrCommandPipeline>` per command class. `run()` fails when the pipeline of a command has no core.

The `Context` passed to a handler has two callables:

- `dispatch(envelope)` dispatches another envelope through the bus.
- `get_state()` returns `null` in the bundled bus. Replace it in a middleware or a custom bus.

## Command middleware

A `GdlrCommandMiddleware` groups callbacks for one command class. Implement any of `_before`, `_around`, and `_after`, and optionally `_should_run_before`, `_should_run_around`, and `_should_run_after`:

```gdscript
class_name LogMiddleware
extends GdlrCommandMiddleware

func _before(envelope: CapGdlrCommandBus.CommandEnvelope, _ctx: CapGdlrCommandHandlers.Context) -> void:
	print("dispatching ", envelope.command)

func _around(next: Callable, envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context) -> Variant:
	return await next.call(envelope, ctx)

func _after(_envelope: CapGdlrCommandBus.CommandEnvelope, _ctx: CapGdlrCommandHandlers.Context, result: Variant) -> Variant:
	return result
```

Only `_around` can `await`. Register it with `handlers.use(AddPointsCommand, LogMiddleware.new(), priority)`. The service reports an error when the middleware implements none of the callbacks.

`use_before()`, `use_around()`, and `use_after()` register single callables with priority `0`. `remove_by_callback(command, callback)` removes them.

`use_global_around(around, priority, should_run)` adds an around callback to the pipelines of every command, including commands registered later. `remove_global_by_callback(callback)` removes it from every pipeline.

The ordering rules are the same as in [Middleware](middleware.md).

## Bus middleware

Bus middleware wraps the whole dispatch. `bus.use(middleware)` takes a callable that receives the next step and returns a callable that takes an envelope:

```gdscript
bus.use(func(next: Callable) -> Callable:
	return func(envelope: CapGdlrCommandBus.CommandEnvelope):
		print("dispatching ", envelope.command)
		return await next.call(envelope)
)
```

The first middleware added is the outer layer. `clear_middleware()` removes all of them.

## Transports

`CapGdlrCommandTransport` sends envelopes to remote targets. It keeps one adapter per target name. Godular does not ship a service for it. Implement `send()`, `register_adapter()`, and `get_adapter()`.

A `GdlrCommandTransportAdapter` is a `Node`. Override `_enable()` and `_send()`:

```gdscript
class_name HttpAdapter
extends GdlrCommandTransportAdapter

func _enable() -> void:
	pass

func _send(envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult:
	var response := await post(envelope.to_dict())
	return CapGdlrCommandBus.CommandResult.from_dict(response)
```

`enable()` runs `_enable()`, sets `enabled`, and emits `transport_enabled`. `send()` waits for that signal when the adapter is not enabled yet.

When `route_config` has a `retry_after_extractor` callable, `send()` calls it with the payload as a dictionary. A positive return value becomes `retry_after_s` with the source `&"payload"`:

```gdscript
envelope.meta.route.route_config = {
	"retry_after_extractor": func(payload: Dictionary): return payload.get("wait", -1.0),
}
```

## Router

`CapGdlrCommandRouter.plan(envelope)` returns a `CommandRoute`. Godular ships no service for it, and the bundled bus does not call it. Provide a router when you decide routes in one place, and set the result on `meta.route` before you dispatch.

## Serialization

Envelopes, metadata, routes, results, rate-limit details, and local outputs all have `to_dict()` and a static `from_dict()`. A round trip restores the command class and the route:

```gdscript
var decoded := CapGdlrCommandBus.CommandEnvelope.from_dict(envelope.to_dict())
```
