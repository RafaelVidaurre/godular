extends CapGdlrCommandBus

var _middleware: Array[Callable] = []
var _svc_command_handlers: CapGdlrCommandHandlers
var _svc_command_transport: CapGdlrCommandTransport


func _init(svc_command_handlers: CapGdlrCommandHandlers, svc_command_transport: CapGdlrCommandTransport) -> void:
	_svc_command_handlers = svc_command_handlers
	_svc_command_transport = svc_command_transport


func use(middleware: Callable) -> void:
	_middleware.append(middleware)


func clear_middleware() -> void:
	_middleware.clear()


func dispatch(command_or_envelope: Variant, meta_params := {}) -> CommandResult:
	var envelope := _to_envelope(command_or_envelope, meta_params)
	var terminal := func(e: CommandEnvelope):
		return await _run_terminal(e)

	var chain := terminal

	for i in range(_middleware.size() - 1, -1, -1):
		chain = _middleware[i].call(chain)

	var result: CommandResult = await chain.call(envelope)

	return result


func _run_terminal(envelope: CommandEnvelope) -> CommandResult:
	if not _svc_command_handlers:
		return CommandResult.new(false, CommandStatus.NACK, "CommandBus is not configured", null)

	var exec_kind := envelope.meta.route.exec_kind

	match exec_kind:
		ExecKind.LOCAL:
			var local_output := await _run_local_handler(envelope)
			return CommandResult.new(true, CommandStatus.ACK, "", local_output.to_dict())

		ExecKind.DUAL_LOCAL_FIRST:
			await _run_local_handler(envelope)
			var remote_result: CommandResult = await _svc_command_transport.send(envelope)
			return remote_result

		ExecKind.DUAL_REMOTE_FIRST:
			var remote_result: CommandResult = await _svc_command_transport.send(envelope)
			await _run_local_handler(envelope)
			return remote_result

		ExecKind.REMOTE:
			var remote_result: CommandResult = await _svc_command_transport.send(envelope)
			return remote_result

		_:
			return CommandResult.new(false, CommandStatus.NACK, "Invalid execution kind", null)


func _run_local_handler(envelope: CommandEnvelope) -> CapGdlrCommandHandlers.LocalOutput:
	var ctx := CapGdlrCommandHandlers.Context.new()
	ctx.get_state = func(): return null
	ctx.dispatch = func(next_envelope: CommandEnvelope): return await dispatch(next_envelope)

	var output := await _svc_command_handlers.run(envelope, ctx)
	return output


func _to_envelope(command_or_envelope: Variant, meta_params := {}) -> CommandEnvelope:
	if command_or_envelope is CommandEnvelope:
		return command_or_envelope

	if command_or_envelope is Command:
		var meta := CommandMeta.new()
		for key in meta_params:
			meta.set(key, meta_params[key])
		return CommandEnvelope.new(command_or_envelope, meta)

	assert(false, "Invalid command or envelope: %s" % command_or_envelope)
	return null
