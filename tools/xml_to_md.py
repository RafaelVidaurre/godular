#!/usr/bin/env python3
"""Render Godot doctool XML class files as Markdown.

Usage: xml_to_md.py OUTPUT_DIR SECTION=XML_DIR [SECTION=XML_DIR ...]

Reads the XML files that `godot --doctool <dir> --gdscript-docs <res-path>`
writes. Renders one Markdown page for each named class and a README.md index.
Skips path-named files (scripts without `class_name`) and private members.
"""

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def is_public(name: str) -> bool:
    return name == "_init" or not name.startswith("_")


def parse_sections(args: list[str]) -> dict[str, list[Path]]:
    sections: dict[str, list[Path]] = {}
    for arg in args:
        section, _, xml_dir = arg.partition("=")
        files = [
            path
            for path in sorted(Path(xml_dir).glob("*.xml"))
            if not path.name.startswith("addons--")
        ]
        sections[section] = files
    return sections


def load_class(path: Path) -> ET.Element:
    return ET.parse(path).getroot()


class Renderer:
    def __init__(self, known_classes: set[str]):
        self.known_classes = known_classes

    def link(self, class_name: str) -> str:
        base = class_name.split(".")[0]
        if base in self.known_classes or class_name in self.known_classes:
            target = class_name if class_name in self.known_classes else base
            return "[%s](%s.md)" % (class_name, target)
        return "`%s`" % class_name

    def bbcode_to_md(self, text: str) -> str:
        text = "\n".join(line.strip() for line in text.strip().splitlines())
        text = re.sub(r"\[codeblock(?:s)?(?: lang=\w+)?\]\n?", "\n```gdscript\n", text)
        text = re.sub(r"\n?\[/codeblock(?:s)?\]", "\n```\n", text)
        text = re.sub(r"\[(?:gdscript|csharp)\]\n?|\n?\[/(?:gdscript|csharp)\]", "", text)
        text = text.replace("[b]", "**").replace("[/b]", "**")
        text = text.replace("[i]", "*").replace("[/i]", "*")
        text = text.replace("[code]", "`").replace("[/code]", "`")
        text = text.replace("[br]", "\n")
        text = re.sub(r"\[(?:param|method|member|signal|constant|enum) ([^\]]+)\]", r"`\1`", text)
        text = re.sub(
            r"\[([A-Z][A-Za-z0-9_.]*)\]",
            lambda match: self.link(match.group(1)),
            text,
        )
        return text.strip()

    def type_ref(self, type_name: str) -> str:
        return self.link(type_name)

    def method_signature(self, method: ET.Element) -> str:
        params = []
        for param in method.findall("param"):
            piece = "%s: %s" % (param.get("name"), param.get("type"))
            default = param.get("default")
            if default is not None:
                piece += " = %s" % default
            params.append(piece)
        return_type = method.find("return").get("type")
        qualifiers = method.get("qualifiers", "")
        prefix = "static func" if "static" in qualifiers else "func"
        return "%s %s(%s) -> %s" % (prefix, method.get("name"), ", ".join(params), return_type)

    def description_of(self, node: ET.Element) -> str:
        description = node.find("description")
        text = description.text if description is not None and description.text else ""
        return self.bbcode_to_md(text)

    def render_class(self, root: ET.Element) -> str:
        name = root.get("name")
        lines = ["# %s" % name, ""]
        lines += ["Inherits: %s" % self.type_ref(root.get("inherits", "")), ""]

        brief = self.bbcode_to_md(root.findtext("brief_description") or "")
        if brief:
            lines += [brief, ""]
        description = self.bbcode_to_md(root.findtext("description") or "")
        if description:
            lines += [description, ""]

        signals = [
            signal
            for signal in root.findall("./signals/signal")
            if is_public(signal.get("name"))
        ]
        if signals:
            lines += ["## Signals", ""]
            for signal in signals:
                params = ", ".join(
                    "%s: %s" % (param.get("name"), param.get("type"))
                    for param in signal.findall("param")
                )
                lines += ["### `%s(%s)`" % (signal.get("name"), params), ""]
                text = self.description_of(signal)
                if text:
                    lines += [text, ""]

        constants = root.findall("./constants/constant")
        enums: dict[str, list[ET.Element]] = {}
        plain_constants = []
        for constant in constants:
            if not is_public(constant.get("name")):
                continue
            if "<Object>" in (constant.get("value") or ""):
                continue
            enum_name = constant.get("enum")
            if enum_name:
                enums.setdefault(enum_name, []).append(constant)
            else:
                plain_constants.append(constant)

        if enums:
            lines += ["## Enumerations", ""]
            for enum_name, values in enums.items():
                lines += ["### `%s`" % enum_name, ""]
                for value in values:
                    entry = "- `%s` = `%s`" % (value.get("name"), value.get("value"))
                    text = self.bbcode_to_md(value.text or "")
                    if text:
                        entry += " — %s" % text
                    lines.append(entry)
                lines.append("")

        if plain_constants:
            lines += ["## Constants", ""]
            for constant in plain_constants:
                entry = "- `%s` = `%s`" % (constant.get("name"), constant.get("value"))
                text = self.bbcode_to_md(constant.text or "")
                if text:
                    entry += " — %s" % text
                lines.append(entry)
            lines.append("")

        members = [
            member
            for member in root.findall("./members/member")
            if is_public(member.get("name"))
        ]
        if members:
            lines += ["## Properties", ""]
            for member in members:
                lines += ["### `%s: %s`" % (member.get("name"), member.get("type")), ""]
                text = self.bbcode_to_md(member.text or "")
                if text:
                    lines += [text, ""]

        methods = [
            method
            for method in root.findall("./methods/method")
            if is_public(method.get("name"))
        ]
        if methods:
            lines += ["## Methods", ""]
            for method in methods:
                lines += ["### `%s`" % self.method_signature(method), ""]
                text = self.description_of(method)
                if text:
                    lines += [text, ""]

        return "\n".join(lines).rstrip() + "\n"


