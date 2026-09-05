# Contributing

## Report a bug

Open a [GitHub issue](https://github.com/RafaelVidaurre/godular/issues). Include the Godot version, the Godular version from `addons/godular/plugin.cfg`, the steps to reproduce the problem, and the error output. A minimal module setup that shows the problem helps most.

## Propose a change

Open an issue before you start on a feature or a change to the public API. This avoids work on changes that do not fit the project. Bug fixes and documentation fixes do not need an issue first.

## Set up a clone

1. Install [ug](https://github.com/RafaelVidaurre/use-godot). It installs the Godot version pinned in `.ugrc`.
2. Run `tools/setup.sh`. It creates `.venv` with the Python tools and installs the Git hooks.

Open the repository root in Godot to work in the editor. The project already enables the Godular and GUT plugins.

`addons/gdb_promise` is vendored from [gd-better-promises](https://github.com/RafaelVidaurre/gd-better-promises) at the tag pinned in `tests/dependencies.lock`. Do not edit it here. Send changes to that repository.

## Make a change

- Keep the change focused. One pull request solves one problem.
- Write commit messages in the [Conventional Commits](https://www.conventionalcommits.org) format. Use `.venv/bin/cz commit` to write them. The commit hook rejects other formats.
- Keep a linear history. Rebase onto `main` instead of merging it into your branch.
- Add or update tests in `tests/test_godular.gd` for behaviour changes.
- Document every public class and member with a [doc comment](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html). Use Godot BBCode tags such as `[param]`, `[method]`, and `[code]`, not Markdown. The docs build fails when a public member has no description.
- Update the guide in `docs/guide` when you change what users see.
- Do not change the version number. Maintainers release the addon.

## Run the tests

Tests use [GUT](https://github.com/bitwes/Gut).

```sh
tests/run.sh
```

Set `GODOT_SELECTOR` to an installed `ug` selector to test another Godot version:

```sh
GODOT_SELECTOR=4.5.2-stable@standard tests/run.sh
```

CI runs the suite on every supported minor version, checks the commit messages, and builds the documentation site.

## Build the docs

```sh
source .venv/bin/activate
tools/build_docs.sh
```

The script dumps the class reference with the Godot doctool, renders it with Godot's `make_rst.py`, and builds the site with Sphinx into `docs/_build/html`. Warnings fail the build.

## Open a pull request

1. Push your branch and open a pull request against `main`.
2. Explain what the change does and why. Link the issue when there is one.
3. Make sure CI passes.

A maintainer reviews the pull request and merges it.
