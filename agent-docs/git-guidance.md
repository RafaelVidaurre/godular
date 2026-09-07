# Git guidance

Follow these rules for all Git operations in this repository.

## Setup

- Run `tools/setup.sh` after you clone the repository.

## Commits

- Use Conventional Commits for all new commits.
- Use `.venv/bin/cz commit` to create commits.
- Do not bypass the commit or push hooks.

## Releases

- Follow [the release guide](../docs/RELEASING.md) when preparing or publishing a release.
- Use `cz bump --check-consistency` to create releases.
- Do not change release versions by hand.
