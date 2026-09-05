Godular helps you organize a Godot game into modules and connect their services.

Each module declares what it needs, what it provides, and what it shares. Godular supplies those dependencies and starts modules in dependency order, waiting for asynchronous work.

## Features

- Dependency injection for services and factories.
- Middleware that runs before, after, or around a callable.
- A command bus for local handlers and transports you provide.
- Jobs with dependencies, manual start options, and resets.

## Install

Godular needs Godot 4.5 or later.

1. Install the complete `addons` folder from your download. Keep both bundled add-on folders.
2. Enable **Godular** under **Project Settings**, then **Plugins**.
3. Follow the [getting started guide](https://rafaelvidaurre.github.io/godular/guide/getting-started.html) to create your first module.

## AI disclosure

Code, documentation, and the project icon were produced with AI assistance under human review.