def render_index(sections: dict[str, list[ET.Element]], renderer: Renderer) -> str:
    lines = [
        "# API reference",
        "",
        "Generated from GDScript doc comments with `tools/generate_docs.sh`.",
        "Do not edit these files by hand.",
        "",
    ]
    for section, roots in sections.items():
        lines += ["## %s" % section, ""]
        top_level = [root for root in roots if "." not in root.get("name")]
        children: dict[str, list[ET.Element]] = {}
        for root in roots:
            name = root.get("name")
            if "." in name:
                children.setdefault(name.split(".")[0], []).append(root)
        for root in top_level:
            name = root.get("name")
            brief = renderer.bbcode_to_md(root.findtext("brief_description") or "")
            entry = "- [%s](%s.md)" % (name, name)
            if brief:
                entry += " — %s" % brief.splitlines()[0]
            lines.append(entry)
            for child in children.get(name, []):
                child_name = child.get("name")
                child_brief = renderer.bbcode_to_md(child.findtext("brief_description") or "")
                child_entry = "  - [%s](%s.md)" % (child_name, child_name)
                if child_brief:
                    child_entry += " — %s" % child_brief.splitlines()[0]
                lines.append(child_entry)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    output_dir = Path(sys.argv[1])
    output_dir.mkdir(parents=True, exist_ok=True)

    section_files = parse_sections(sys.argv[2:])
    section_roots = {
        section: [load_class(path) for path in files]
        for section, files in section_files.items()
    }
    known_classes = {
        root.get("name")
        for roots in section_roots.values()
        for root in roots
    }
    renderer = Renderer(known_classes)

    for roots in section_roots.values():
        for root in roots:
            page = output_dir / ("%s.md" % root.get("name"))
            page.write_text(renderer.render_class(root))

    (output_dir / "README.md").write_text(render_index(section_roots, renderer))


if __name__ == "__main__":
    main()
