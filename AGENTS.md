# devjobs

Standard Flutter scaffold (SDK `^3.12.1`, Material Design). Single entrypoint at `lib/main.dart`. No state management, routing, model layer, or tests yet.

## Commands

| Action | Command |
|--------|---------|
| Run (debug) | `flutter run` |
| Run (release) | `flutter run --release` |
| Analyze | `flutter analyze` |
| Test | `flutter test` |
| Get deps | `flutter pub get` |
| Clean build | `flutter clean` |

## Config

- `analysis_options.yaml` — default `package:flutter_lints/flutter.yaml`, no overrides.
- `opencode.json` — MCP server `dart-mcp-server` enabled (LSP analysis via MCP tools).
- `skills-lock.json` — 22 skills registered (all from `dart-lang/skills`, `flutter/skills`, and autoskills registries). Load with `opencode skill load <name>`.

## Notes

- `.agents/` and `.kiro/` are gitignored (AI tool artifacts).
- No CI, no custom build scripts, no test fixtures.
