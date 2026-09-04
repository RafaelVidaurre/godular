#!/bin/zsh
set -euo pipefail

repo_root=${0:A:h:h}
cd "$repo_root"

# Keep Godot's state inside the repository so a test run never touches the
# editor configuration of the person running it.
export XDG_DATA_HOME="$repo_root/.godot/xdg/data"
export XDG_CONFIG_HOME="$repo_root/.godot/xdg/config"
export XDG_CACHE_HOME="$repo_root/.godot/xdg/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

# Defaults to the version in .ugrc. Set GODOT_SELECTOR to test another one.
selector=("${(@s: :)GODOT_SELECTOR:-}")
selector=("${(@)selector:#}")

shasum -a 256 -c tests/dependencies.sha256
ug exec "${selector[@]}" -- --headless --editor --path . --log-file .godot/editor.log --quit
ug exec "${selector[@]}" -- --headless --path . --log-file .godot/tests.log --script res://addons/gut/gut_cmdln.gd -gexit
zsh tests/verify_plugin.sh
