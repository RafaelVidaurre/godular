#!/bin/zsh
set -euo pipefail

test_dir="$(mktemp -d /tmp/godular-plugin-test.XXXXXX)"
cleanup() {
	case "$test_dir" in
		/tmp/godular-plugin-test.*) trash "$test_dir" ;;
		*) print -u2 "Refusing to remove unexpected test path: $test_dir" ;;
	esac
}
trap cleanup EXIT

mkdir -p "$test_dir/addons"
cp -R addons/godular "$test_dir/addons/godular"
cp -R addons/gd_promise "$test_dir/addons/gd_promise"
cp -R tests/plugin_enabler "$test_dir/addons/plugin_enabler"
cp tests/plugin_project.godot "$test_dir/project.godot"

ug exec -- --headless --editor --path "$test_dir"

rg -q '^GdlrModuleManager="\*(res://addons/godular/singletons/module_manager/module_manager.gd|uid://)' "$test_dir/project.godot"
rg -q 'res://addons/godular/plugin.cfg' "$test_dir/project.godot"
test -f "$test_dir/addons/gd_promise/gd_promise.gd"
