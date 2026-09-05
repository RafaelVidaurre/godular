# GdbPromise

Promises for Godot 4, in GDScript. Chain work with `then` and `catch`, or just `await` the result, and stop threading completion callbacks through half your codebase.

GDScript already gives you `await`, which is fine until the thing you are waiting on can fail, or you need to wait on several things at once, or the work is started in one place and awaited in another. `GdbPromise` is a single `RefCounted` script that gives you one object representing a result that has not arrived yet. You can hand it around, await it from several places, combine it with others, and it settles exactly once.

## Getting started

### Install

GdbPromise needs Godot 4.5 or later. The test suite runs against 4.5, 4.6, and 4.7.

1. Download this repository as a zip, or grab a release.
2. Copy `addons/gdb_promise` into your project's `addons` folder.

There is no plugin to enable. `GdbPromise` is a `class_name`, so it is available everywhere as soon as Godot imports the script.

### Your first promise

Create a promise, settle it later, and await it from anywhere:

```gdscript
func load_profile() -> GdbPromise:
	var promise := GdbPromise.new(func(resolve: Callable, reject: Callable) -> void:
		var request := HTTPRequest.new()
		add_child(request)
		request.request_completed.connect(func(_result, code, _headers, body):
			if code == 200:
				resolve.call(body.get_string_from_utf8())
			else:
				reject.call("http %d" % code)
		)
		request.request("https://example.com/profile")
	)
	return promise


func _ready() -> void:
	var profile = await load_profile().await_resolved()
	print(profile)
```

Or chain instead of awaiting:

```gdscript
load_profile() \
	.then(func(body): print("got ", body)) \
	.catch(func(reason): push_error(reason))
```

Combine several, and give the whole thing a deadline:

```gdscript
var all_done := GdbPromise.all([load_profile(), load_settings()])
var result = await GdbPromise.race([all_done, GdbPromise.timeout(5.0)]).await_settled()
```

## What's in the box

- Chaining with `then`, `catch`, and `finally`, each returning a promise so you can keep going.
- Awaiting with `await_resolved`, `await_rejected`, and `await_settled`, so callers pick the style they want.
- Combinators: `all` waits for every promise and preserves result order, `race` takes the first to settle.
- Constructors for the common cases: `new_resolved`, `new_rejected`, `sleep`, `timeout`, and `to_promise` for wrapping a value or callable.
- `from_signals` turns a success signal, and optionally a failure signal, into a promise.
- Inspectable state: `status`, `is_settled`, `is_resolved`, `is_rejected`, and `result`.

## Documentation

The API reference is generated from the doc comments in the source and lives in [docs/reference](https://github.com/RafaelVidaurre/gd-better-promises/blob/main/docs/reference/GdbPromise.md). It is also in Godot's built-in help (F1), since the engine reads the same comments.

## Running the tests

Tests use [GUT](https://github.com/bitwes/Gut):

```sh
tests/run.sh
```

## Contributing

See [CONTRIBUTING.md](https://github.com/RafaelVidaurre/gd-better-promises/blob/main/CONTRIBUTING.md). Commits follow Conventional Commits; the details are in [docs/git-guidance.md](https://github.com/RafaelVidaurre/gd-better-promises/blob/main/docs/git-guidance.md).

## License

[MIT](LICENSE)
