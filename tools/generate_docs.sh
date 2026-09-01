#!/usr/bin/env bash
# Regenerates docs/reference from GDScript doc comments.
# Uses the official Godot doctool, then renders the XML as Markdown.
set -euo pipefail

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repository_root"

xml_root=$(mktemp -d)
trap 'rm -rf "$xml_root"' EXIT
mkdir -p "$xml_root/godular" "$xml_root/gd_promise"

# Import the project once so script classes resolve.
ug exec -- --headless --editor --path . --quit

ug exec -- --headless --path . --doctool "$xml_root/godular" --gdscript-docs res://addons/godular --quit
ug exec -- --headless --path . --doctool "$xml_root/gd_promise" --gdscript-docs res://addons/gd_promise --quit

rm -rf docs/reference
python3 tools/xml_to_md.py docs/reference \
	"Godular=$xml_root/godular" \
	"GdPromise=$xml_root/gd_promise"

echo "Wrote docs/reference"
