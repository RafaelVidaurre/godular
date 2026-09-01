#!/bin/zsh
set -euo pipefail

shasum -a 256 -c tests/dependencies.sha256
ug exec -- --headless --editor --path . --quit
ug exec -- --headless --path . --script res://addons/gut/gut_cmdln.gd -gexit
zsh tests/verify_plugin.sh
