"""Sphinx configuration for the Godular documentation site."""

import re
from pathlib import Path

repository_root = Path(__file__).resolve().parent.parent

project = "Godular"
author = "Godular contributors"
copyright = "Godular contributors"
release = re.search(
    r'^version="([^"]+)"',
    (repository_root / "addons" / "godular" / "plugin.cfg").read_text(),
    re.MULTILINE,
).group(1)
version = release

extensions = [
    "myst_parser",
    "sphinx.ext.intersphinx",
    "sphinx_copybutton",
]

exclude_patterns = ["_build", "agent-guidance.md", "git-guidance.md"]
source_suffix = {".rst": "restructuredtext", ".md": "markdown"}

# Godot's make_rst.py links engine classes as :ref:`Node<class_Node>`.
# Those labels live in the Godot docs inventory.
intersphinx_mapping = {
    "godot": ("https://docs.godotengine.org/en/stable/", None),
}

highlight_language = "gdscript"
pygments_style = "friendly"
pygments_dark_style = "monokai"

myst_enable_extensions = ["colon_fence"]
myst_heading_anchors = 3

html_theme = "furo"
html_title = "Godular %s" % release
html_logo = str(repository_root / "icon.png")
html_favicon = str(repository_root / "icon.png")
html_static_path = ["_static"]
html_css_files = ["classref.css"]
html_theme_options = {
    "source_repository": "https://github.com/RafaelVidaurre/godular/",
    "source_branch": "main",
    "source_directory": "docs/",
}

copybutton_prompt_text = ""


def setup(app):
    """Register a GDScript lexer that knows Godot 4 annotations."""
    from pygments.lexer import inherit
    from pygments.lexers.gdscript import GDScriptLexer
    from pygments.token import Name

    class Godot4Lexer(GDScriptLexer):
        name = "GDScript 4"
        tokens = {
            "root": [
                (r"@[A-Za-z_]\w*", Name.Decorator),
                inherit,
            ],
        }

    app.add_lexer("gdscript", Godot4Lexer)
