#!/usr/bin/env bash
# Builds the documentation site into docs/_build/html.
#
# 1. Dumps the class reference from the GDScript doc comments with the
#    official Godot doctool.
# 2. Renders it as reStructuredText with Godot's make_rst.py.
# 3. Builds the site with Sphinx. Warnings fail the build.
#
# Requires `ug` and the Python packages in docs/requirements.txt.
set -euo pipefail

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repository_root"

xml_root=$(mktemp -d)
trap 'rm -rf "$xml_root"' EXIT
mkdir -p "$xml_root/engine" "$xml_root/godular" "$xml_root/gd_promise"

# Import the project once so script classes resolve.
ug exec -- --headless --editor --path . --quit

# The engine reference lets make_rst.py resolve links to engine classes.
ug exec -- --headless --doctool "$xml_root/engine" --quit
ug exec -- --headless --path . --doctool "$xml_root/godular" --gdscript-docs res://addons/godular --quit
ug exec -- --headless --path . --doctool "$xml_root/gd_promise" --gdscript-docs res://addons/gd_promise --quit

python3 tools/render_api_reference.py "$xml_root" docs/api/classes

sphinx-build --fail-on-warning --keep-going --builder html docs docs/_build/html

echo "Built docs/_build/html"
