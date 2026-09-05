# Godular

Godular helps you organize a Godot game into modules and connect their services.
Each module declares its dependencies and shared services.
Godular supplies those dependencies and starts modules in dependency order, waiting for asynchronous work.

- Documentation: <https://rafaelvidaurre.github.io/godular/>
- Source and issues: <https://github.com/RafaelVidaurre/godular>

## Install

Godular needs Godot 4.5 or later.

1. Keep both `addons/godular` and the bundled `addons/gd_promise` folder in your project.
2. Enable "Godular" under Project Settings, then Plugins.
3. Follow the [getting started guide](https://rafaelvidaurre.github.io/godular/guide/getting-started.html) to create and start your first module.

The plugin adds the `GdlrModuleManager` autoload. Class documentation is also available in the editor help (F1).

## AI disclosure

Code, documentation, and the project icon were produced with AI assistance under human review.

## License

[MIT](LICENSE)
