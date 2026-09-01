#!/bin/zsh
set -euo pipefail

repository_root=${0:A:h:h}
cd "$repository_root"

python3 -m venv .venv
.venv/bin/python -m pip install --requirement requirements-dev.txt
.venv/bin/prek install \
	--hook-type commit-msg \
	--hook-type pre-push \
	--prepare-hooks

