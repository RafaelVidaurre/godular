#!/usr/bin/env bash
# Prepares a clone for development: Python tools, Git hooks, and the
# documentation toolchain.
set -euo pipefail

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repository_root"

python3 -m venv .venv
.venv/bin/python -m pip install --requirement requirements-dev.txt --requirement docs/requirements.txt
.venv/bin/prek install \
	--hook-type commit-msg \
	--hook-type pre-push \
	--prepare-hooks
