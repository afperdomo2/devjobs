# devjobs

Flutter project (SDK `^3.12.1`, Material Design). Currently a scaffold with `lib/main.dart` as the sole entrypoint.

## Commands

| Action | Command |
|--------|---------|
| Run (debug) | `flutter run` |
| Analyze | `flutter analyze` |
| Test | `flutter test` |

No custom build/CI scripts. Tests and CI not yet set up.

## Lint

`analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` (default Flutter ruleset). No overrides.

## Skills

Three skills registered in `skills-lock.json`:
- `dart-best-practices` (kevmoo/dash_skills)
- `flutter-animations` (madteacher/mad-agents-skills)
- `flutter-expert` (jeffallan/claude-skills)

Load via `opencode skill load <name>` if needed.

## Notes

- `.agents/` and `.kiro/` are gitignored (AI tool artifacts).
- No state management, routing, or model layer yet.
