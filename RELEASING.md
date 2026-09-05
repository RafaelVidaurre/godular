# Releasing

This page is for maintainers. Contributors do not release.

Godular follows [Semantic Versioning](https://semver.org). A release is a `v*` tag whose tree matches the reviewed release commit on `main`. The version lives in `addons/godular/plugin.cfg` and `.cz.toml`, and commitizen keeps them in sync.

## Cut a release

1. Make sure `main` is green in CI and your clone is up to date. Create a release branch from `main`.
2. Run `.venv/bin/cz bump --dry-run --check-consistency` to preview the version. Then run `.venv/bin/cz bump --check-consistency`. Commitizen updates the version and changelog, commits, and creates a local annotated tag.
3. Push only the release branch: `git -c push.followTags=false push -u origin HEAD`. Open a release PR. Keep the generated version commit separate from other changes.
4. Wait for the final PR-head checks, then rebase-merge the PR. The repository requires a PR and linear history; direct pushes to `main` are rejected.
5. Fetch and sync `main`. Identify the rebased release commit. Compare its tree with the local tag: `git rev-parse <tag>^{tree} <release-commit>^{tree}` must print the same hash twice. Also run `git diff --exit-code <tag> <release-commit> -- addons` and wait for final-main CI.
6. Push only the verified tag: `git push origin <tag>`. Keep published tags immutable. GitHub's rebase merge changes commit hashes, so the tag retains Commitizen's original commit while the release commit on `main` has the same tree.

Push branches and tags separately. A combined push can publish a tag even when GitHub rejects the branch update.

The `Release` workflow (`.github/workflows/release.yml`) then:

1. Checks that the tag matches the version in `plugin.cfg` and `.cz.toml`.
2. Builds `godular-vX.Y.Z.zip` from the tag with `git archive`. The archive contains only `addons/godular` and `addons/gdb_promise`, as configured in `.gitattributes`. The readme and license travel inside each addon folder, because the Asset Store review asked for nothing at the archive root.
3. Publishes a GitHub release with the changelog section of that version as its notes and the zip as its asset.

The `Docs` workflow deploys the site from `main` on every push, so the reference is current before the tag exists.

## Bump the vendored GdbPromise

Release [gd-better-promises](https://github.com/RafaelVidaurre/gd-better-promises) first. Then edit `gdb_promise_tag` and `gdb_promise_commit` in `tests/dependencies.lock`, run `tools/vendor_gdb_promise.sh`, and commit the result. CI fails when the vendored copy does not match the lock.

## Update the Asset Store

Open the [Godular management dashboard](https://store.godotengine.org/asset/rafael-vidaurre/godular/manage/#settings) while signed in as its publisher.
Use [the summary](metadata/asset-store-summary.txt) for Asset Summary and [the description](metadata/asset-store-description.md) for Detailed Description.
The description field supports Markdown. Check its Preview tab, keep the AI disclosure enabled, and save.

Check the [listing](https://store.godotengine.org/asset/rafael-vidaurre/godular/) after saving.
An asset under review remains pending until moderators publish it.

## Update the legacy Asset Library

Sign in as the owner of the [Godot Asset Library](https://godotengine.org/asset-library/asset/5442) entry.
Open [Edit](https://godotengine.org/asset-library/asset/5442/edit) and paste [the canonical description](docs/asset-library-description.txt) into Description.
Keep its blank lines and plain-text bullets. The listing preserves line breaks but does not render Markdown or HTML.

For a release update, set Download Commit/URL to the full commit hash of the release tag.
Submit the edit and wait for moderation. Check Recent Edits for its status.

## Release baseline

Tag `v0.1.0` identifies commit `11cb63e258e80909b5f8f4baeb2eb18fb1b8a6e1`, the original 0.1.0 download in the legacy Asset Library. Later releases use Commitizen to count changes from that tag.

## Do not

- Do not change version numbers by hand.
- Create new release tags through Commitizen.
- Do not bypass the commit or push hooks.
