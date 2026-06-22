# devjobs

Standard Flutter scaffold (SDK `^3.12.1`, Material Design). Single entrypoint at `lib/main.dart`. No routing, or tests yet.

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

## Architecture

- **Data source:** Google Sheets via Apps Script Web App (REST API).
  - `apps_script_code.example.gs` — reference copy of the deployed script.
  - `.env.example` — template; copy to `.env` and set `API_URL`.
- **State management:** `Provider` (`ChangeNotifier`). Single `AppState` in `lib/providers/app_state.dart`.
  - Cache with 3-min TTL — invalidated on refresh or status change.
  - Dashboard stats computed locally from cached list.
  - Dashboard cards: Total postulaciones (no click), Activas (clickable → tab 1), Entrevistas (checkbox-based count), Rechazadas (clickable → tab 3). Clickable cards show `chevron_right` indicator.
  - Tab filters: Activas = estado NOT IN (Enviada, Rechazada, Retirada); Enviadas = estado = Enviada; Rechazadas = Rechazada + Retirada.
  - `diasProceso` computed getter on model: difference in days between fechaPostulacion and fechaSeguimiento (null when no seguimiento).
  - Detail screen shows "Tiempo del proceso" below "F. seguimiento" (only when available).
- **Models:** `lib/models/job_application.dart` — `JobApplication` (15 fields: rowIndex, empresa, vacante, tipoContrato, modalidad, ciudad, salarioOfrecido, estado, link, descripcion, fechaPostulacion, fechaSeguimiento, contacto, comentarios, entrevistaRealizada) + `DashboardStats` (total, activas, entrevistas, rechazadas).
- **Service:** `lib/services/sheets_api_service.dart` — HTTP client using `package:http`.
- **Screens:** `MainScreen` with `BottomNavigationBar` (4 tabs: Inicio/Activas/Enviadas/Rechazadas). Detail via `Navigator.push`.
- **Widgets:** `lib/widgets/status_chip.dart` — colored status badge. `lib/widgets/application_card.dart` — reusable application card.
- **Helpers:** `lib/helpers/date_formatter.dart` — Spanish date formatting via `package:intl`.

## Notes

- `.agents/` and `.kiro/` are gitignored (AI tool artifacts).
- No CI, no custom build scripts, no test fixtures.
