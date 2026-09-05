#!/usr/bin/env python3
"""Render Godot doctool XML as reStructuredText with Godot's make_rst.py.

Usage: render_api_reference.py XML_ROOT OUTPUT_DIR

XML_ROOT must contain:
  engine/      the engine class reference (`godot --doctool engine`)
  godular/     `godot --doctool godular --gdscript-docs res://addons/godular`
  gdb_promise/  `godot --doctool gdb_promise --gdscript-docs res://addons/gdb_promise`

The engine classes are parsed so that make_rst.py can resolve links to them.
Only the addon classes are written to OUTPUT_DIR. Sphinx resolves the engine
links through intersphinx.

The script downloads make_rst.py from the Godot tag pinned in .ugrc so that
the renderer always matches the doctool that produced the XML.
"""

import re
import sys
import types
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
ADDON_SECTIONS = ("godular", "gdb_promise")
# addons/gdb_promise is vendored from its own repository. Its doc comments
# are fixed upstream, so only the Godular classes must be complete here.
STRICT_SECTIONS = ("godular",)


def godot_tag() -> str:
    selector = (REPOSITORY_ROOT / ".ugrc").read_text().strip()
    return selector.split("@")[0]


def fetch_make_rst(cache_dir: Path) -> Path:
    tag = godot_tag()
    target = cache_dir / tag / "make_rst.py"
    if target.exists():
        return target
    target.parent.mkdir(parents=True, exist_ok=True)
    url = "https://raw.githubusercontent.com/godotengine/godot/%s/doc/tools/make_rst.py" % tag
    with urllib.request.urlopen(url) as response:
        target.write_bytes(response.read())
    return target


def install_engine_stubs() -> None:
    """make_rst.py imports two helpers from the Godot source tree."""
    version = types.ModuleType("version")
    version.docs = godot_tag().rsplit("-", 1)[0]
    sys.modules["version"] = version

    class Ansi:
        def __getattr__(self, _name: str) -> str:
            return ""

    color = types.ModuleType("misc.utility.color")
    color.Ansi = Ansi()
    color.force_stderr_color = lambda _enabled: None
    color.force_stdout_color = lambda _enabled: None
    sys.modules["misc"] = types.ModuleType("misc")
    sys.modules["misc.utility"] = types.ModuleType("misc.utility")
    sys.modules["misc.utility.color"] = color


def is_private(name: str) -> bool:
    return name.startswith("_")


def has_description(node: ET.Element) -> bool:
    description = node.find("description")
    text = description.text if description is not None else node.text
    if text and text.strip():
        return True
    return node.get("deprecated") is not None or node.get("experimental") is not None


def prune_class(path: Path) -> list[str]:
    """Drop undocumented private members. Return undocumented public members."""
    tree = ET.parse(path)
    root = tree.getroot()
    class_name = root.get("name")
    missing: list[str] = []

    if not (root.findtext("brief_description") or "").strip():
        missing.append(class_name)

    for group in ("methods", "members", "signals", "constants"):
        container = root.find(group)
        if container is None:
            continue
        for node in list(container):
            name = node.get("name")
            documented = has_description(node)
            if is_private(name) and not documented:
                container.remove(node)
            elif not documented:
                missing.append("%s.%s" % (class_name, name))

    tree.write(path, encoding="unicode", xml_declaration=True)
    return missing


def prepare_addon_xml(xml_root: Path) -> None:
    missing: list[str] = []
    for section in ADDON_SECTIONS:
        for path in sorted((xml_root / section).glob("*.xml")):
            if path.name.startswith("addons--"):
                # Scripts without class_name are implementation details.
                path.unlink()
                continue
            undocumented = prune_class(path)
            if section in STRICT_SECTIONS:
                missing += undocumented
    if missing:
        print("Undocumented public API:", file=sys.stderr)
        for entry in missing:
            print("  " + entry, file=sys.stderr)
        sys.exit(1)


def parse_link_target(link_target: str, state, context_name: str) -> list[str]:
    """Split `Class.member` at the last dot so inner classes resolve.

    make_rst.py splits at every dot, which breaks references such as
    [member CapGdlrCommandBus.CommandRoute.target]. The editor help splits
    at the last dot. This override matches the editor.
    """
    if "." not in link_target:
        return [state.current_class, link_target]
    class_name, _, member = link_target.rpartition(".")
    return [class_name, member]


def escape_trailing_underscores(make_method_signature):
    """A parameter name that ends with an underscore reads as a reference
    in reStructuredText. Escape it before the tables are laid out."""

    def wrapped(*args, **kwargs):
        return_type, signature = make_method_signature(*args, **kwargs)
        return return_type, re.sub(r"(\w)_\\:", r"\1\\_\\:", signature)

    return wrapped


def run_make_rst(make_rst: Path, xml_root: Path, output_dir: Path) -> None:
    install_engine_stubs()
    namespace: dict = {"__name__": "make_rst", "__file__": str(make_rst)}
    exec(compile(make_rst.read_text(), str(make_rst), "exec"), namespace)
    namespace["parse_link_target"] = parse_link_target
    namespace["make_method_signature"] = escape_trailing_underscores(namespace["make_method_signature"])

    addon_paths = [str(xml_root / section) for section in ADDON_SECTIONS]
    sys.argv = [
        str(make_rst),
        str(xml_root / "engine" / "doc" / "classes"),
        str(xml_root / "engine" / "modules"),
        *addon_paths,
        "--filter",
        "|".join(re.escape(path) for path in addon_paths),
        "--output",
        str(output_dir),
    ]
    try:
        namespace["main"]()
    except SystemExit as exit_request:
        if exit_request.code:
            sys.exit(exit_request.code)


def clean_output(output_dir: Path) -> None:
    # make_rst.py writes an index grouped by engine base types. The site
    # declares its own index.
    (output_dir / "index.rst").unlink(missing_ok=True)
    for path in output_dir.glob("class_*.rst"):
        text = path.read_text()
        text = re.sub(r"^:github_url: hide\n", "", text)
        text = re.sub(r"^\.\. XML source: .*\n", "", text, flags=re.MULTILINE)
        # make_rst.py marks abstract methods but does not define the badge.
        if "|abstract|" in text and ".. |abstract|" not in text:
            text += "\n.. |abstract| replace:: :abbr:`abstract (This method has no implementation. Override it in a subclass.)`\n"
        path.write_text(text)


def main() -> None:
    xml_root = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)
    for stale in output_dir.glob("*.rst"):
        stale.unlink()

    prepare_addon_xml(xml_root)
    make_rst = fetch_make_rst(REPOSITORY_ROOT / "docs" / "_build" / "make_rst")
    run_make_rst(make_rst, xml_root, output_dir)
    clean_output(output_dir)
    print("Wrote %d class pages to %s" % (len(list(output_dir.glob("class_*.rst"))), output_dir))


if __name__ == "__main__":
    main()
