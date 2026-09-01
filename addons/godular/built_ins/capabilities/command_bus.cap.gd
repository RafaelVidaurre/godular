@abstract class_name CapGdlrCommandBus
extends GdlrCapability


enum CommandStatus {
	NACK,
	ACK,
	TIMEOUT,
}

enum ExecKind {
	NONE = -1,
	LOCAL,
	REMOTE,
	DUAL_LOCAL_FIRST,
	DUAL_REMOTE_FIRST,
}


@abstract func use(middleware: Callable) -> void
@abstract func clear_middleware() -> void
@abstract func dispatch(command_or_envelope: Variant, meta_params := {}) -> CommandResult


class CommandEnvelope extends RefCounted:
	var meta: CommandMeta
	var command: Command


	func _init(command_: Command, meta_: CommandMeta = CommandMeta.new()) -> void:
		meta = meta_
		command = command_


	func to_dict() -> Dictionary:
		return {
			"meta": meta.to_dict() if meta else null,
			"command": command.to_dict() if command else null,
		}


	static func from_dict(serialized: Dictionary) -> CommandEnvelope:
		return CommandEnvelope.new(
			Command.deserialize(serialized.command),
			CommandMeta.from_dict(serialized.meta),
		)


class CommandMeta extends RefCounted:
	var id: StringName
	var correlation_id: StringName
	var causation_id: StringName
	var idempotency_key: StringName
	var timeout: float
	var actor: Dictionary
	var route: CommandRoute


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


class CommandRoute extends RefCounted:
	var target: StringName
	var exec_kind: ExecKind
	var route_config: Dictionary


	func _init(exec_kind_: ExecKind, target_ := "", route_config_ := {}) -> void:
		exec_kind = exec_kind_
		target = target_
		route_config = route_config_


	func to_dict() -> Dictionary:
		return {
			"target": target,
			"exec_kind": exec_kind,
			"route_config": route_config,
		}


	static func from_dict(serialized: Dictionary) -> CommandRoute:
		return CommandRoute.new(
			serialized.exec_kind,
			serialized.target,
			serialized.route_config,
		)


@abstract class Command extends RefCounted:
	@abstract func _to_dict() -> Dictionary


	func _to_string() -> String:
		return "<Command: %s>" % _get_display_name()


	func _get_display_name() -> String:
		return "Unnamed"


	func to_dict() -> Dictionary:
		return {
			"resource_path": get_script().resource_path,
			"inputs": _to_dict()
		}


	## Named differently from subclass factories to avoid recursive dispatch.
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


class CommandResult extends RefCounted:
	const RATE_LIMITED_REASON := "RATE_LIMITED"
	const RETRY_AFTER_SOURCE_NONE := &""
	const RETRY_AFTER_SOURCE_RATE_LIMIT := &"rate_limit"

	var ok: bool
	var status: CommandStatus
	var reason: String
	var payload: Variant
	var metadata: Dictionary
	var retry_after_s := -1.0
	var retry_after_source := RETRY_AFTER_SOURCE_NONE
	## Optional rate-limit details for NACK results created by command-level rate limiting.
	var rate_limit: RateLimitInfo


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


	## Builds the standard command result for a rate-limited command attempt.
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


	## Returns true when this result was produced by command rate limiting.
	func is_rate_limited() -> bool:
		return rate_limit != null and rate_limit.limited


	## Returns the normalized retry-after value for this command result.
	func get_retry_after_s(default_value := -1.0) -> float:
		if retry_after_s <= 0.0:
			return default_value
		return retry_after_s


	## Sets retry guidance after command or transport-specific parsing has normalized it.
	func set_retry_after_s(value: float, source: StringName) -> void:
		retry_after_s = value
		retry_after_source = source


	## Applies route-provided retry parsing to this result's decoded payload.
	func apply_payload_retry_after_extractor(extractor: Callable) -> void:
		if not extractor.is_valid():
			return

		var retry_after_s_ := float(extractor.call(_payload_as_dict()))
		if retry_after_s_ > 0.0:
			set_retry_after_s(retry_after_s_, &"payload")


	## Returns typed rate-limit details, if this result has them.
	func get_rate_limit_info() -> RateLimitInfo:
		return rate_limit


	func _to_string() -> String:
		if ok:
			return "CommandResult(%s)" % CommandStatus.keys()[status]
		return "CommandResult(%s)[Reason: %s]" % [CommandStatus.keys()[status], reason]


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


class RateLimitInfo extends RefCounted:
	## True when the command result represents a rate-limited attempt.
	var limited: bool
	## Stable identifier for the policy bucket that limited the command.
	var policy_id: StringName


	func _init(limited_ := false, policy_id_ := &"") -> void:
		limited = limited_
		policy_id = policy_id_


	func to_dict() -> Dictionary:
		return {
			"limited": limited,
			"policy_id": policy_id,
		}


	static func from_dict(serialized: Dictionary) -> RateLimitInfo:
		return RateLimitInfo.new(
			serialized.get("limited", false),
			serialized.get("policy_id", &"")
		)
