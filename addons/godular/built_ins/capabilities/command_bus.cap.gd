@abstract class_name CapGdlrCommandBus
extends GdlrCapability
## Capability that dispatches commands.
##
## A command is a serializable request. The bus wraps it in a
## [CapGdlrCommandBus.CommandEnvelope], runs the envelope through the bus
## middleware, and then executes it according to
## [member CapGdlrCommandBus.CommandRoute.exec_kind]: local handlers from
## [CapGdlrCommandHandlers], a remote [CapGdlrCommandTransport], or both.
## [br][br]
## Godular ships a service for this capability at
## [code]res://addons/godular/built_ins/services/command_bus.svc.gd[/code].
## It needs a [CapGdlrCommandHandlers] and a [CapGdlrCommandTransport]:
## [codeblock]
## const SvcCommandBus = preload("res://addons/godular/built_ins/services/command_bus.svc.gd")
## const SvcCommandHandlers = preload("res://addons/godular/built_ins/services/command_handlers.svc.gd")
##
## static var PROVIDERS = {
##     CapGdlrCommandHandlers: {"use": SvcCommandHandlers},
##     CapGdlrCommandTransport: {"use": MyTransport},
##     CapGdlrCommandBus: {
##         "use": SvcCommandBus,
##         "inject": [CapGdlrCommandHandlers, CapGdlrCommandTransport],
##     },
## }
## [/codeblock]
##
## @tutorial(Command bus): https://rafaelvidaurre.github.io/godular/guide/command-bus.html


## Outcome of a command.
enum CommandStatus {
	## The command was not accepted. [member CapGdlrCommandBus.CommandResult.reason]
	## explains why.
	NACK,
	## The command was accepted.
	ACK,
	## The command timed out.
	TIMEOUT,
}

## Where a command runs.
enum ExecKind {
	## No route. The bus rejects the command.
	NONE = -1,
	## Local handlers only.
	LOCAL,
	## The remote transport only.
	REMOTE,
	## Local handlers first, then the remote transport. The remote result is
	## returned.
	DUAL_LOCAL_FIRST,
	## The remote transport first, then local handlers. The remote result is
	## returned.
	DUAL_REMOTE_FIRST,
}


## Adds bus middleware. [param middleware] receives the next step of the
## chain and returns a callable that takes an envelope and returns a
## [CapGdlrCommandBus.CommandResult]:
## [codeblock]
## bus.use(func(next: Callable) -> Callable:
##     return func(envelope: CapGdlrCommandBus.CommandEnvelope):
##         print("dispatching ", envelope.command)
##         return await next.call(envelope)
## )
## [/codeblock]
## The first middleware added is the outer layer.
@abstract func use(middleware: Callable) -> void
## Removes every bus middleware.
@abstract func clear_middleware() -> void
## Dispatches a command and returns its result. [param command_or_envelope]
## is a [CapGdlrCommandBus.Command] or a [CapGdlrCommandBus.CommandEnvelope].
## For a command, the bus creates a [CapGdlrCommandBus.CommandMeta] and sets
## each key of [param meta_params] on it. The envelope must have a
## [member CapGdlrCommandBus.CommandMeta.route].
@abstract func dispatch(command_or_envelope: Variant, meta_params := {}) -> CommandResult


## A command together with its metadata.
class CommandEnvelope extends RefCounted:
	## Identifiers, routing, and timing of the command.
	var meta: CommandMeta
	## The command to run.
	var command: Command


	## Creates an envelope for [param command_].
	func _init(command_: Command, meta_: CommandMeta = CommandMeta.new()) -> void:
		meta = meta_
		command = command_


	## Serializes the envelope. See [method from_dict].
	func to_dict() -> Dictionary:
		return {
			"meta": meta.to_dict() if meta else null,
			"command": command.to_dict() if command else null,
		}


	## Restores an envelope from the output of [method to_dict].
	static func from_dict(serialized: Dictionary) -> CommandEnvelope:
		return CommandEnvelope.new(
			Command.deserialize(serialized.command),
			CommandMeta.from_dict(serialized.meta),
		)


