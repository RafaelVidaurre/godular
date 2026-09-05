# Releasing

This page is for maintainers. Contributors do not release.

Godular follows [Semantic Versioning](https://semver.org). A release is a `v*` tag on `main`. The version lives in `addons/godular/plugin.cfg` and `.cz.toml`, and commitizen keeps them in sync.

## Cut a release

1. Make sure `main` is green in CI and your clone is up to date.
2. Run `.venv/bin/cz bump --check-consistency`. Commitizen reads the commits since the last tag, picks the next version from their types, updates `addons/godular/plugin.cfg`, creates or updates `CHANGELOG.md`, commits, and tags. Run `cz bump --dry-run` first to preview the version.
3. Run `git push --follow-tags`.

The `Release` workflow (`.github/workflows/release.yml`) then:

1. Checks that the tag matches the version in `plugin.cfg` and `.cz.toml`.
2. Builds `godular-vX.Y.Z.zip` from the tag with `git archive`. The archive contains only `addons/godular` and `addons/gd_promise`, as configured in `.gitattributes`. The readme and license travel inside each addon folder, because the Asset Store review asked for nothing at the archive root.
3. Publishes a GitHub release with the changelog section of that version as its notes and the zip as its asset.

The `Docs` workflow deploys the site from `main` on every push, so the reference is current before the tag exists.

## Bump the vendored GdPromise

Release [gd-better-promises](https://github.com/RafaelVidaurre/gd-better-promises) first. Then edit `gd_promise_tag` and `gd_promise_commit` in `tests/dependencies.lock`, run `tools/vendor_gd_promise.sh`, and commit the result. CI fails when the vendored copy does not match the lock.

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

## First release

No `v*` tag exists yet, although version 0.1.0 is on the Asset Library. Before the first `cz bump`, tag the published commit:

```sh
git tag v0.1.0 <commit>
git push origin v0.1.0
```

The `Release` workflow runs for that tag and publishes the 0.1.0 archive. Later bumps count commits from there.

## Do not

- Do not change version numbers by hand.
- Do not tag by hand except for the first release described above.
- Do not bypass the commit or push hooks.
