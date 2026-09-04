# Project guidance

Engineering principles selected for this repository. Agents must follow them.

<!-- managed-by: guidance-composer -->
- Do not preserve backward compatibility.
- Choose the simplest implementation that fully meets the current requirements. Do not add speculative complexity for needs that are not required yet.
- Prefer established, well-maintained libraries over custom implementations.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Prefer CLIs and MCP tools over browser or computer interaction when they can accomplish the task. Use browser or computer interaction when visual or browser verification is the goal, or when no more agent-ergonomic surface is available.
- When a real architectural decision is required, choose a design meant to last. Do not accept a stopgap intended only to work for now and be replaced later.
- Keep components modular and concerns clearly separated.
- Always respond using ASD-STE100 Simplified Technical English. It is a controlled writing standard. Aerospace and defense groups made it. It helps people write clear technical text.
- Use approved words only. The standard gives a word list. Each word has one meaning.
- Use one word for one idea. Do not use two words for the same thing.
- Write short sentences. Use 20 words or less for instructions.
- Use active voice. Write "Turn the switch", not "The switch must be turned".
- Write short paragraphs. Keep one topic in each paragraph.
- The goal is easy reading. Many readers are not native English speakers. Clear text helps them do the work in a safe and correct way.
- Do not add subtitles, helper text, or descriptive copy beneath headings, labels, cards, or settings by default. Prefer one concise, self-explanatory heading or label. Only add supporting copy when the user explicitly asks for it or when it is necessary to prevent misunderstanding or error, and never use it to restate the heading.
- Write every message directed at the user so it stands on its own for a cold reader — someone who has not followed the implementation discussion. Make the subject and claim explicit in the message itself.
<!-- /managed-by: guidance-composer -->

## Godot commands

- Use `ug` for every Godot command.
- Use the version in the repository `.ugrc` file.
- Do not run a Godot executable directly.

## Tests

- Use GUT for GDScript tests.
- Run the complete test suite with `tests/run.sh`.
- Do not create a custom GDScript test runner.

## Dependencies

- Use `GdPromise` from `addons/gd_promise` for promise behavior.
- Do not add a promise implementation inside Godular.
- `addons/gd_promise` is vendored from its own repository. Do not edit it here.
- Send changes to the upstream repository, tag a release, then bump the pin in
  `tests/dependencies.lock` and run `tools/vendor_gd_promise.sh`.
- Do not use Git submodules for add-on dependencies. Asset Store downloads are
  Git archives, and archives do not contain submodule content.

## Public repository

- Keep research and temporary records under `.crew/`.
- Do not commit `.crew/`.
- Exclude development dependencies and tests from published add-on archives.