## Metadata of one command dispatch.
class CommandMeta extends RefCounted:
	## Unique identifier of the dispatch.
	var id: StringName
	## Identifier shared by every command of one workflow.
	var correlation_id: StringName
	## Identifier of the command that caused this one.
	var causation_id: StringName
	## Key that lets a receiver ignore a repeated dispatch.
	var idempotency_key: StringName
	## Timeout in seconds. Godular does not enforce it. Transports can.
	var timeout: float
	## Free-form data about who dispatched the command.
	var actor: Dictionary
	## Where the command runs. Required by the bundled bus.
	var route: CommandRoute


	## Serializes the metadata. See [method from_dict].
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"correlation_id": correlation_id,
			"causation_id": causation_id,
			"idempotency_key": idempotency_key,
			"timeout": timeout,
			"actor": actor,
			"route": route.to_dict() if route else null,
		}


	## Restores metadata from the output of [method to_dict]. Only
	## [member id] is required.
	static func from_dict(serialized: Dictionary) -> CommandMeta:
		var meta := CommandMeta.new()
		meta.id = serialized.id
		if serialized.has("correlation_id"):
			meta.correlation_id = serialized.correlation_id
		if serialized.has("causation_id"):
			meta.causation_id = serialized.causation_id
		if serialized.has("idempotency_key"):
			meta.idempotency_key = serialized.idempotency_key
		if serialized.has("timeout"):
			meta.timeout = serialized.timeout
		if serialized.has("actor"):
			meta.actor = serialized.actor
		if serialized.has("route"):
			meta.route = CommandRoute.from_dict(serialized.route)
		return meta


## Where and how a command runs.
class CommandRoute extends RefCounted:
	## Name of the transport adapter for remote execution. See
	## [method CapGdlrCommandTransport.get_adapter].
	var target: StringName
	## Local, remote, or both.
	var exec_kind: ExecKind
	## Free-form options for the transport. [GdlrCommandTransportAdapter]
	## reads the [code]retry_after_extractor[/code] key.
	var route_config: Dictionary


	## Creates a route.
	func _init(exec_kind_: ExecKind, target_ := "", route_config_ := {}) -> void:
		exec_kind = exec_kind_
		target = target_
		route_config = route_config_


	## Serializes the route. See [method from_dict].
	func to_dict() -> Dictionary:
		return {
			"target": target,
			"exec_kind": exec_kind,
			"route_config": route_config,
		}


	## Restores a route from the output of [method to_dict].
	static func from_dict(serialized: Dictionary) -> CommandRoute:
		return CommandRoute.new(
			serialized.exec_kind,
			serialized.target,
			serialized.route_config,
		)


## Base class for commands.
##
## Subclass it in its own script file, not in an inner class, so that
## [method deserialize] can load it by path. Implement [method _to_dict]
## with the command inputs:
## [codeblock]
## class_name AddPointsCommand
## extends CapGdlrCommandBus.Command
##
## var amount := 0
##
## func _to_dict() -> Dictionary:
##     return {"amount": amount}
## [/codeblock]
## Optional members that Godular reads from a command class:[br]
## - [code]static func from_dict(inputs: Dictionary) -> Command[/code]:
## custom restore. Without it, [method deserialize] creates the command and
## sets each input as a property.[br]
## - An inner class [code]Payload[/code] with
## [code]static func from_dict(data: Dictionary)[/code]: typed result
## payload for [method CapGdlrCommandBus.CommandResult.from_dict].
@abstract class Command extends RefCounted:
	## Returns the inputs of the command as a dictionary.
	@abstract func _to_dict() -> Dictionary


	func _to_string() -> String:
		return "<Command: %s>" % _get_display_name()


	## Returns the name used in log output. Override it.
	func _get_display_name() -> String:
		return "Unnamed"


	## Serializes the command with its script path and its inputs. See
	## [method deserialize].
	func to_dict() -> Dictionary:
		return {
			"resource_path": get_script().resource_path,
			"inputs": _to_dict()
		}


	## Restores a command from the output of [method to_dict]. The method
	## loads the command script, then uses its static [code]from_dict[/code]
	## when the class defines one.
	static func deserialize(serialized: Dictionary) -> Command:
		assert(serialized.has("resource_path"), "Command serialized dictionary must have a resource_path key")
		assert(serialized.has("inputs"), "Command serialized dictionary must have an inputs key")
		var CommandClass: GDScript = load(serialized.resource_path)
		var inputs: Dictionary = serialized.inputs

		if "from_dict" in CommandClass:
			return CommandClass.from_dict(inputs)

		var command: Command = CommandClass.new()

		for key in inputs:
			command.set(key, inputs[key])

		return command


