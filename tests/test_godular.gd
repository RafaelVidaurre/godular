extends GutTest

const ModuleA = preload("res://tests/fixtures/module_a.gd")
const AsyncRoot = preload("res://tests/fixtures/async_root.gd")
const ProviderModule = preload("res://tests/fixtures/provider_module.gd")
const ConsumerModule = preload("res://tests/fixtures/consumer_module.gd")
const DynamicModule = preload("res://tests/fixtures/dynamic_module.gd")
const ModuleManager = preload("res://addons/godular/singletons/module_manager/module_manager.gd")
const SvcCommandHandlers = preload("res://addons/godular/built_ins/services/command_handlers.svc.gd")
const SvcCommandBus = preload("res://addons/godular/built_ins/services/command_bus.svc.gd")
const RegJobs = preload("res://addons/godular/built_ins/modules/jobs/registries/reg_jobs.gd")
const SvcJobs = preload("res://addons/godular/built_ins/modules/jobs/services/svc_jobs.gd")
const JobsModule = preload("res://addons/godular/built_ins/modules/jobs/md_jobs.gd")


class FakeTransport extends CapGdlrCommandTransport:
	var calls := 0
	var adapters: Dictionary[StringName, GdlrCommandTransportAdapter] = {}

	func send(_envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult:
		calls += 1
		return CapGdlrCommandBus.CommandResult.new(true, CapGdlrCommandBus.CommandStatus.ACK, "", {"remote": true})

	func register_adapter(target: StringName, adapter: GdlrCommandTransportAdapter) -> void:
		adapters[target] = adapter

	func get_adapter(target: StringName) -> GdlrCommandTransportAdapter:
		return adapters.get(target)


class FakeRouter extends CapGdlrCommandRouter:
	func plan(_envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandRoute:
		return CapGdlrCommandBus.CommandRoute.new(CapGdlrCommandBus.ExecKind.LOCAL)


class FakeAdapter extends GdlrCommandTransportAdapter:
	var enable_calls := 0
	var send_calls := 0

	func _enable() -> void:
		enable_calls += 1

	func _send(_envelope: CapGdlrCommandBus.CommandEnvelope) -> CapGdlrCommandBus.CommandResult:
		send_calls += 1
		return CapGdlrCommandBus.CommandResult.new(false, CapGdlrCommandBus.CommandStatus.NACK, "retry", {"wait": 3.0})


class CommandHandlerFake extends GdlrCommandHandler:
	func run(_envelope: CapGdlrCommandBus.CommandEnvelope, _ctx: CapGdlrCommandHandlers.Context) -> Variant:
		return CapGdlrCommandHandlers.LocalOutput.new([{"type": "done"}], [])


class CommandMiddlewareFake extends GdlrCommandMiddleware:
	var before_calls := 0

	func _before(_envelope: CapGdlrCommandBus.CommandEnvelope, _ctx: CapGdlrCommandHandlers.Context) -> void:
		before_calls += 1


class DebugPluginFake extends GdlrModuleGraph.DebugPlugin:
	pass


class DependencyJob extends CapGdlrJobs.JobSpec:
	const KEY := &"jobs/test/dependency"

	func _run(_args := {}) -> GdPromise:
		return GdPromise.new_resolved("dependency-output")


class ManualJob extends CapGdlrJobs.JobSpec:
	const KEY := &"jobs/test/manual"

	func _ensure_requirements() -> GdPromise:
		return ensure_job(DependencyJob.KEY)

	func _run(_args := {}) -> GdPromise:
		return GdPromise.new_resolved("manual-output")

	func _get_run_policy() -> CapGdlrJobs.JobRunPolicy:
		return CapGdlrJobs.JobRunPolicy.MANUAL


class PendingRunJob extends CapGdlrJobs.JobSpec:
	const KEY := &"jobs/test/pending"
	var run_count := 0

	func _run(_args := {}) -> GdPromise:
		run_count += 1
		return GdPromise.new(func(_resolve: Callable, _reject: Callable) -> void: pass)


class PendingRequirementsJob extends CapGdlrJobs.JobSpec:
	const KEY := &"jobs/test/pending-requirements"
	var resolve_requirements := Callable()
	var run_count := 0

	func _ensure_requirements() -> GdPromise:
		return GdPromise.new(func(resolve: Callable, _reject: Callable) -> void:
			resolve_requirements = resolve
		)

	func _run(_args := {}) -> GdPromise:
		run_count += 1
		return GdPromise.new_resolved()


func test_module_graph_registers_and_enables_dependencies_in_order() -> void:
	GdlrTestEvents.reset()
	var graph := GdlrModuleGraph.new(ModuleA)
	var compile_promise := graph.compile()
	await compile_promise.await_settled()
	assert_true(compile_promise.is_resolved, "The module graph compiles.")
	var start_promise := graph.start()
	await start_promise.await_settled()
	assert_true(start_promise.is_resolved, "The module graph starts.")
	assert_eq(GdlrTestEvents.register_order, ["D", "B", "C", "A"], "Dependencies register before dependants.")
	assert_eq(GdlrTestEvents.enable_order, ["D", "B", "C", "A"], "Dependencies enable before dependants.")


func test_module_graph_waits_for_async_dependency_enable() -> void:
	GdlrTestEvents.reset()
	var graph := GdlrModuleGraph.new(AsyncRoot)
	await graph.compile().await_settled()
	await graph.start().await_settled()
	assert_eq(GdlrTestEvents.enable_order, ["AsyncDependency", "AsyncRoot"], "The dependant waits for asynchronous enable.")


func test_module_graph_injects_and_exports_providers() -> void:
	GdlrTestEvents.reset()
	var graph := GdlrModuleGraph.new(ConsumerModule)
	await graph.compile().await_settled()
	await graph.start().await_settled()
	var service: Variant = graph.request(GdlrTestCapability)
	assert_true(service is GdlrTestService, "The tree export resolves the provider service.")
	assert_same(service, GdlrTestEvents.injected_service, "The module receives its typed dependency.")
	assert_same(service, GdlrTestEvents.injected_consumer_service, "Object injection uses the module dependency.")
	assert_eq(graph.request(&"summary"), "service", "A dependant can resolve an imported export.")
	var debug_plugin := DebugPluginFake.new("Test")
	graph.register_debug_plugin("Test", debug_plugin)
	assert_same(graph.get_debug_plugins().get("Test"), debug_plugin, "The graph registers its debug extension.")
	graph.get_debug_plugins().erase("Test")
	debug_plugin.free()


func test_dynamic_module_providers_override_static_providers() -> void:
	var graph := GdlrModuleGraph.new(DynamicModule.for_root("dynamic"))
	await graph.compile().await_settled()
	await graph.start().await_settled()
	assert_eq(graph.request(&"setting"), "dynamic", "The dynamic provider overrides the static provider.")


func test_module_manager_mounts_starts_and_requests_exports() -> void:
	var manager := ModuleManager.new()
	get_tree().root.add_child(manager)
	var state := {"mounted": 0, "started": 0}
	manager.graph_mounted.connect(func(_graph: GdlrModuleGraph): state.mounted += 1)
	manager.graph_started.connect(func(_graph: GdlrModuleGraph): state.started += 1)
	await manager.mount(ProviderModule)
	await manager.start()
	assert_eq(state, {"mounted": 1, "started": 1}, "Each lifecycle signal fires once.")
	assert_true(manager.request(GdlrTestCapability) is GdlrTestService, "The manager returns a tree export.")
	manager.queue_free()
	await get_tree().process_frame


func test_gd_promise_dependency_resolves_rejects_combines_and_converts() -> void:
	var pending := GdPromise.new(func(_resolve: Callable, _reject: Callable): pass)
	pending.resolve("done")
	assert_eq(await pending.await_resolved(), "done", "A pending promise resolves.")
	var rejected := GdPromise.new(func(_resolve: Callable, _reject: Callable): pass)
	rejected.reject("failed")
	assert_eq(await rejected.await_rejected(), "failed", "A pending promise rejects.")
	var all_result: Array = await GdPromise.all([
		GdPromise.new_resolved(1),
		GdPromise.new_resolved(2),
	]).await_resolved()
	assert_eq(all_result, [1, 2], "Promise.all preserves result order.")
	var race_result: Variant = await GdPromise.race([
		GdPromise.new_resolved("first"),
		GdPromise.new_resolved("second"),
	]).await_resolved()
	assert_eq(race_result, "first", "Promise.race uses the first settled promise.")
	assert_eq(await GdPromise.to_promise(func(): return 3).await_resolved(), 3, "to_promise awaits a callable.")


func test_di_container_resolves_dependencies_and_caches_singletons() -> void:
	var state := {"calls": 0}
	var first_provider := GdlrModuleProvider.new(&"first", [], func():
		state.calls += 1
		return {"value": "first"}
	)
	var second_provider := GdlrModuleProvider.new(&"second", [&"first"], func(first):
		return GdPromise.new_resolved({"first": first})
	)
	var alias_provider := GdlrModuleProvider.new(&"alias", [&"second"], null, &"second")
	var container := GdlrDiContainer.new()
	var first_factory := GdlrDiContainer.ProviderFactory.new(first_provider, {}, container)
	var second_factory := GdlrDiContainer.ProviderFactory.new(second_provider, {&"first": first_factory}, container)
	var alias_factory := GdlrDiContainer.ProviderFactory.new(alias_provider, {&"second": second_factory}, container)
	container.add_provider_factory(&"first", first_factory)
	container.add_provider_factory(&"second", second_factory)
	container.add_provider_factory(&"alias", alias_factory)
	var first_result = await container.resolve(&"alias").await_resolved()
	var second_result = await container.resolve(&"alias").await_resolved()
	assert_eq(first_result, {"first": {"value": "first"}}, "The container resolves ordered dependencies.")
	assert_true(first_result == second_result and state.calls == 1, "The container caches singleton providers.")
	assert_eq(container.resolve_sync(&"alias"), first_result, "Synchronous resolve returns the asynchronous cache.")


func test_middleware_orders_callbacks_and_transforms_results() -> void:
	var events: Array[String] = []
	var pipeline := GdlrMiddlewarePipeline.new(func(value: int):
		events.append("core")
		return value + 1
	)
	pipeline.use_before(func(_value: int): events.append("before-high"), 10)
	pipeline.use_before(func(_value: int): events.append("before-low"), -10)
	pipeline.use_around(func(next: Callable, value: int):
		events.append("around-enter")
		var result = await next.call(value * 2)
		events.append("around-exit")
		return result
	)
	pipeline.use_after(func(result: int, _value: int):
		events.append("after")
		return result * 3
	)
	var result = await pipeline.run(2)
	assert_eq(result, 15, "Middleware transforms arguments and results in order.")
	assert_eq(events, ["before-low", "before-high", "around-enter", "core", "around-exit", "after"], "Middleware follows priority and insertion order.")
	pipeline.set_core_override(func(_value: int): return 9, 5, func(value: int): return value == 4)
	assert_eq(await pipeline.run(4), 27, "A matching override replaces the core.")
	var removable := func(_value: int): events.append("removed")
	pipeline.use_before(removable)
	pipeline.remove_by_callback(removable)
	events.clear()
	await pipeline.run(1)
	assert_false(events.has("removed"), "remove_by_callback removes middleware.")


func test_command_contracts_and_dispatch() -> void:
	var envelope := _make_envelope()
	var decoded := CapGdlrCommandBus.CommandEnvelope.from_dict(envelope.to_dict())
	assert_true(decoded.command is GdlrTestCommand and decoded.command.message == "hello", "Serialization restores the command.")
	assert_eq(decoded.meta.route.exec_kind, CapGdlrCommandBus.ExecKind.LOCAL, "Serialization restores route metadata.")
	var limited := CapGdlrCommandBus.CommandResult.rate_limited(2.0, &"test-policy")
	var limited_copy := CapGdlrCommandBus.CommandResult.from_dict(limited.to_dict())
	assert_true(limited_copy.is_rate_limited() and limited_copy.get_rate_limit_info().policy_id == &"test-policy", "Serialization preserves rate-limit metadata.")
	assert_eq(limited_copy.get_retry_after_s(), 2.0, "Serialization preserves retry timing.")

	var handlers := SvcCommandHandlers.new()
	var state := {"around_calls": 0}
	var handler := CommandHandlerFake.new()
	var middleware := CommandMiddlewareFake.new()
	handlers.set_core(GdlrTestCommand, handler.run)
	handlers.use(GdlrTestCommand, middleware)
	handlers.use_global_around(func(next: Callable, current_envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context):
		state.around_calls += 1
		return await next.call(current_envelope, ctx)
	)
	var future_handlers := SvcCommandHandlers.new()
	future_handlers.use_global_around(func(next: Callable, current_envelope: CapGdlrCommandBus.CommandEnvelope, ctx: CapGdlrCommandHandlers.Context):
		state.around_calls += 1
		return await next.call(current_envelope, ctx)
	)
	future_handlers.set_core(GdlrTestCommand, func(_envelope: CapGdlrCommandBus.CommandEnvelope, _ctx: CapGdlrCommandHandlers.Context):
		return CapGdlrCommandHandlers.LocalOutput.new()
	)
	await handlers.run(envelope, CapGdlrCommandHandlers.Context.new())
	await future_handlers.run(envelope, CapGdlrCommandHandlers.Context.new())
	assert_eq(state.around_calls, 2, "Global middleware covers existing and future pipelines.")
	assert_eq(middleware.before_calls, 1, "Command middleware runs before its handler.")
	assert_eq(FakeRouter.new().plan(envelope).exec_kind, CapGdlrCommandBus.ExecKind.LOCAL, "The router contract returns a route.")

	var transport := FakeTransport.new()
	var bus := SvcCommandBus.new(handlers, transport)
	var local_result: CapGdlrCommandBus.CommandResult = await bus.dispatch(envelope)
	assert_true(local_result.ok and local_result.payload.state_dispatches.size() == 1, "Local dispatch returns handler output.")
	var remote_result: CapGdlrCommandBus.CommandResult = await bus.dispatch(_make_envelope(CapGdlrCommandBus.ExecKind.REMOTE))
	assert_true(remote_result.ok and transport.calls == 1, "Remote dispatch uses the transport.")


func test_transport_adapter_enables_sends_and_applies_retry_metadata() -> void:
	var adapter := FakeAdapter.new()
	await adapter.enable()
	var envelope := _make_envelope(CapGdlrCommandBus.ExecKind.REMOTE)
	envelope.meta.route.route_config = {
		"retry_after_extractor": func(payload: Dictionary): return payload.get("wait", -1.0),
	}
	var result := await adapter.send(envelope)
	assert_true(adapter.enabled and adapter.enable_calls == 1 and adapter.send_calls == 1, "The adapter enables and sends once.")
	assert_true(result.get_retry_after_s() == 3.0 and result.retry_after_source == &"payload", "The adapter applies retry metadata.")
	adapter.free()


func test_jobs_run_requirements_and_reset_aborted_work() -> void:
	var registry := RegJobs.new()
	registry.register_job(DependencyJob.new())
	registry.register_job(ManualJob.new())
	var jobs := SvcJobs.new(registry)
	var ensured := jobs.ensure_job(ManualJob.KEY)
	await get_tree().process_frame
	assert_true(not ensured.is_settled and jobs.get_job_status(ManualJob.KEY) == CapGdlrJobs.JobStatus.WAITING_FOR_START, "A manual job waits for run_job.")
	jobs.run_job(ManualJob.KEY)
	assert_eq(await ensured.await_resolved(), "manual-output", "A manual job resolves after run_job.")
	assert_eq(jobs.get_job_output(DependencyJob.KEY), "dependency-output", "A job requirement runs first.")

	var pending_registry := RegJobs.new()
	var pending_spec := PendingRunJob.new()
	pending_registry.register_job(pending_spec)
	var pending_jobs := SvcJobs.new(pending_registry)
	var first_run := pending_jobs.ensure_job(PendingRunJob.KEY)
	await get_tree().process_frame
	var reset := pending_jobs.reset_job(PendingRunJob.KEY, true)
	await reset.await_settled()
	assert_true(reset.is_resolved and first_run.is_rejected and not pending_jobs.has_job(PendingRunJob.KEY), "Abort reset clears a running job.")
	pending_jobs.ensure_job(PendingRunJob.KEY)
	await get_tree().process_frame
	assert_eq(pending_spec.run_count, 2, "A reset job starts a new run.")

	var requirements_registry := RegJobs.new()
	var requirements_spec := PendingRequirementsJob.new()
	requirements_registry.register_job(requirements_spec)
	var requirements_jobs := SvcJobs.new(requirements_registry)
	var waiting_run := requirements_jobs.ensure_job(PendingRequirementsJob.KEY)
	await get_tree().process_frame
	var requirements_reset := requirements_jobs.reset_job(PendingRequirementsJob.KEY, true)
	await requirements_reset.await_settled()
	assert_true(requirements_reset.is_resolved and waiting_run.is_rejected, "Abort reset rejects a job that waits for requirements.")
	requirements_spec.resolve_requirements.call()
	await get_tree().process_frame
	assert_true(requirements_spec.run_count == 0 and not requirements_jobs.has_job(PendingRequirementsJob.KEY), "An aborted job does not resume after reset.")


func test_jobs_module_exports_jobs_service() -> void:
	var graph := GdlrModuleGraph.new(JobsModule)
	await graph.compile().await_settled()
	await graph.start().await_settled()
	assert_true(graph.request(CapGdlrJobs) is CapGdlrJobs, "The jobs module exposes the jobs service.")


func _make_envelope(exec_kind: CapGdlrCommandBus.ExecKind = CapGdlrCommandBus.ExecKind.LOCAL) -> CapGdlrCommandBus.CommandEnvelope:
	var command := GdlrTestCommand.new()
	command.message = "hello"
	var meta := CapGdlrCommandBus.CommandMeta.new()
	meta.id = &"command-1"
	meta.route = CapGdlrCommandBus.CommandRoute.new(exec_kind, &"server")
	return CapGdlrCommandBus.CommandEnvelope.new(command, meta)