## Result of a command dispatch.
class CommandResult extends RefCounted:
	## [member reason] of results created by [method rate_limited].
	const RATE_LIMITED_REASON := "RATE_LIMITED"
	## [member retry_after_source] when no retry time is known.
	const RETRY_AFTER_SOURCE_NONE := &""
	## [member retry_after_source] when a rate limit set the retry time.
	const RETRY_AFTER_SOURCE_RATE_LIMIT := &"rate_limit"

	## True when the command succeeded.
	var ok: bool
	## Outcome of the command.
	var status: CommandStatus
	## Explanation of a failure. Empty on success.
	var reason: String
	## Data returned by the handler or the remote target. For local
	## execution the bundled bus stores the output of
	## [method CapGdlrCommandHandlers.LocalOutput.to_dict].
	var payload: Variant
	## Free-form data about the result.
	var metadata: Dictionary
	## Seconds to wait before a retry. Negative when unknown.
	var retry_after_s := -1.0
	## Who set [member retry_after_s]: [constant RETRY_AFTER_SOURCE_NONE],
	## [constant RETRY_AFTER_SOURCE_RATE_LIMIT], or a transport-specific name
	## such as [code]&"payload"[/code].
	var retry_after_source := RETRY_AFTER_SOURCE_NONE
	## Rate-limit details. [code]null[/code] unless the command was rate
	## limited.
	var rate_limit: RateLimitInfo


	## Creates a result. [param metadata_] is copied.
	func _init(
		ok_: bool,
		status_: CommandStatus,
		reason_: String,
		payload_: Variant,
		metadata_: Dictionary = {},
		rate_limit_: RateLimitInfo = null,
		retry_after_s_ := -1.0,
		retry_after_source_ := RETRY_AFTER_SOURCE_NONE
	) -> void:
		ok = ok_
		status = status_
		reason = reason_
		payload = payload_
		metadata = metadata_.duplicate(true)
		rate_limit = rate_limit_
		retry_after_s = retry_after_s_
		retry_after_source = retry_after_source_


	## Creates the standard result for a rate-limited attempt: a
	## [constant CapGdlrCommandBus.NACK] with [constant RATE_LIMITED_REASON],
	## the payload [code]{"message": message}[/code], and rate-limit details.
	static func rate_limited(
		retry_after_s := -1.0,
		policy_id := &"",
		message := RATE_LIMITED_REASON
	) -> CommandResult:
		return CommandResult.new(
			false,
			CommandStatus.NACK,
			RATE_LIMITED_REASON,
			{"message": message},
			{},
			RateLimitInfo.new(true, policy_id),
			retry_after_s,
			RETRY_AFTER_SOURCE_RATE_LIMIT
		)


	## Returns true when a rate limit produced this result.
	func is_rate_limited() -> bool:
		return rate_limit != null and rate_limit.limited


	## Returns [member retry_after_s], or [param default_value] when the
	## retry time is not positive.
	func get_retry_after_s(default_value := -1.0) -> float:
		if retry_after_s <= 0.0:
			return default_value
		return retry_after_s


	## Sets the retry time and records [param source] as its origin.
	func set_retry_after_s(value: float, source: StringName) -> void:
		retry_after_s = value
		retry_after_source = source


	## Calls [param extractor] with the payload as a dictionary. When it
	## returns a positive number, the method stores it as the retry time with
	## the source [code]&"payload"[/code]. An invalid callable is ignored.
	func apply_payload_retry_after_extractor(extractor: Callable) -> void:
		if not extractor.is_valid():
			return

		var retry_after_s_ := float(extractor.call(_payload_as_dict()))
		if retry_after_s_ > 0.0:
			set_retry_after_s(retry_after_s_, &"payload")


	## Returns [member rate_limit].
	func get_rate_limit_info() -> RateLimitInfo:
		return rate_limit


	func _to_string() -> String:
		if ok:
			return "CommandResult(%s)" % CommandStatus.keys()[status]
		return "CommandResult(%s)[Reason: %s]" % [CommandStatus.keys()[status], reason]


	## Serializes the result. An object payload must have a
	## [code skip-lint]to_dict()[/code] method. See [method from_dict].
	func to_dict() -> Dictionary:
		var serialized_payload: Variant = null
		if payload is Object:
			if not payload.has_method("to_dict"):
				assert(false, "Payload must have a to_dict method")
			serialized_payload = payload.to_dict()
		else:
			serialized_payload = payload

		return {
			"ok": ok,
			"status": status,
			"reason": reason,
			"payload": serialized_payload,
			"metadata": metadata,
			"rate_limit": rate_limit.to_dict() if rate_limit else null,
			"retry_after_s": retry_after_s,
			"retry_after_source": retry_after_source,
		}


	## Restores a result from the output of [method to_dict]. When
	## [param CommandClass] is given and the result is ok, the payload is
	## restored with the [code]Payload.from_dict[/code] of that class. See
	## [CapGdlrCommandBus.Command].
	static func from_dict(serialized: Dictionary, CommandClass: GDScript = null) -> CommandResult:
		var payload: Variant = null

		if serialized.get("ok"):
			if CommandClass:
				if "Payload" in CommandClass:
					if serialized.get("payload") != null:
						payload = CommandClass.Payload.from_dict(serialized.get("payload", {}))
				else:
					assert(false, "CommandClass must have a Payload class to be used in CommandResult.from_dict")
			else:
				payload = serialized.get("payload")
		else:
			payload = serialized.get("payload")

		return CommandResult.new(
			serialized.ok,
			serialized.status,
			serialized.get("reason", ""),
			payload,
			serialized.get("metadata", {}),
			RateLimitInfo.from_dict(serialized.rate_limit) if serialized.get("rate_limit") != null else null,
			serialized.get("retry_after_s", -1.0),
			serialized.get("retry_after_source", RETRY_AFTER_SOURCE_NONE),
		)


	func _payload_as_dict() -> Dictionary:
		if payload is Dictionary:
			return payload
		if payload is Object:
			if not payload.has_method("to_dict"):
				assert(false, "Payload must have a to_dict method")
			return payload.to_dict()
		return {}


## Rate-limit details of a [CapGdlrCommandBus.CommandResult].
class RateLimitInfo extends RefCounted:
	## True when a rate limit rejected the command.
	var limited: bool
	## Identifier of the policy that limited the command.
	var policy_id: StringName


	## Creates rate-limit details.
	func _init(limited_ := false, policy_id_ := &"") -> void:
		limited = limited_
		policy_id = policy_id_


	## Serializes the details. See [method from_dict].
	func to_dict() -> Dictionary:
		return {
			"limited": limited,
			"policy_id": policy_id,
		}


	## Restores details from the output of [method to_dict].
	static func from_dict(serialized: Dictionary) -> RateLimitInfo:
		return RateLimitInfo.new(
			serialized.get("limited", false),
			serialized.get("policy_id", &"")
		)
